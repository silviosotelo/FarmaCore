<?php
/**
 * Funciones para sincronización garantizada de pedidos WooCommerce con API externa
 * 
 * Este código implementa múltiples hooks para asegurar que los pedidos se envíen correctamente
 * a la API y un sistema de reintento para pedidos fallidos.
 */

// 1. Hook principal cuando el pedido cambia a procesando (momento ideal)
add_action('woocommerce_order_status_processing', 'ft_enviar_pedido_a_api', 10, 1);

// 2. Hook de respaldo cuando el pedido cambia a completado
add_action('woocommerce_order_status_completed', 'ft_enviar_pedido_a_api', 10, 1);

// 3. Hook adicional para el pago recibido (muy importante)
add_action('woocommerce_payment_complete', 'ft_enviar_pedido_a_api', 10, 1);

// 4. Mantén el hook actual como respaldo final
add_action('woocommerce_thankyou', 'ft_enviar_pedido_a_api', 10, 1);

/**
 * Función principal para enviar el pedido a la API externa
 * 
 * @param int $order_id ID del pedido en WooCommerce
 * @return bool True si se procesó correctamente, False si no
 */
function ft_enviar_pedido_a_api($order_id)
{
    // Verificar que el order_id sea válido
    if (!$order_id) {
        error_log("ft_enviar_pedido_a_api: order_id inválido");
        return false;
    }
    
    // Verificar si la función ya se ejecutó exitosamente para este pedido
    if (get_post_meta($order_id, '_order_api_sent', true) === 'yes') {
        // El pedido ya fue enviado correctamente
        return true;
    }
    
    // Obtener el objeto de pedido
    $order = wc_get_order($order_id);
    if (!$order) {
        error_log("ft_enviar_pedido_a_api: No se pudo obtener el pedido #$order_id");
        return false;
    }
    
    // Marca temporal para indicar que se inició el proceso
    update_post_meta($order_id, '_api_process_started', 'yes');
    update_post_meta($order_id, '_api_last_attempt', current_time('mysql'));
    
    // Iniciar log de debug
    $log_path = $_SERVER['DOCUMENT_ROOT'] . '/api/';
    $fp = fopen($log_path . 'response_' . $order_id . '.txt', 'a+');
    $TrackError = fopen($log_path . 'trackerror_' . $order_id . '.txt', 'a+');
    fwrite($fp, "--- Intento de sincronización: " . current_time('mysql') . " ---\n");
    
    try {
        // Obtener datos del pedido
        $order_data = $order->get_data();

        // Obtener datos del cliente y envío desde metadatos del pedido
        $customer_data = array();
        foreach ($order->get_meta_data() as $item) {
            $item_data = $item->get_data();
            $keys_to_map = array(
                '_billing_nro_doc' => 'CLI_NRO_DOC',
                '_billing_tipo_doc' => 'CLI_TIPO_DOC',
                '_billing_razon_social' => 'CLI_RAZON_SOCIAL',
                'billing_lat' => 'ECO_LATITUD',
                'billing_long' => 'ECO_LONGITUD',
                'billing_sucursal' => 'ECO_ENV_SUC',
            );
            if (isset($keys_to_map[$item_data['key']])) {
                $customer_data[$keys_to_map[$item_data['key']]] = $item_data['value'];
            }
        }

        // Verificar datos críticos
        if (empty($customer_data['CLI_NRO_DOC'])) {
            $customer_data['CLI_NRO_DOC'] = '0';
            fwrite($TrackError, "Advertencia: CLI_NRO_DOC vacío en pedido #$order_id\n");
        }
        
        if (empty($customer_data['CLI_TIPO_DOC'])) {
            $customer_data['CLI_TIPO_DOC'] = '1'; // Valor predeterminado
            fwrite($TrackError, "Advertencia: CLI_TIPO_DOC vacío en pedido #$order_id\n");
        }
        
        if (empty($customer_data['CLI_RAZON_SOCIAL'])) {
            $customer_data['CLI_RAZON_SOCIAL'] = $order->get_billing_first_name() . ' ' . $order->get_billing_last_name();
            fwrite($TrackError, "Advertencia: CLI_RAZON_SOCIAL vacío en pedido #$order_id\n");
        }

        // Obtener otros datos del pedido
        $sucursal = function_exists('obtener_codigo_erp_desde_cookie') ? obtener_codigo_erp_desde_cookie() : '';
        $direccion_envio = $order->get_billing_address_1();
        $pedido_ciudad = $order->get_billing_city();
        $depto_envio = $order->get_billing_state();
        $metodo_envio = function_exists('wl8_get_metodo_envio') ? wl8_get_metodo_envio($order->get_shipping_method()) : $order->get_shipping_method();
        $medio_de_pago = function_exists('wl8_get_medio_pago') ? wl8_get_medio_pago($order->get_payment_method_title()) : $order->get_payment_method_title();
        $estado_del_pedido = function_exists('wl8_get_estado_pedido') ? wl8_get_estado_pedido($order->get_status()) : $order->get_status();
        $telefono_cliente = $order->get_billing_phone();
        $numero_pedido = $order->get_id();
        $numero_proceso = $order->get_order_key();
        $cli_cogido = $order->get_customer_id();
        $total_descuento = $order->get_discount_total();
        $cupon = $order->get_coupon_codes();
        $nota_pedido = $order->get_customer_note();
        $order_total = $order->get_total();

        // Obtener detalles de los productos del pedido
        $itemsAenviar = array();
        foreach ($order->get_items() as $item) {
            $product = $item->get_product();
            $product_SKU = $product ? $product->get_sku() : '';
            $producto_nombre = $item->get_name();
            $cantidad = $item->get_quantity();
            $total = $item->get_total();
            $porc_dcto = $product ? get_post_meta($product->get_id(), 'porc_dcto', true) : '';
            $cod_promo = $product ? get_post_meta($product->get_id(), 'cod_promocion', true) : '';

            $itemsAenviar[] = array(
                'EDET_NRO_ITEM' => count($itemsAenviar) + 1,
                'EDET_SKU' => $product_SKU,
                'EDET_DESC' => $producto_nombre,
                'EDET_CANT' => $cantidad,
                'EDET_PRECIO' => $total,
                'EDET_PORC_DCTO' => $porc_dcto,
                'EDET_COD_PROMO' => $cod_promo,
            );
        }

        // Obtener la fecha actual
        date_default_timezone_set('America/Asuncion');
        $now = date('Y-m-d\TH:i:s\Z');

        // Crear el arreglo de datos para la venta
        $venta = array(
            'ECO_PEDIDO' => 400000 + $numero_pedido,
            'ECO_PEDIDO_ALF' => $numero_proceso,
            'ECO_VENTA' => array(
                array(
                    'ECO_TIPO' => '1',
                    'ECO_MON' => '1',
                    'ECO_FEC_PED' => $now,
                    'ECO_ESTADO' => $estado_del_pedido,
                    'ECO_MET_PAGO' => $medio_de_pago,
                    'ECO_OPC_DELIVERY' => $metodo_envio,
                    'ECO_DESCUENTO' => $total_descuento,
                    'ECO_CUPON' => $cupon,
                    'ECO_TOTAL' => $order_total,
                ),
            ),
            'ECO_DETALLE' => $itemsAenviar,
            'ECO_CLIENTE' => array(
                array(
                    'CLI_CODIGO' => $cli_cogido,
                    'CLI_RAZON_SOCIAL' => $customer_data['CLI_RAZON_SOCIAL'],
                    'CLI_TIPO_DOC' => $customer_data['CLI_TIPO_DOC'],
                    'CLI_NRO_DOC' => $customer_data['CLI_NRO_DOC'],
                    'CLI_TELEFONO' => $telefono_cliente,
                ),
            ),
            'ECO_ENVIO' => array(
                array(
                    'ECO_ENV_TIPO' => 1,
                    'ECO_ENV_DIR' => $direccion_envio ?? 'SIN DIRECCION 123',
                    'ECO_ENV_CIUDAD' => $pedido_ciudad ?? 'SIN CIUDAD',
                    'ECO_ENV_DEP' => $depto_envio ?? 'SIN DEPARTAMENTO',
                    'ECO_ENV_SUC' => $sucursal ?? $customer_data['ECO_ENV_SUC'] ?? '',
                    'ECO_ENV_TEL' => $telefono_cliente ?? 'SIN TELEFONO',
                    'ECO_LATITUD' => $customer_data['ECO_LATITUD'] ?? 0,
                    'ECO_LONGITUD' => $customer_data['ECO_LONGITUD'] ?? 0,
                    'ECO_OBS' => $nota_pedido,
                ),
            ),
        );

        // Endpoint de la API
        $endpoint = 'https://api.desarrollo.farmatotal.com.py/farma/rws/ecommerce/save_order';

        // Preparar cuerpo de la solicitud
        $body = wp_json_encode(
            $venta,
            true,
            JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
        );
        
        // Guardar el JSON enviado para debugging
        update_post_meta($order_id, '_api_request_body', $body);
        fwrite($fp, "Cuerpo de la solicitud: " . $body . "\n");

        // Configurar opciones de la solicitud
        $options = [
            'method' => 'POST',
            'sslverify' => false,
            'body' => $body,
            'headers' => [
                'Content-Type' => 'application/json',
            ],
            'timeout' => 120, // 2 minutos, más razonable que 10 minutos
            'redirection' => 5,
            'blocking' => true,
            'data_format' => 'body',
        ];

        // Enviar solicitud a la API (Excepto para documento específico de prueba)
        if ($customer_data['CLI_NRO_DOC'] != '9661000') {    
            $request = wp_remote_post($endpoint, $options);
        } else {
            fwrite($fp, "Pedido de prueba con CLI_NRO_DOC=9661000. No se envía a API.\n");
            // Simular éxito para pedidos de prueba
            update_post_meta($order_id, '_order_api_sent', 'yes');
            fclose($fp);
            fclose($TrackError);
            return true;
        }

        // Procesar respuesta
        if (is_wp_error($request)) {
            // Error de WordPress al hacer la solicitud
            $error_code = $request->get_error_code();
            $error_message = $request->get_error_message();
            
            fwrite($TrackError, "Error WP: ($error_code) $error_message\n");
            error_log("Error al enviar pedido #$order_id a API. Error WP: ($error_code) $error_message");
            
            // Guardar metadatos del error
            update_post_meta($order_id, '_api_error', json_encode([
                'time' => current_time('mysql'),
                'code' => $error_code,
                'message' => $error_message
            ]));
            
            // Incrementar contador de intentos
            $attemptCount = intval(get_post_meta($order_id, '_api_attempts', true)) + 1;
            update_post_meta($order_id, '_api_attempts', $attemptCount);
            
            // Añadir nota al pedido
            $message = sprintf('Error de sincronización con API: Nro Pedido: [%s] Error: [%s]', 
                $order_id, 
                "$error_code: $error_message"
            );
            $order->add_order_note(__($message, 'ecom_recibir_venta'));
            
            fclose($fp);
            fclose($TrackError);
            return false;
        } elseif (wp_remote_retrieve_response_code($request) != 200) {
            // Respuesta no exitosa de la API
            $response_code = wp_remote_retrieve_response_code($request);
            $response = wp_remote_retrieve_body($request);
            
            fwrite($TrackError, "Error API HTTP $response_code: $response\n");
            error_log("Error al enviar pedido #$order_id a API. HTTP $response_code: $response");
            
            // Guardar metadatos del error
            update_post_meta($order_id, '_api_error', json_encode([
                'time' => current_time('mysql'),
                'code' => $response_code,
                'response' => $response
            ]));
            
            // Incrementar contador de intentos
            $attemptCount = intval(get_post_meta($order_id, '_api_attempts', true)) + 1;
            update_post_meta($order_id, '_api_attempts', $attemptCount);
            
            // Añadir nota al pedido
            $message = sprintf('e-Commerce Sync Error: Nro Pedido: [%s] Respuesta ERP (HTTP %s): [%s]', 
                sanitize_text_field($order_id), 
                $response_code,
                sanitize_text_field($response)
            );
            $order->add_order_note(__($message, 'ecom_recibir_venta'));
            
            // Guardar para depuración
            update_post_meta($order->get_id(), 'pos_recibir_venta', $response);
            fwrite($fp, $body); // Guardar lo que se intentó enviar
            
            fclose($fp);
            fclose($TrackError);
            return false;
        } else {
            // Éxito - Guardar la respuesta y marcar como enviado
            $response = wp_remote_retrieve_body($request);
            $decode = json_decode($response);
            
            fwrite($fp, "Respuesta exitosa: $response\n");
            error_log("Pedido #$order_id enviado correctamente a la API");
            
            // Marcarlo como enviado exitosamente
            update_post_meta($order_id, '_order_api_sent', 'yes');
            update_post_meta($order_id, '_api_success_time', current_time('mysql'));
            update_post_meta($order->get_id(), 'pos_recibir_venta', $response);
            
            // Añadir nota al pedido
            $message = sprintf('e-Commerce Sync Completada: Nro Pedido: [%s] Respuesta ERP: [%s]', 
                sanitize_text_field($order_id), 
                sanitize_text_field(isset($decode->msg) ? $decode->msg : 'OK')
            );
            $order->add_order_note(__($message, 'ecom_recibir_venta'));
            
            // Si se configuró así, cambiar el estado del pedido a completado
            $order->update_status('completed');
            
            // Guardar información de sucursal para referencia
            $order->add_order_note(__('Sucursal de Envío: ' . 
                (isset($customer_data['ECO_ENV_SUC']) ? $customer_data['ECO_ENV_SUC'] : 'No especificada'), 
                'ecom_sucursal_envio'
            ));
            
            // Guardar JSON para referencia
            $order->update_meta_data('json', $body);
            
            fclose($fp);
            fclose($TrackError);
            return true;
        }
    } catch (Exception $e) {
        // Manejo de excepciones inesperadas
        $error_message = $e->getMessage();
        fwrite($TrackError, "Excepción: " . $error_message . "\n");
        error_log("Excepción al enviar pedido #$order_id a API: " . $error_message);
        
        // Guardar metadatos del error
        update_post_meta($order_id, '_api_error', json_encode([
            'time' => current_time('mysql'),
            'exception' => $error_message
        ]));
        
        // Incrementar contador de intentos
        $attemptCount = intval(get_post_meta($order_id, '_api_attempts', true)) + 1;
        update_post_meta($order_id, '_api_attempts', $attemptCount);
        
        // Añadir nota al pedido
        $message = sprintf('Error de sincronización con API (Excepción): Nro Pedido: [%s] Error: [%s]', 
            $order_id, 
            $error_message
        );
        $order->add_order_note(__($message, 'ecom_recibir_venta'));
        
        fclose($fp);
        fclose($TrackError);
        return false;
    }
}

