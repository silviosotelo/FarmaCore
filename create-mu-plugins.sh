cat > create-mu-plugins.sh <<'MU_SCRIPT'
#!/bin/bash
#########################################################################
# Crear MU-Plugins para Multi-Tenant
#########################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${BLUE}➜${NC} $1"; }

WP_DIR="/var/www/woo-enterprise"
MU_DIR="$WP_DIR/wp-content/mu-plugins"

info "Creando MU-Plugins..."

mkdir -p "$MU_DIR"

#########################################################################
# 00-tenant-bootstrap.php
#########################################################################

cat > "$MU_DIR/00-tenant-bootstrap.php" <<'PHP'
<?php
/**
 * Plugin Name: Tenant Bootstrap
 * Description: Detecta y carga el tenant actual
 * Version: 1.0.0
 * Author: WooCommerce Enterprise
 */

if (!defined('ABSPATH')) exit;

// Constantes globales
define('WOO_ENTERPRISE_VERSION', '1.0.0');
define('WOO_ENTERPRISE_MASTER_DB', 'master_wp');

/**
 * Detectar tenant actual
 */
function woo_enterprise_detect_tenant() {
    global $wpdb;
    
    $http_host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    
    // Conectar a master DB
    $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
    
    // Buscar tenant por dominio
    $tenant = $master_db->get_row($master_db->prepare(
        "SELECT * FROM master_tenants WHERE domain = %s AND status = 'active' LIMIT 1",
        $http_host
    ));
    
    // Si no encuentra, buscar por slug en subdomain
    if (!$tenant) {
        $subdomain = explode('.', $http_host)[0];
        $tenant = $master_db->get_row($master_db->prepare(
            "SELECT * FROM master_tenants WHERE slug = %s AND status = 'active' LIMIT 1",
            $subdomain
        ));
    }
    
    return $tenant;
}

/**
 * Cambiar a DB del tenant
 */
function woo_enterprise_switch_tenant_db($tenant) {
    global $wpdb, $table_prefix;
    
    if (!$tenant) {
        return false;
    }
    
    // Cambiar DB
    $wpdb->select($tenant->db_name);
    
    // Si el tenant tiene prefix custom, usarlo
    if (!empty($tenant->db_prefix)) {
        $table_prefix = $tenant->db_prefix;
        $wpdb->set_prefix($table_prefix);
    }
    
    // Guardar tenant en global
    $GLOBALS['current_tenant'] = $tenant;
    
    return true;
}

/**
 * Helper: Obtener tenant actual
 */
function woo_get_current_tenant() {
    return $GLOBALS['current_tenant'] ?? null;
}

/**
 * Helper: Verificar si es super admin
 */
function woo_is_super_admin() {
    // Solo cuando está en master_wp
    global $wpdb;
    return ($wpdb->dbname === WOO_ENTERPRISE_MASTER_DB && current_user_can('manage_options'));
}

// Ejecutar detección (solo si no estamos en instalación)
if (!defined('WP_INSTALLING') || !WP_INSTALLING) {
    $current_tenant = woo_enterprise_detect_tenant();
    
    if ($current_tenant) {
        woo_enterprise_switch_tenant_db($current_tenant);
        
        // Log en debug
        if (defined('WP_DEBUG') && WP_DEBUG) {
            error_log(sprintf(
                '[Tenant] Loaded: %s (DB: %s)',
                $current_tenant->slug,
                $current_tenant->db_name
            ));
        }
    }
}
PHP

ok "MU-Plugin: 00-tenant-bootstrap.php"

#########################################################################
# tenant-functions.php
#########################################################################

cat > "$MU_DIR/tenant-functions.php" <<'PHP'
<?php
/**
 * Plugin Name: Tenant Functions
 * Description: Funciones helper para multi-tenant
 * Version: 1.0.0
 */

if (!defined('ABSPATH')) exit;

/**
 * Obtener todos los tenants
 */
function woo_get_all_tenants($status = 'active') {
    global $wpdb;
    
    $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
    
    $where = $status ? $master_db->prepare("WHERE status = %s", $status) : '';
    
    return $master_db->get_results("SELECT * FROM master_tenants $where ORDER BY created_at DESC");
}

/**
 * Obtener tenant por ID
 */
function woo_get_tenant($tenant_id) {
    global $wpdb;
    
    $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
    
    return $master_db->get_row($master_db->prepare(
        "SELECT * FROM master_tenants WHERE id = %d",
        $tenant_id
    ));
}

/**
 * Obtener tenant por slug
 */
function woo_get_tenant_by_slug($slug) {
    global $wpdb;
    
    $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
    
    return $master_db->get_row($master_db->prepare(
        "SELECT * FROM master_tenants WHERE slug = %s",
        $slug
    ));
}

/**
 * Crear tenant
 */
function woo_create_tenant($data) {
    global $wpdb;
    
    $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
    
    $defaults = [
        'slug' => '',
        'name' => '',
        'db_name' => '',
        'db_prefix' => 'wp_',
        'domain' => '',
        'status' => 'active',
        'created_at' => current_time('mysql')
    ];
    
    $data = wp_parse_args($data, $defaults);
    
    $result = $master_db->insert('master_tenants', $data);
    
    if ($result) {
        return $master_db->insert_id;
    }
    
    return false;
}

/**
 * Actualizar tenant
 */
function woo_update_tenant($tenant_id, $data) {
    global $wpdb;
    
    $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
    
    return $master_db->update(
        'master_tenants',
        $data,
        ['id' => $tenant_id]
    );
}

/**
 * Eliminar tenant (soft delete)
 */
function woo_delete_tenant($tenant_id) {
    return woo_update_tenant($tenant_id, ['status' => 'deleted']);
}

/**
 * Verificar si tenant existe
 */
function woo_tenant_exists($slug) {
    return (bool) woo_get_tenant_by_slug($slug);
}

/**
 * Obtener URL del tenant
 */
function woo_get_tenant_url($tenant, $path = '') {
    if (is_numeric($tenant)) {
        $tenant = woo_get_tenant($tenant);
    }
    
    if (!$tenant) {
        return '';
    }
    
    $protocol = is_ssl() ? 'https://' : 'http://';
    $domain = $tenant->domain ?: ($tenant->slug . '.' . $_SERVER['HTTP_HOST']);
    
    return $protocol . $domain . '/' . ltrim($path, '/');
}
PHP

ok "MU-Plugin: tenant-functions.php"

# Permisos
chown -R www-data:www-data "$MU_DIR"
chmod 755 "$MU_DIR"
chmod 644 "$MU_DIR"/*.php

ok "MU-Plugins instalados en: $MU_DIR"
MU_SCRIPT

chmod +x create-mu-plugins.sh
bash create-mu-plugins.sh