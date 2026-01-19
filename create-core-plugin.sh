cat > create-core-plugin.sh <<'CORE_SCRIPT'
#!/bin/bash
#########################################################################
# Crear Plugin WooCommerce Enterprise Core
#########################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${BLUE}➜${NC} $1"; }

WP_DIR="/var/www/woo-enterprise"
PLUGIN_DIR="$WP_DIR/wp-content/plugins/woo-enterprise-core"

info "Creando plugin WooCommerce Enterprise Core..."

# Crear estructura
mkdir -p "$PLUGIN_DIR"/{includes,admin,assets/css,assets/js}

#########################################################################
# woo-enterprise-core.php (Plugin Principal)
#########################################################################

cat > "$PLUGIN_DIR/woo-enterprise-core.php" <<'PHP'
<?php
/**
 * Plugin Name: WooCommerce Enterprise Core
 * Plugin URI: https://woocommerce-enterprise.com
 * Description: Sistema multi-tenant para WooCommerce Enterprise
 * Version: 1.0.0
 * Author: WooCommerce Enterprise Team
 * Text Domain: woo-enterprise
 * Requires PHP: 8.0
 * Requires at least: 6.0
 */

if (!defined('ABSPATH')) exit;

// Constantes del plugin
define('WOO_ENTERPRISE_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('WOO_ENTERPRISE_PLUGIN_URL', plugin_dir_url(__FILE__));

/**
 * Clase principal del plugin
 */
class WooEnterpriseCore {
    
    private static $instance = null;
    
    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    private function __construct() {
        $this->load_dependencies();
        $this->init_hooks();
    }
    
    private function load_dependencies() {
        require_once WOO_ENTERPRISE_PLUGIN_DIR . 'includes/class-tenant.php';
        require_once WOO_ENTERPRISE_PLUGIN_DIR . 'includes/class-tenant-manager.php';
        
        // Admin
        if (is_admin()) {
            require_once WOO_ENTERPRISE_PLUGIN_DIR . 'admin/class-admin-dashboard.php';
        }
    }
    
    private function init_hooks() {
        add_action('admin_menu', [$this, 'add_admin_menu']);
        add_action('admin_enqueue_scripts', [$this, 'enqueue_admin_assets']);
    }
    
    public function add_admin_menu() {
        // Solo en master DB
        if (!woo_is_super_admin()) {
            return;
        }
        
        add_menu_page(
            __('Tenants', 'woo-enterprise'),
            __('Tenants', 'woo-enterprise'),
            'manage_options',
            'woo-tenants',
            [$this, 'render_tenants_page'],
            'dashicons-admin-multisite',
            3
        );
        
        add_submenu_page(
            'woo-tenants',
            __('Todos los Tenants', 'woo-enterprise'),
            __('Todos los Tenants', 'woo-enterprise'),
            'manage_options',
            'woo-tenants',
            [$this, 'render_tenants_page']
        );
        
        add_submenu_page(
            'woo-tenants',
            __('Crear Tenant', 'woo-enterprise'),
            __('Crear Tenant', 'woo-enterprise'),
            'manage_options',
            'woo-tenant-create',
            [$this, 'render_create_page']
        );
    }
    
    public function enqueue_admin_assets($hook) {
        if (strpos($hook, 'woo-tenant') === false) {
            return;
        }
        
        wp_enqueue_style(
            'woo-enterprise-admin',
            WOO_ENTERPRISE_PLUGIN_URL . 'assets/css/admin.css',
            [],
            '1.0.0'
        );
        
        wp_enqueue_script(
            'woo-enterprise-admin',
            WOO_ENTERPRISE_PLUGIN_URL . 'assets/js/admin.js',
            ['jquery'],
            '1.0.0',
            true
        );
    }
    
    public function render_tenants_page() {
        require_once WOO_ENTERPRISE_PLUGIN_DIR . 'admin/tenants-list.php';
    }
    
    public function render_create_page() {
        require_once WOO_ENTERPRISE_PLUGIN_DIR . 'admin/tenant-create.php';
    }
}

// Inicializar plugin
function woo_enterprise_core_init() {
    return WooEnterpriseCore::get_instance();
}

add_action('plugins_loaded', 'woo_enterprise_core_init');
PHP

ok "Plugin principal: woo-enterprise-core.php"

#########################################################################
# includes/class-tenant.php
#########################################################################

cat > "$PLUGIN_DIR/includes/class-tenant.php" <<'PHP'
<?php
/**
 * Clase Tenant
 */

if (!defined('ABSPATH')) exit;

class WooEnterprise_Tenant {
    
    public $id;
    public $slug;
    public $name;
    public $db_name;
    public $db_prefix;
    public $domain;
    public $status;
    public $created_at;
    
    public function __construct($data = []) {
        foreach ($data as $key => $value) {
            if (property_exists($this, $key)) {
                $this->$key = $value;
            }
        }
    }
    
    /**
     * Obtener URL del tenant
     */
    public function get_url($path = '') {
        $protocol = is_ssl() ? 'https://' : 'http://';
        $domain = $this->domain ?: ($this->slug . '.' . $_SERVER['HTTP_HOST']);
        return $protocol . $domain . '/' . ltrim($path, '/');
    }
    
    /**
     * Verificar si está activo
     */
    public function is_active() {
        return $this->status === 'active';
    }
    
    /**
     * Guardar cambios
     */
    public function save() {
        global $wpdb;
        
        $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
        
        $data = [
            'slug' => $this->slug,
            'name' => $this->name,
            'db_name' => $this->db_name,
            'db_prefix' => $this->db_prefix,
            'domain' => $this->domain,
            'status' => $this->status
        ];
        
        if ($this->id) {
            // Update
            $result = $master_db->update('master_tenants', $data, ['id' => $this->id]);
        } else {
            // Insert
            $data['created_at'] = current_time('mysql');
            $result = $master_db->insert('master_tenants', $data);
            
            if ($result) {
                $this->id = $master_db->insert_id;
            }
        }
        
        return $result !== false;
    }
    
    /**
     * Eliminar (soft delete)
     */
    public function delete() {
        $this->status = 'deleted';
        return $this->save();
    }
}
PHP

ok "Clase: Tenant"

#########################################################################
# includes/class-tenant-manager.php
#########################################################################

cat > "$PLUGIN_DIR/includes/class-tenant-manager.php" <<'PHP'
<?php
/**
 * Gestor de Tenants
 */

if (!defined('ABSPATH')) exit;

class WooEnterprise_Tenant_Manager {
    
    /**
     * Obtener todos los tenants
     */
    public static function get_all($status = 'active') {
        global $wpdb;
        
        $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
        
        $where = $status ? $master_db->prepare("WHERE status = %s", $status) : '';
        $results = $master_db->get_results("SELECT * FROM master_tenants $where ORDER BY created_at DESC");
        
        $tenants = [];
        foreach ($results as $data) {
            $tenants[] = new WooEnterprise_Tenant($data);
        }
        
        return $tenants;
    }
    
    /**
     * Obtener tenant por ID
     */
    public static function get($tenant_id) {
        global $wpdb;
        
        $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
        
        $data = $master_db->get_row($master_db->prepare(
            "SELECT * FROM master_tenants WHERE id = %d",
            $tenant_id
        ));
        
        return $data ? new WooEnterprise_Tenant($data) : null;
    }
    
    /**
     * Obtener por slug
     */
    public static function get_by_slug($slug) {
        global $wpdb;
        
        $master_db = new wpdb(DB_USER, DB_PASSWORD, WOO_ENTERPRISE_MASTER_DB, DB_HOST);
        
        $data = $master_db->get_row($master_db->prepare(
            "SELECT * FROM master_tenants WHERE slug = %s",
            $slug
        ));
        
        return $data ? new WooEnterprise_Tenant($data) : null;
    }
    
    /**
     * Crear tenant
     */
    public static function create($data) {
        $tenant = new WooEnterprise_Tenant($data);
        
        if ($tenant->save()) {
            return $tenant;
        }
        
        return false;
    }
    
    /**
     * Verificar si slug existe
     */
    public static function slug_exists($slug) {
        return (bool) self::get_by_slug($slug);
    }
}
PHP

ok "Clase: Tenant Manager"

#########################################################################
# admin/tenants-list.php
#########################################################################

cat > "$PLUGIN_DIR/admin/tenants-list.php" <<'PHP'
<?php
/**
 * Lista de Tenants
 */

if (!defined('ABSPATH')) exit;

$tenants = WooEnterprise_Tenant_Manager::get_all();
?>

<div class="wrap">
    <h1 class="wp-heading-inline">
        <?php _e('Tenants', 'woo-enterprise'); ?>
    </h1>
    
    <a href="<?php echo admin_url('admin.php?page=woo-tenant-create'); ?>" class="page-title-action">
        <?php _e('Crear Nuevo', 'woo-enterprise'); ?>
    </a>
    
    <hr class="wp-header-end">
    
    <?php if (empty($tenants)): ?>
        <div class="notice notice-info">
            <p><?php _e('No hay tenants creados aún.', 'woo-enterprise'); ?></p>
        </div>
    <?php else: ?>
        <table class="wp-list-table widefat fixed striped">
            <thead>
                <tr>
                    <th>ID</th>
                    <th><?php _e('Nombre', 'woo-enterprise'); ?></th>
                    <th><?php _e('Slug', 'woo-enterprise'); ?></th>
                    <th><?php _e('Dominio', 'woo-enterprise'); ?></th>
                    <th><?php _e('Base de Datos', 'woo-enterprise'); ?></th>
                    <th><?php _e('Estado', 'woo-enterprise'); ?></th>
                    <th><?php _e('Creado', 'woo-enterprise'); ?></th>
                    <th><?php _e('Acciones', 'woo-enterprise'); ?></th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($tenants as $tenant): ?>
                    <tr>
                        <td><strong><?php echo esc_html($tenant->id); ?></strong></td>
                        <td><?php echo esc_html($tenant->name); ?></td>
                        <td><code><?php echo esc_html($tenant->slug); ?></code></td>
                        <td>
                            <?php if ($tenant->domain): ?>
                                <a href="<?php echo esc_url($tenant->get_url()); ?>" target="_blank">
                                    <?php echo esc_html($tenant->domain); ?>
                                </a>
                            <?php else: ?>
                                <span class="description"><?php _e('Sin configurar', 'woo-enterprise'); ?></span>
                            <?php endif; ?>
                        </td>
                        <td><code><?php echo esc_html($tenant->db_name); ?></code></td>
                        <td>
                            <?php if ($tenant->is_active()): ?>
                                <span class="dashicons dashicons-yes-alt" style="color: green;"></span>
                                <?php _e('Activo', 'woo-enterprise'); ?>
                            <?php else: ?>
                                <span class="dashicons dashicons-warning" style="color: orange;"></span>
                                <?php echo esc_html(ucfirst($tenant->status)); ?>
                            <?php endif; ?>
                        </td>
                        <td><?php echo esc_html(date('Y-m-d H:i', strtotime($tenant->created_at))); ?></td>
                        <td>
                            <a href="<?php echo esc_url($tenant->get_url('wp-admin')); ?>" 
                               class="button button-small" target="_blank">
                                <?php _e('Admin', 'woo-enterprise'); ?>
                            </a>
                            <a href="<?php echo esc_url($tenant->get_url()); ?>" 
                               class="button button-small" target="_blank">
                                <?php _e('Ver Sitio', 'woo-enterprise'); ?>
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
PHP

ok "Admin: Lista de tenants"

#########################################################################
# admin/tenant-create.php
#########################################################################

cat > "$PLUGIN_DIR/admin/tenant-create.php" <<'PHP'
<?php
/**
 * Crear Tenant
 */

if (!defined('ABSPATH')) exit;

$errors = [];
$success = false;

// Procesar formulario
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['create_tenant_nonce'])) {
    
    if (!wp_verify_nonce($_POST['create_tenant_nonce'], 'create_tenant')) {
        $errors[] = __('Error de seguridad. Recarga la página.', 'woo-enterprise');
    } else {
        $slug = sanitize_title($_POST['tenant_slug']);
        $name = sanitize_text_field($_POST['tenant_name']);
        $domain = sanitize_text_field($_POST['tenant_domain']);
        
        // Validaciones
        if (empty($slug)) {
            $errors[] = __('El slug es obligatorio', 'woo-enterprise');
        } elseif (WooEnterprise_Tenant_Manager::slug_exists($slug)) {
            $errors[] = __('Ya existe un tenant con ese slug', 'woo-enterprise');
        }
        
        if (empty($name)) {
            $errors[] = __('El nombre es obligatorio', 'woo-enterprise');
        }
        
        // Si no hay errores, crear tenant
        if (empty($errors)) {
            // Generar nombre de DB único
            $db_name = 'tenant_' . time() . '_wp';
            
            $tenant_data = [
                'slug' => $slug,
                'name' => $name,
                'db_name' => $db_name,
                'domain' => $domain,
                'status' => 'active'
            ];
            
            $tenant = WooEnterprise_Tenant_Manager::create($tenant_data);
            
            if ($tenant) {
                $success = true;
                
                // Mostrar instrucciones
                ?>
                <div class="notice notice-success">
                    <h3><?php _e('¡Tenant creado exitosamente!', 'woo-enterprise'); ?></h3>
                    <p><strong><?php _e('Ahora ejecutá este comando en el servidor:', 'woo-enterprise'); ?></strong></p>
                    <pre style="background: #f0f0f0; padding: 15px; overflow-x: auto;">bash /var/www/woo-enterprise/scripts/provision-tenant.sh \
    <?php echo esc_html($slug); ?> \
    "<?php echo esc_html($name); ?>" \
    <?php echo esc_html($db_name); ?> \
    <?php echo esc_html($domain ?: $slug . '.tudominio.com'); ?></pre>
                    <p><?php _e('Este comando va a:', 'woo-enterprise'); ?></p>
                    <ul>
                        <li><?php _e('Crear la base de datos', 'woo-enterprise'); ?></li>
                        <li><?php _e('Instalar WordPress', 'woo-enterprise'); ?></li>
                        <li><?php _e('Instalar WooCommerce', 'woo-enterprise'); ?></li>
                        <li><?php _e('Configurar el tenant', 'woo-enterprise'); ?></li>
                    </ul>
                </div>
                <?php
            } else {
                $errors[] = __('Error al crear el tenant en la base de datos', 'woo-enterprise');
            }
        }
    }
}
?>