/**
 * Programar reintentos para pedidos fallidos
 */
add_action('init', function() {
    if (!wp_next_scheduled('ft_reintentar_envios_fallidos')) {
        wp_schedule_event(time(), 'hourly', 'ft_reintentar_envios_fallidos');
    }
});

/**
 * Hook para el evento programado de reintentos
 */
add_action('ft_reintentar_envios_fallidos', 'ft_verificar_pedidos_pendientes');

/**
 * Función para buscar pedidos pendientes y reintentarlos
 */
function ft_verificar_pedidos_pendientes() {
    error_log("Iniciando verificación de pedidos pendientes para sincronización con API...");
    
    // Buscar pedidos que iniciaron el proceso pero no se enviaron exitosamente
    $args = array(
        'post_type' => 'shop_order',
        'post_status' => 'any', // Todos los estados de pedido
        'meta_query' => array(
            'relation' => 'AND',
            array(
                'key' => '_api_process_started',
                'value' => 'yes',
                'compare' => '='
            ),
            array(
                'relation' => 'OR',
                array(
                    'key' => '_order_api_sent',
                    'compare' => 'NOT EXISTS'
                ),
                array(
                    'key' => '_order_api_sent',
                    'value' => 'yes',
                    'compare' => '!='
                )
            ),
            // Solo considerar pedidos de los últimos 7 días (configurable)
            array(
                'key' => '_api_attempts',
                'compare' => '<',
                'value' => 10, // Máximo 10 intentos
                'type' => 'NUMERIC'
            )
        ),
        'date_query' => array(
            'after' => '7 days ago'
        ),
        'posts_per_page' => 20, // Procesar 20 a la vez para no sobrecargar
    );
    
    $query = new WP_Query($args);
    $count = 0;
    
    if ($query->have_posts()) {
        error_log("Se encontraron " . $query->post_count . " pedidos pendientes para sincronizar.");
        
        while ($query->have_posts()) {
            $query->the_post();
            $order_id = get_the_ID();
            
            // Obtener último intento
            $last_attempt = get_post_meta($order_id, '_api_last_attempt', true);
            $now = current_time('mysql');
            
            // Si el último intento fue hace menos de 30 minutos, saltarlo
            if ($last_attempt && (strtotime($now) - strtotime($last_attempt)) < 1800) {
                continue;
            }
            
            // Registrar reintento en log
            error_log("Reintentando envío del pedido #$order_id a la API");
            
            // Reintentar envío
            $result = ft_enviar_pedido_a_api($order_id);
            $count++;
            
            // Pausa breve para no sobrecargar la API
            if ($count % 5 == 0) {
                sleep(3);
            }
        }
        
        error_log("Finalizada la sincronización de pedidos pendientes. Se procesaron $count pedidos.");
    } else {
        error_log("No se encontraron pedidos pendientes para sincronizar.");
    }
    
    wp_reset_postdata();
}

