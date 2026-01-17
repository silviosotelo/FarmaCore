<?php
/**
 * stock-validation.php
 * Include in your theme's functions.php:
 * require_once get_stylesheet_directory() . '/inc/stock-validation.php';
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit; // No direct access
}

/**
 * AJAX stock check for WooCommerce core and Bacola
 */
if ( ! function_exists( 'ft_ajax_stock_check' ) ) {
    function ft_ajax_stock_check() {
        // Detect wc-ajax endpoint
        $endpoint = $_REQUEST['wc-ajax'] ?? '';
        error_log('[FT] ft_ajax_stock_check triggered, wc-ajax=' . $endpoint);

        // Determine relevant AJAX action
        if ( 'add_to_cart' === $endpoint ) {
            $product_id = absint( $_REQUEST['product_id'] ?? 0 );
            $quantity   = absint( $_REQUEST['quantity']   ?? 1 );
        } elseif ( 'bacola_add_to_cart_archive' === $endpoint ) {
            $product_id = absint( $_REQUEST['add-to-cart'] ?? 0 );
            $quantity   = absint( $_REQUEST['quantity']    ?? 1 );
        } else {
            return; // Ignore other AJAX calls
        }

        // Load product
        $product = wc_get_product( $product_id );
        if ( ! $product ) {
            return;
        }

        // Prepare SKU and ERP code
        $sku = $product->get_sku() ?: (string) $product_id;
        $erp = function_exists('obtener_codigo_erp_desde_cookie')
             ? obtener_codigo_erp_desde_cookie()
             : null;

        // Build API payload
        $payload = [
            'STK_SUCURSAL' => $erp,
            'STK_DETALLE'  => [[
                'STK_NRO_ITEM'  => 1,
                'STK_ARTICULO'  => $sku,
                'STK_CANTIDAD'  => $quantity,
                'STK_PORC_DCTO' => 0,
                'STK_COD_PROMO'=> 0,
            ]]
        ];
        $url  = 'https://api.desarrollo.farmatotal.com.py/farma/next/ecommerce/producto/stock';
        $resp = wp_remote_post( $url, [
            'headers' => [ 'Content-Type' => 'application/json; charset=utf-8' ],
            'body'    => wp_json_encode( $payload ),
            'timeout' => 5,
        ] );

        // Debug logging
        if ( defined('WP_DEBUG') && WP_DEBUG ) {
            error_log('[FT] Payload: ' . wp_json_encode($payload));
            if ( is_wp_error($resp) ) {
                error_log('[FT] WP_Error: ' . $resp->get_error_message());
            } else {
                error_log('[FT] HTTP: ' . wp_remote_retrieve_response_code($resp));
                error_log('[FT] Body: ' . wp_remote_retrieve_body($resp));
            }
        }

        // On network error, return generic JSON error
        if ( is_wp_error($resp) ) {
            wp_send_json_error( [ 'message' => 'Error al verificar stock.' ] );
        }

        // Decode API response
        $body = json_decode( wp_remote_retrieve_body($resp), true );
        $item = $body['value'][0] ?? null;

        // If no stock, use wc_add_notice and return fragments
        if ( ! $item || $item['stk_cant_act'] < $quantity ) {
            // Register a WooCommerce error notice
            wc_add_notice(
                sprintf(
                    'Lo sentimos, sólo quedan %d unidades de "%s".',
                    $item['stk_cant_act'] ?? 0,
                    $product->get_name()
                ),
                'error'
            );

            // Capture HTML and clear notices
            $notices_html = wc_print_notices( [ 'return' => true ] );
            wc_clear_notices();

            // Return JSON in Bacola format
            wp_send_json(
                [
                    'error'     => false,
                    'fragments' => [ 'notices_html' => $notices_html ]
                ]
            );
        }

        // Otherwise, allow WooCommerce to proceed normally
        return;
    }

    // Hook into WooCommerce AJAX actions with high priority (5)
    add_action( 'wc_ajax_nopriv_add_to_cart',                'ft_ajax_stock_check', 5 );
    add_action( 'wc_ajax_add_to_cart',                       'ft_ajax_stock_check', 5 );
    add_action( 'wc_ajax_nopriv_bacola_add_to_cart_archive', 'ft_ajax_stock_check', 5 );
    add_action( 'wc_ajax_bacola_add_to_cart_archive',        'ft_ajax_stock_check', 5 );
}

/**
 * Form submission stock check (product single) before WooCommerce handler
 */
if ( ! function_exists( 'ft_validate_stock_on_form_add' ) ) {
    function ft_validate_stock_on_form_add() {
        // Skip AJAX requests or if no add-to-cart parameter
        if ( wp_doing_ajax() || empty( $_REQUEST['add-to-cart'] ) ) {
            return;
        }

        $product_id = absint( $_REQUEST['add-to-cart'] );
        $quantity   = absint( $_REQUEST['quantity']    ?? 1 );
        $product    = wc_get_product( $product_id );
        if ( ! $product ) {
            return;
        }

        // Ensure ERP code is set
        $erp = function_exists('obtener_codigo_erp_desde_cookie')
             ? obtener_codigo_erp_desde_cookie()
             : null;
        if ( ! $erp ) {
            wc_add_notice( 'Por favor, selecciona primero una sucursal.', 'error' );
            wp_safe_redirect( get_permalink( $product_id ) );
            exit;
        }

        // Build payload
        $sku = $product->get_sku() ?: (string) $product_id;
        $payload = [
            'STK_SUCURSAL' => $erp,
            'STK_DETALLE'  => [[
                'STK_NRO_ITEM'  => 1,
                'STK_ARTICULO'  => $sku,
                'STK_CANTIDAD'  => $quantity,
                'STK_PORC_DCTO' => 0,
                'STK_COD_PROMO'=> 0,
            ]]
        ];

        $url  = 'https://api.desarrollo.farmatotal.com.py/farma/next/ecommerce/producto/stock';
        $resp = wp_remote_post( $url, [
            'headers' => [ 'Content-Type' => 'application/json; charset=utf-8' ],
            'body'    => wp_json_encode($payload),
            'timeout' => 5,
        ] );

        // Debug
        if ( defined('WP_DEBUG') && WP_DEBUG ) {
            error_log('[FT_form] Payload: ' . wp_json_encode($payload));
            if ( is_wp_error($resp) ) {
                error_log('[FT_form] WP_Error: ' . $resp->get_error_message());
            } else {
                error_log('[FT_form] HTTP: ' . wp_remote_retrieve_response_code($resp));
                error_log('[FT_form] Body: ' . wp_remote_retrieve_body($resp));
            }
        }

        // On error, show notice and redirect
        if ( is_wp_error($resp) ) {
            wc_add_notice('Error al verificar stock. Intenta de nuevo.', 'error');
            wp_safe_redirect( get_permalink( $product_id ) );
            exit;
        }

        $body = json_decode( wp_remote_retrieve_body($resp), true );
        $item = $body['value'][0] ?? null;
        if ( ! $item || $item['stk_cant_act'] < $quantity ) {
            wc_add_notice(
                sprintf(
                    'Lo sentimos, sólo quedan %d unidades de "%s".',
                    $item['stk_cant_act'] ?? 0,
                    $product->get_name()
                ),
                'error'
            );
            wp_safe_redirect( get_permalink( $product_id ) );
            exit;
        }
    }
    // Hook early in init before WooCommerce handlers (priority < 20)
    add_action( 'init', 'ft_validate_stock_on_form_add', 9 );
}