<div class="wrap">
    <h1><?php _e('Crear Nuevo Tenant', 'woo-enterprise'); ?></h1>
    
    <?php if (!empty($errors)): ?>
        <div class="notice notice-error">
            <ul>
                <?php foreach ($errors as $error): ?>
                    <li><?php echo esc_html($error); ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    <?php endif; ?>
    
    <?php if (!$success): ?>
        <form method="post" action="">
            <?php wp_nonce_field('create_tenant', 'create_tenant_nonce'); ?>
            
            <table class="form-table">
                <tr>
                    <th scope="row">
                        <label for="tenant_name">
                            <?php _e('Nombre del Tenant', 'woo-enterprise'); ?>
                            <span class="description">(requerido)</span>
                        </label>
                    </th>
                    <td>
                        <input type="text" 
                               id="tenant_name" 
                               name="tenant_name" 
                               class="regular-text" 
                               required
                               placeholder="Ej: Farmacia ABC">
                        <p class="description">
                            <?php _e('Nombre descriptivo del tenant', 'woo-enterprise'); ?>
                        </p>
                    </td>
                </tr>
                
                <tr>
                    <th scope="row">
                        <label for="tenant_slug">
                            <?php _e('Slug', 'woo-enterprise'); ?>
                            <span class="description">(requerido)</span>
                        </label>
                    </th>
                    <td>
                        <input type="text" 
                               id="tenant_slug" 
                               name="tenant_slug" 
                               class="regular-text" 
                               required
                               pattern="[a-z0-9-]+"
                               placeholder="farmacia-abc">
                        <p class="description">
                            <?php _e('Solo letras minúsculas, números y guiones. Ej: farmacia-abc', 'woo-enterprise'); ?>
                        </p>
                    </td>
                </tr>
                
                <tr>
                    <th scope="row">
                        <label for="tenant_domain">
                            <?php _e('Dominio', 'woo-enterprise'); ?>
                            <span class="description">(opcional)</span>
                        </label>
                    </th>
                    <td>
                        <input type="text" 
                               id="tenant_domain" 
                               name="tenant_domain" 
                               class="regular-text"
                               placeholder="farmacia-abc.com">
                        <p class="description">
                            <?php _e('Dominio custom del tenant. Si no se especifica, usará: slug.tudominio.com', 'woo-enterprise'); ?>
                        </p>
                    </td>
                </tr>
            </table>
            
            <p class="submit">
                <button type="submit" class="button button-primary">
                    <?php _e('Crear Tenant', 'woo-enterprise'); ?>
                </button>
                <a href="<?php echo admin_url('admin.php?page=woo-tenants'); ?>" class="button">
                    <?php _e('Cancelar', 'woo-enterprise'); ?>
                </a>
            </p>
        </form>
    <?php endif; ?>