/**
 * Añadir meta box para información de sincronización en admin
 */
add_action('add_meta_boxes', 'ft_add_api_sync_meta_box');

function ft_add_api_sync_meta_box() {
    add_meta_box(
        'ft_api_sync_info',
        'Información de Sincronización API',
        'ft_api_sync_meta_box_callback',
        'shop_order',
        'side',
        'high'
    );
}

/**
 * Contenido del meta box de sincronización
 */
function ft_api_sync_meta_box_callback($post) {
    $order_id = $post->ID;
    $is_sent = get_post_meta($order_id, '_order_api_sent', true) === 'yes';
    $attempts = intval(get_post_meta($order_id, '_api_attempts', true));
    $last_attempt = get_post_meta($order_id, '_api_last_attempt', true);
    $error_data = get_post_meta($order_id, '_api_error', true);
    
    if ($is_sent) {
        $success_time = get_post_meta($order_id, '_api_success_time', true);
        echo '<div style="background-color:#dff0d8; padding:10px; border-radius:4px;">';
        echo '<strong>Estado:</strong> ✅ Enviado correctamente<br>';
        echo '<strong>Fecha de envío:</strong> ' . $success_time;
        echo '</div>';
    } else {
        echo '<div style="background-color:#f2dede; padding:10px; border-radius:4px;">';
        echo '<strong>Estado:</strong> ⚠️ Pendiente de sincronización<br>';
        echo '<strong>Intentos:</strong> ' . $attempts . '<br>';
        
        if ($last_attempt) {
            echo '<strong>Último intento:</strong> ' . $last_attempt . '<br>';
        }
        
        if ($error_data) {
            $error = json_decode($error_data, true);
            echo '<strong>Último error:</strong> ';
            
            if (isset($error['code'])) {
                echo 'Código: ' . $error['code'] . '<br>';
            }
            
            if (isset($error['message'])) {
                echo 'Mensaje: ' . substr($error['message'], 0, 100) . 
                    (strlen($error['message']) > 100 ? '...' : '');
            } else if (isset($error['exception'])) {
                echo 'Excepción: ' . substr($error['exception'], 0, 100) . 
                    (strlen($error['exception']) > 100 ? '...' : '');
            }
        }
        
        echo '</div>';
        echo '<p><button type="button" class="button" id="ft-retry-api-sync" data-order="' . $order_id . '">Reintentar sincronización</button></p>';
        
        // JavaScript para funcionalidad de botón de reintento
        ?>
        <script type="text/javascript">
        jQuery(document).ready(function($) {
            $('#ft-retry-api-sync').on('click', function() {
                var button = $(this);
                var order_id = button.data('order');
                
                button.prop('disabled', true).text('Sincronizando...');
                
                $.ajax({
                    url: ajaxurl,
                    type: 'POST',
                    data: {
                        action: 'ft_retry_api_sync',
                        order_id: order_id,
                        security: '<?php echo wp_create_nonce('ft-retry-api-sync'); ?>'
                    },
                    success: function(response) {
                        if (response.success) {
                            location.reload();
                        } else {
                            alert('Error: ' + response.data);
                            button.prop('disabled', false).text('Reintentar sincronización');
                        }
                    },
                    error: function() {
                        alert('Ocurrió un error en la solicitud.');
                        button.prop('disabled', false).text('Reintentar sincronización');
                    }
                });
            });
        });
        </script>
        <?php
    }
}

