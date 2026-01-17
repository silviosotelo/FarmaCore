<?php
/**
 * Reiniciar Action Scheduler y tablas relacionadas
 * Agregar a functions.php temporalmente y luego ELIMINAR después de ejecutar
 */
add_action('init', function() {
    // Solo ejecutar para administradores
    if (!current_user_can('manage_options')) {
        return;
    }
    
    // Solo ejecutar al visitar la página de administración
    if (!is_admin()) {
        return;
    }
    
    // Verificar si ya se ejecutó
    if (get_option('as_reset_completed')) {
        return;
    }
    
    global $wpdb;
    
    // Limpiar tablas de Action Scheduler
    $tables = [
        $wpdb->prefix . 'actionscheduler_actions',
        $wpdb->prefix . 'actionscheduler_claims',
        $wpdb->prefix . 'actionscheduler_groups',
        $wpdb->prefix . 'actionscheduler_logs'
    ];
    
    foreach ($tables as $table) {
        $wpdb->query("TRUNCATE TABLE $table");
    }
    
    // Eliminar opciones relacionadas
    $wpdb->query("DELETE FROM $wpdb->options WHERE option_name LIKE 'action_scheduler_%'");
    $wpdb->query("DELETE FROM $wpdb->options WHERE option_name LIKE 'wc_schedule_%'");
    $wpdb->query("DELETE FROM $wpdb->options WHERE option_name = 'wc_pending_batch_processes'");
    
    // Marcar como completado
    update_option('as_reset_completed', true);
    
    // Mostrar notificación de éxito
    add_action('admin_notices', function() {
        echo '<div class="notice notice-success is-dismissible">';
        echo '<p>Action Scheduler ha sido reiniciado. Este mensaje aparecerá solo una vez.</p>';
        echo '</div>';
    });
}, 5);