</div>
PHP

ok "Admin: Crear tenant"

#########################################################################
# assets/css/admin.css
#########################################################################

cat > "$PLUGIN_DIR/assets/css/admin.css" <<'CSS'
/* WooCommerce Enterprise Admin Styles */

.woo-enterprise-header {
    background: #fff;
    border-bottom: 1px solid #ccd0d4;
    padding: 15px 20px;
    margin: -10px -20px 20px -10px;
}

.woo-enterprise-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin: 20px 0;
}

.woo-stat-box {
    background: #fff;
    border: 1px solid #ccd0d4;
    border-radius: 4px;
    padding: 20px;
    text-align: center;
}

.woo-stat-box h3 {
    margin: 0 0 10px 0;
    font-size: 2em;
    color: #2271b1;
}

.woo-stat-box p {
    margin: 0;
    color: #646970;
}

pre {
    background: #f0f0f1;
    border: 1px solid #c3c4c7;
    border-radius: 4px;
    padding: 15px;
    overflow-x: auto;
    font-size: 13px;
}

.notice pre {
    margin: 10px 0;
}
CSS

ok "CSS Admin"

#########################################################################
# assets/js/admin.js
#########################################################################

cat > "$PLUGIN_DIR/assets/js/admin.js" <<'JS'
/**
 * WooCommerce Enterprise Admin JS
 */

(function($) {
    'use strict';
    
    $(document).ready(function() {
        
        // Auto-generar slug desde nombre
        $('#tenant_name').on('input', function() {
            const name = $(this).val();
            const slug = name
                .toLowerCase()
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .replace(/[^a-z0-9]+/g, '-')
                .replace(/^-+|-+$/g, '');
            
            $('#tenant_slug').val(slug);
        });
        
        // Confirmar antes de eliminar
        $('.delete-tenant').on('click', function(e) {
            if (!confirm('¿Estás seguro de eliminar este tenant?')) {
                e.preventDefault();
            }
        });
        
    });
    
})(jQuery);
JS

ok "JavaScript Admin"

# Permisos
chown -R www-data:www-data "$PLUGIN_DIR"
chmod 755 "$PLUGIN_DIR"

ok "Plugin creado en: $PLUGIN_DIR"

echo ""
echo "═══════════════════════════════════════════════════"
echo "Ahora activá el plugin desde WordPress:"
echo "  wp plugin activate woo-enterprise-core --allow-root"
echo "═══════════════════════════════════════════════════"
CORE_SCRIPT

chmod +x create-core-plugin.sh
bash create-core-plugin.sh