/**
 * Ajax para reintentar sincronización manualmente
 */
add_action('wp_ajax_ft_retry_api_sync', 'ft_ajax_retry_api_sync');

function ft_ajax_retry_api_sync() {
    // Verificar nonce
    check_ajax_referer('ft-retry-api-sync', 'security');
    
    // Verificar permisos
    if (!current_user_can('edit_shop_orders')) {
        wp_send_json_error('Permisos insuficientes');
    }
    
    // Obtener ID del pedido
    $order_id = isset($_POST['order_id']) ? intval($_POST['order_id']) : 0;
    
    if (!$order_id) {
        wp_send_json_error('ID de pedido inválido');
    }
    
    // Intentar sincronización
    $result = ft_enviar_pedido_a_api($order_id);
    
    if ($result) {
        wp_send_json_success('Pedido sincronizado correctamente');
    } else {
        wp_send_json_error('La sincronización falló. Revise los logs para más detalles.');
    }
}

/**
 * Añadir columna de estado de sincronización en el listado de pedidos
 */
add_filter('manage_edit-shop_order_columns', 'ft_add_order_sync_column');

function ft_add_order_sync_column($columns) {
    $new_columns = array();
    
    foreach ($columns as $column_name => $column_info) {
        $new_columns[$column_name] = $column_info;
        
        if ($column_name === 'order_status') {
            $new_columns['api_sync'] = 'Sincronización API';
        }
    }
    
    return $new_columns;
}

