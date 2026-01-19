cat > installer.sh <<'INSTALLER'
#!/bin/bash
#########################################################################
# WooCommerce Enterprise Platform - Interactive Installer
# Version: 4.0 - The Good One
#########################################################################

set -e
trap 'handle_error $? $LINENO' ERR

#########################################################################
# CONFIGURATION
#########################################################################

VERSION="4.0.0"
LOG_FILE="/var/log/woo-enterprise-installer.log"
CONFIG_FILE="/root/.woo-enterprise-config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

#########################################################################
# HELPER FUNCTIONS
#########################################################################

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    log "SUCCESS: $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    log "ERROR: $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    log "WARNING: $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
    log "INFO: $1"
}

header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   WooCommerce Enterprise Platform - Installer v${VERSION}    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    error "Error en línea $line_number (código: $exit_code)"
    log "Stack trace en línea $line_number"
    
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                   ERROR DETECTADO                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Ver detalles en: $LOG_FILE"
    echo ""
    read -p "Presiona Enter para volver al menú principal..."
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este instalador debe ejecutarse como root"
        echo "Ejecuta: sudo bash installer.sh"
        exit 1
    fi
}

#########################################################################
# VERIFICATION FUNCTIONS
#########################################################################

check_nginx() {
    if systemctl is-active --quiet nginx 2>/dev/null && command -v nginx &>/dev/null; then
        local version=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')
        echo "installed:$version"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_php() {
    if systemctl is-active --quiet php8.2-fpm 2>/dev/null && command -v php &>/dev/null; then
        local version=$(php -v | head -n1 | grep -oP '\d+\.\d+\.\d+')
        echo "installed:$version"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_mysql() {
    if systemctl is-active --quiet mysql 2>/dev/null && command -v mysql &>/dev/null; then
        local version=$(mysql --version | grep -oP '\d+\.\d+\.\d+' | head -n1)
        echo "installed:$version"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_redis() {
    if systemctl is-active --quiet redis-server 2>/dev/null && command -v redis-cli &>/dev/null; then
        local version=$(redis-server --version | grep -oP '\d+\.\d+\.\d+')
        echo "installed:$version"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_wpcli() {
    if command -v wp &>/dev/null; then
        local version=$(wp --version --allow-root 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        echo "installed:$version"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_composer() {
    if command -v composer &>/dev/null; then
        local version=$(composer --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        echo "installed:$version"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_wordpress() {
    if [ -f "/var/www/woo-enterprise/wp-config.php" ]; then
        echo "installed"
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

check_firewall() {
    if command -v ufw &>/dev/null; then
        if ufw status | grep -q "Status: active"; then
            echo "active"
        else
            echo "inactive"
        fi
        return 0
    else
        echo "not_installed"
        return 1
    fi
}

#########################################################################
# INSTALLATION FUNCTIONS
#########################################################################

install_nginx() {
    header
    echo -e "${BOLD}Instalando Nginx...${NC}"
    echo ""
    
    log "Iniciando instalación de Nginx"
    
    # Actualizar repos
    info "Actualizando repositorios..."
    apt-get update -qq || { error "Fallo al actualizar repos"; return 1; }
    
    # Instalar Nginx
    info "Instalando paquete nginx..."
    apt-get install -y nginx || { error "Fallo al instalar nginx"; return 1; }
    
    # Configuración básica
    info "Configurando nginx..."
    
    # Crear archivo de performance (SIN duplicados)
    cat > /etc/nginx/conf.d/woo-performance.conf <<'EOF'
client_max_body_size 64M;
client_body_buffer_size 128k;
fastcgi_buffers 16 16k;
fastcgi_buffer_size 32k;
fastcgi_read_timeout 300;
keepalive_timeout 65;
server_tokens off;
EOF
    
    # Verificar configuración
    if nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        success "Configuración de Nginx válida"
    else
        error "Error en configuración de Nginx"
        return 1
    fi
    
    # Iniciar servicio
    systemctl enable nginx
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        success "Nginx instalado y corriendo"
        log "Nginx instalado exitosamente"
        return 0
    else
        error "Nginx no pudo iniciarse"
        return 1
    fi
}

install_php() {
    header
    echo -e "${BOLD}Instalando PHP 8.2...${NC}"
    echo ""
    
    log "Iniciando instalación de PHP 8.2"
    
    # Agregar repositorio
    info "Agregando repositorio PHP..."
    add-apt-repository ppa:ondrej/php -y || { error "Fallo al agregar repo PHP"; return 1; }
    apt-get update -qq
    
    # Instalar PHP y extensiones
    info "Instalando PHP 8.2 y extensiones (esto puede tardar)..."
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-xmlrpc \
        php8.2-soap \
        php8.2-intl \
        php8.2-zip \
        php8.2-bcmath \
        php8.2-redis \
        php8.2-imagick || { error "Fallo al instalar PHP"; return 1; }
    
    # Configurar php.ini
    info "Optimizando PHP..."
    local php_ini="/etc/php/8.2/fpm/php.ini"
    
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' "$php_ini"
    sed -i 's/post_max_size = .*/post_max_size = 64M/' "$php_ini"
    sed -i 's/memory_limit = .*/memory_limit = 256M/' "$php_ini"
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
    sed -i 's/max_input_time = .*/max_input_time = 300/' "$php_ini"
    sed -i 's/;max_input_vars = .*/max_input_vars = 5000/' "$php_ini"
    
    # Configurar PHP-FPM
    local fpm_pool="/etc/php/8.2/fpm/pool.d/www.conf"
    sed -i 's/pm = dynamic/pm = ondemand/' "$fpm_pool"
    sed -i 's/pm.max_children = .*/pm.max_children = 50/' "$fpm_pool"
    sed -i 's/;pm.process_idle_timeout = .*/pm.process_idle_timeout = 10s/' "$fpm_pool"
    
    # Reiniciar PHP-FPM
    systemctl enable php8.2-fpm
    systemctl restart php8.2-fpm
    
    if systemctl is-active --quiet php8.2-fpm; then
        success "PHP 8.2 instalado y corriendo"
        log "PHP 8.2 instalado exitosamente"
        return 0
    else
        error "PHP-FPM no pudo iniciarse"
        return 1
    fi
}

install_mysql() {
    header
    echo -e "${BOLD}Instalando MySQL 8.0...${NC}"
    echo ""
    
    log "Iniciando instalación de MySQL 8.0"
    
    # Generar password seguro
    local mysql_root_pass=$(openssl rand -base64 32)
    
    # Pre-configurar password
    export DEBIAN_FRONTEND=noninteractive
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_pass"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_pass"
    
    # Instalar MySQL
    info "Instalando MySQL Server..."
    apt-get install -y mysql-server || { error "Fallo al instalar MySQL"; return 1; }
    
    # Esperar a que MySQL inicie
    info "Esperando a que MySQL inicie..."
    sleep 5
    
    # Guardar credenciales
    cat > /root/.my.cnf <<EOF
[client]
user=root
password=$mysql_root_pass
EOF
    chmod 600 /root/.my.cnf
    
    # Secure installation
    info "Asegurando instalación MySQL..."
    mysql -u root -p"$mysql_root_pass" <<'SQL'
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL
    
    # Configuración de performance
    cat > /etc/mysql/mysql.conf.d/woo-enterprise.cnf <<'EOF'
[mysqld]
max_connections = 200
max_allowed_packet = 64M
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF
    
    systemctl restart mysql
    
    if systemctl is-active --quiet mysql; then
        success "MySQL instalado y corriendo"
        success "Credenciales guardadas en /root/.my.cnf"
        log "MySQL instalado exitosamente"
        return 0
    else
        error "MySQL no pudo iniciarse"
        return 1
    fi
}

install_redis() {
    header
    echo -e "${BOLD}Instalando Redis...${NC}"
    echo ""
    
    log "Iniciando instalación de Redis"
    
    info "Instalando Redis Server..."
    apt-get install -y redis-server || { error "Fallo al instalar Redis"; return 1; }
    
    # Configurar Redis
    info "Configurando Redis..."
    sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
    sed -i 's/# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
    systemctl enable redis-server
    systemctl restart redis-server
    
    if systemctl is-active --quiet redis-server; then
        success "Redis instalado y corriendo"
        log "Redis instalado exitosamente"
        return 0
    else
        error "Redis no pudo iniciarse"
        return 1
    fi
}

install_wpcli() {
    header
    echo -e "${BOLD}Instalando WP-CLI...${NC}"
    echo ""
    
    log "Iniciando instalación de WP-CLI"
    
    # Crear directorios
    info "Creando directorios..."
    mkdir -p /root/.wp-cli/cache
    mkdir -p /var/www/.wp-cli/cache
    chmod -R 755 /root/.wp-cli /var/www/.wp-cli
    
    # Descargar WP-CLI
    info "Descargando WP-CLI..."
    curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /tmp/wp-cli.phar || {
        error "Fallo al descargar WP-CLI"
        return 1
    }
    
    chmod +x /tmp/wp-cli.phar
    mv /tmp/wp-cli.phar /usr/local/bin/wp
    
    # Crear config
    cat > /root/.wp-cli/config.yml <<'EOF'
path: /var/www/woo-enterprise
apache_modules:
  - mod_rewrite
EOF
    
    # Verificar
    if wp --version --allow-root &>/dev/null; then
        success "WP-CLI instalado correctamente"
        log "WP-CLI instalado exitosamente"
        return 0
    else
        error "WP-CLI no funciona correctamente"
        return 1
    fi
}

install_composer() {
    header
    echo -e "${BOLD}Instalando Composer...${NC}"
    echo ""
    
    log "Iniciando instalación de Composer"
    
    info "Descargando Composer..."
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" || {
        error "Fallo al descargar Composer"
        return 1
    }
    
    info "Instalando Composer..."
    php /tmp/composer-setup.php --quiet --install-dir=/tmp || {
        error "Fallo al instalar Composer"
        return 1
    }
    
    mv /tmp/composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    rm -f /tmp/composer-setup.php
    
    if composer --version &>/dev/null; then
        success "Composer instalado correctamente"
        log "Composer instalado exitosamente"
        return 0
    else
        error "Composer no funciona"
        return 1
    fi
}

install_wordpress() {
    header
    echo -e "${BOLD}Instalando WordPress...${NC}"
    echo ""
    
    log "Iniciando instalación de WordPress"
    
    # Verificar dependencias
    if ! check_mysql | grep -q "installed"; then
        error "MySQL no está instalado. Instálalo primero."
        return 1
    fi
    
    if ! check_wpcli | grep -q "installed"; then
        error "WP-CLI no está instalado. Instálalo primero."
        return 1
    fi
    
    # Crear directorios
    info "Creando directorios..."
    mkdir -p /var/www/woo-enterprise
    cd /var/www/woo-enterprise
    
    # Descargar WordPress
    info "Descargando WordPress en español..."
    sudo -u www-data wp core download --locale=es_ES --allow-root || {
        error "Fallo al descargar WordPress"
        return 1
    }
    
    # Crear base de datos master
    info "Creando base de datos master_wp..."
    
    # Generar credenciales DB
    local wp_db_pass=$(openssl rand -base64 32)
    
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS master_wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'wp_master'@'localhost' IDENTIFIED BY '$wp_db_pass';
GRANT ALL PRIVILEGES ON \`master_wp\`.* TO 'wp_master'@'localhost';
GRANT ALL PRIVILEGES ON \`tenant_%\`.* TO 'wp_master'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Guardar credenciales
    cat > /root/.wp-db-credentials <<EOF
WP_DB_USER=wp_master
WP_DB_PASS=$wp_db_pass
EOF
    chmod 600 /root/.wp-db-credentials
    
    # Crear wp-config.php
    info "Creando wp-config.php..."
    sudo -u www-data wp config create \
        --dbname=master_wp \
        --dbuser=wp_master \
        --dbpass="$wp_db_pass" \
        --dbhost=localhost \
        --dbcharset=utf8mb4 \
        --allow-root \
        --extra-php <<'PHP'
/* Multi-tenant constants */
define('WOO_ENTERPRISE_MASTER_DB', 'master_wp');
define('WOO_ENTERPRISE_VERSION', '1.0.0');

/* Redis Object Cache */
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);

/* Security */
define('DISALLOW_FILE_EDIT', true);

/* Performance */
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

/* Debug */
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
PHP
    
    # Crear tablas master
    info "Creando tablas de tenants..."
    mysql master_wp <<'SQL'
CREATE TABLE IF NOT EXISTS `master_tenants` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` VARCHAR(36) UNIQUE NOT NULL,
  `slug` VARCHAR(50) UNIQUE NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `vertical` ENUM('pharmacy','electronics','retail','gastronomy','wholesale') NOT NULL,
  `db_name` VARCHAR(64) NOT NULL,
  `primary_domain` VARCHAR(255),
  `status` ENUM('active','suspended','trial') DEFAULT 'trial',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SQL
    
    # Permisos
    chown -R www-data:www-data /var/www/woo-enterprise
    
    success "WordPress instalado correctamente"
    success "Base de datos: master_wp"
    success "Credenciales en: /root/.wp-db-credentials"
    log "WordPress instalado exitosamente"
    
    return 0
}

configure_nginx() {
    header
    echo -e "${BOLD}Configurando Nginx para WordPress...${NC}"
    echo ""
    
    # Solicitar dominio
    echo "Ingresa tu dominio (ej: ejemplo.com):"
    read -r domain
    
    if [ -z "$domain" ]; then
        error "Dominio no puede estar vacío"
        return 1
    fi
    
    info "Configurando vhost para: $domain"
    
    cat > /etc/nginx/sites-available/woo-enterprise <<EOF
server {
    listen 80;
    server_name $domain *.$domain;
    
    root /var/www/woo-enterprise;
    index index.php index.html;
    
    access_log /var/log/nginx/woo-access.log;
    error_log /var/log/nginx/woo-error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\. {
        deny all;
    }
}
EOF
    
    # Habilitar sitio
    ln -sf /etc/nginx/sites-available/woo-enterprise /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test
    if nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        systemctl reload nginx
        success "Nginx configurado para: $domain"
        
        # Guardar dominio
        echo "DOMAIN=$domain" >> "$CONFIG_FILE"
        
        return 0
    else
        error "Error en configuración Nginx"
        return 1
    fi
}

#########################################################################
# MENU SYSTEM
#########################################################################

show_status() {
    header
    echo -e "${BOLD}Estado de Componentes:${NC}"
    echo ""
    
    local nginx_status=$(check_nginx)
    local php_status=$(check_php)
    local mysql_status=$(check_mysql)
    local redis_status=$(check_redis)
    local wpcli_status=$(check_wpcli)
    local composer_status=$(check_composer)
    local wordpress_status=$(check_wordpress)
    
    printf "%-20s %s\n" "Nginx:" "$(format_status "$nginx_status")"
    printf "%-20s %s\n" "PHP 8.2:" "$(format_status "$php_status")"
    printf "%-20s %s\n" "MySQL:" "$(format_status "$mysql_status")"
    printf "%-20s %s\n" "Redis:" "$(format_status "$redis_status")"
    printf "%-20s %s\n" "WP-CLI:" "$(format_status "$wpcli_status")"
    printf "%-20s %s\n" "Composer:" "$(format_status "$composer_status")"
    printf "%-20s %s\n" "WordPress:" "$(format_status "$wordpress_status")"
    
    echo ""
}

format_status() {
    if echo "$1" | grep -q "installed"; then
        local version=$(echo "$1" | cut -d: -f2)
        echo -e "${GREEN}✓ Instalado${NC} (v$version)"
    elif echo "$1" | grep -q "active"; then
        echo -e "${GREEN}✓ Activo${NC}"
    elif echo "$1" | grep -q "inactive"; then
        echo -e "${YELLOW}○ Inactivo${NC}"
    else
        echo -e "${RED}✗ No instalado${NC}"
    fi
}

install_component() {
    local component=$1
    
    case $component in
        nginx)
            install_nginx
            ;;
        php)
            install_php
            ;;
        mysql)
            install_mysql
            ;;
        redis)
            install_redis
            ;;
        wpcli)
            install_wpcli
            ;;
        composer)
            install_composer
            ;;
        wordpress)
            install_wordpress
            ;;
        nginx_config)
            configure_nginx
            ;;
        *)
            error "Componente desconocido: $component"
            return 1
            ;;
    esac
    
    local result=$?
    echo ""
    if [ $result -eq 0 ]; then
        success "Instalación completada"
    else
        error "Instalación falló"
    fi
    echo ""
    read -p "Presiona Enter para continuar..."
    return $result
}