/**
 * Mostrar estado de sincronización en la columna
 */
add_action('manage_shop_order_posts_custom_column', 'ft_show_order_sync_column_content');

function ft_show_order_sync_column_content($column) {
    global $post;
    
    if ($column == 'api_sync') {
        $order_id = $post->ID;
        $is_sent = get_post_meta($order_id, '_order_api_sent', true) === 'yes';
        $attempts = intval(get_post_meta($order_id, '_api_attempts', true));
        
        if ($is_sent) {
            echo '<mark class="order-status status-completed"><span>✅ Sincronizado</span></mark>';
        } else if ($attempts > 0) {
            echo '<mark class="order-status status-failed"><span>⚠️ Pendiente (' . $attempts . ' intentos)</span></mark>';
        } else if (get_post_meta($order_id, '_api_process_started', true) === 'yes') {
            echo '<mark class="order-status status-on-hold"><span>⏱️ En proceso</span></mark>';
        } else {
            echo '<mark class="order-status status-processing"><span>❓ No iniciado</span></mark>';
        }
    }
}

/**
 * Añadir un filtro en el listado de pedidos para encontrar pedidos con problemas de sincronización
 */
add_action('restrict_manage_posts', 'ft_add_shop_order_sync_filter');

function ft_add_shop_order_sync_filter() {
    global $typenow;
    
    if ($typenow == 'shop_order') {
        $current = isset($_GET['api_sync_status']) ? $_GET['api_sync_status'] : '';
        ?>
        <select name="api_sync_status">
            <option value="">Estado de sincronización</option>
            <option value="synced" <?php selected('synced', $current); ?>>Sincronizados</option>
            <option value="pending" <?php selected('pending', $current); ?>>Pendientes</option>
            <option value="not_started" <?php selected('not_started', $current); ?>>No iniciados</option>
        </select>
        <?php
    }
}

/**
 * Implementar la lógica del filtro
 */
add_filter('parse_query', 'ft_shop_order_sync_filter_query');

function ft_shop_order_sync_filter_query($query) {
    global $pagenow, $typenow;
    
    if ($pagenow == 'edit.php' && $typenow == 'shop_order' && isset($_GET['api_sync_status'])) {
        $status = $_GET['api_sync_status'];
        
        if (!empty($status)) {
            $meta_query = $query->get('meta_query') ? $query->get('meta_query') : array();
            
            if ($status == 'synced') {
                $meta_query[] = array(
                    'key' => '_order_api_sent',
                    'value' => 'yes',
                    'compare' => '='
                );
            } else if ($status == 'pending') {
                $meta_query[] = array(
                    'relation' => 'AND',
                    array(
                        'key' => '_api_process_started',
                        'value' => 'yes',
                        'compare' => '='
                    ),
                    array(
                        'relation' => 'OR',
                        array(
                            'key' => '_order_api_sent',
                            'compare' => 'NOT EXISTS'
                        ),
                        array(
                            'key' => '_order_api_sent',
                            'value' => 'yes',
                            'compare' => '!='
                        )
                    )
                );
            } else if ($status == 'not_started') {
                $meta_query[] = array(
                    'key' => '_api_process_started',
                    'compare' => 'NOT EXISTS'
                );
            }
            
            $query->set('meta_query', $meta_query);
        }
    }
}