main_menu() {
    while true; do
        header
        show_status
        
        echo -e "${BOLD}Opciones:${NC}"
        echo ""
        echo "  ${CYAN}INSTALACIÓN COMPONENTES:${NC}"
        echo "    1) Instalar Nginx"
        echo "    2) Instalar PHP 8.2"
        echo "    3) Instalar MySQL 8.0"
        echo "    4) Instalar Redis"
        echo "    5) Instalar WP-CLI"
        echo "    6) Instalar Composer"
        echo "    7) Instalar WordPress"
        echo ""
        echo "  ${CYAN}CONFIGURACIÓN:${NC}"
        echo "    8) Configurar Nginx (dominio)"
        echo ""
        echo "  ${CYAN}INSTALACIÓN RÁPIDA:${NC}"
        echo "    9) Instalar TODO (stack completo)"
        echo ""
        echo "    0) Salir"
        echo ""
        echo -n "Selecciona una opción: "
        
        read -r option
        
        case $option in
            1) install_component nginx ;;
            2) install_component php ;;
            3) install_component mysql ;;
            4) install_component redis ;;
            5) install_component wpcli ;;
            6) install_component composer ;;
            7) install_component wordpress ;;
            8) install_component nginx_config ;;
            9) install_all ;;
            0) 
                clear
                echo "¡Hasta luego!"
                exit 0
                ;;
            *)
                warning "Opción inválida"
                sleep 1
                ;;
        esac
    done
}

install_all() {
    header
    echo -e "${BOLD}Instalación Completa del Stack${NC}"
    echo ""
    warning "Esto instalará TODOS los componentes necesarios"
    echo ""
    read -p "¿Continuar? (s/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        return 0
    fi
    
    local components=(nginx php mysql redis wpcli composer wordpress nginx_config)
    local total=${#components[@]}
    local current=0
    
    for component in "${components[@]}"; do
        current=$((current + 1))
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Paso $current de $total: Instalando $component..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        install_component $component
        
        if [ $? -ne 0 ]; then
            error "Falló la instalación de $component"
            read -p "¿Continuar con los demás? (s/n): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
                return 1
            fi
        fi
    done
    
    echo ""
    success "Instalación completa finalizada"
    echo ""
    read -p "Presiona Enter para volver al menú..."
}

#########################################################################
# MAIN
#########################################################################

check_root
touch "$LOG_FILE"
log "========== Instalador iniciado v$VERSION =========="

main_menu
INSTALLER

chmod +x installer.sh