/**
 * Registrar una acción masiva para sincronizar pedidos
 */
add_filter('bulk_actions-edit-shop_order', 'ft_register_bulk_sync_action');

function ft_register_bulk_sync_action($bulk_actions) {
    $bulk_actions['sync_with_api'] = 'Sincronizar con API';
    return $bulk_actions;
}

/**
 * Manejar la acción masiva de sincronización
 */
add_filter('handle_bulk_actions-edit-shop_order', 'ft_handle_bulk_sync_action', 10, 3);

function ft_handle_bulk_sync_action($redirect_to, $action, $post_ids) {
    if ($action !== 'sync_with_api') {
        return $redirect_to;
    }
    
    $synced = 0;
    $failed = 0;
    
    foreach ($post_ids as $post_id) {
        $result = ft_enviar_pedido_a_api($post_id);
        if ($result) {
            $synced++;
        } else {
            $failed++;
        }
    }
    
    $redirect_to = add_query_arg(
        array(
            'bulk_synced' => $synced,
            'bulk_failed' => $failed
        ),
        $redirect_to
    );
    
    return $redirect_to;
}

/**
 * Mostrar mensaje de resultado de la acción masiva
 */
add_action('admin_notices', 'ft_bulk_sync_admin_notice');

function ft_bulk_sync_admin_notice() {
    if (empty($_REQUEST['bulk_synced']) && empty($_REQUEST['bulk_failed'])) {
        return;
    }
    
    $synced = isset($_REQUEST['bulk_synced']) ? intval($_REQUEST['bulk_synced']) : 0;
    $failed = isset($_REQUEST['bulk_failed']) ? intval($_REQUEST['bulk_failed']) : 0;
    
    if ($synced > 0 && $failed == 0) {
        $message = sprintf('Se sincronizaron %d pedidos correctamente.', $synced);
        $class = 'notice-success';
    } else if ($synced > 0 && $failed > 0) {
        $message = sprintf('Se sincronizaron %d pedidos correctamente y %d fallaron. Revise los logs para más detalles.', $synced, $failed);
        $class = 'notice-warning';
    } else {
        $message = sprintf('Fallaron %d pedidos. Revise los logs para más detalles.', $failed);
        $class = 'notice-error';
    }
    
    printf('<div class="notice %s is-dismissible"><p>%s</p></div>', $class, $message);
}