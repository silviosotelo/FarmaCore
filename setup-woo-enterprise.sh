#!/bin/bash
#########################################################################
# WooCommerce Enterprise Platform - VPS Setup Script
# Ubuntu 22.04 LTS
# Stack: Nginx + PHP 8.2 + MySQL 8.0 + Redis + Certbot
#########################################################################

set -e  # Exit on error

# Colors para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables globales
MYSQL_ROOT_PASSWORD=""
WP_DB_USER="wp_master"
WP_DB_PASS=""
DOMAIN=""
ADMIN_EMAIL=""

#########################################################################
# Funciones auxiliares
#########################################################################

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

#########################################################################
# 1. ACTUALIZAR SISTEMA
#########################################################################

update_system() {
    print_warning "Actualizando sistema..."
    apt update -qq
    apt upgrade -y -qq
    apt install -y software-properties-common curl wget git unzip
    print_success "Sistema actualizado"
}

#########################################################################
# 2. INSTALAR NGINX
#########################################################################

install_nginx() {
    print_warning "Instalando Nginx..."
    apt install -y nginx
    
    # Optimización básica
    cat > /etc/nginx/conf.d/performance.conf <<'EOF'
client_max_body_size 64M;
client_body_buffer_size 128k;
fastcgi_buffers 16 16k;
fastcgi_buffer_size 32k;
fastcgi_read_timeout 300;
keepalive_timeout 65;
types_hash_max_size 2048;
server_tokens off;
EOF

    # Habilitar Gzip
    sed -i 's/# gzip_vary on;/gzip_vary on;/g' /etc/nginx/nginx.conf
    sed -i 's/# gzip_types/gzip_types/g' /etc/nginx/nginx.conf
    
    systemctl enable nginx
    systemctl restart nginx
    print_success "Nginx instalado y configurado"
}

#########################################################################
# 3. INSTALAR PHP 8.2
#########################################################################

install_php() {
    print_warning "Instalando PHP 8.2..."
    
    # Agregar repositorio Ondřej Surý
    add-apt-repository ppa:ondrej/php -y
    apt update -qq
    
    # Instalar PHP y extensiones necesarias para WordPress/WooCommerce
    apt install -y \
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
        php8.2-imagick
    
    # Optimización php.ini
    PHP_INI="/etc/php/8.2/fpm/php.ini"
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' $PHP_INI
    sed -i 's/post_max_size = .*/post_max_size = 64M/' $PHP_INI
    sed -i 's/memory_limit = .*/memory_limit = 256M/' $PHP_INI
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHP_INI
    sed -i 's/max_input_time = .*/max_input_time = 300/' $PHP_INI
    sed -i 's/;max_input_vars = .*/max_input_vars = 5000/' $PHP_INI
    
    # Optimización PHP-FPM pool
    FPM_POOL="/etc/php/8.2/fpm/pool.d/www.conf"
    sed -i 's/pm = dynamic/pm = ondemand/' $FPM_POOL
    sed -i 's/pm.max_children = .*/pm.max_children = 50/' $FPM_POOL
    sed -i 's/;pm.process_idle_timeout = .*/pm.process_idle_timeout = 10s/' $FPM_POOL
    
    systemctl enable php8.2-fpm
    systemctl restart php8.2-fpm
    print_success "PHP 8.2 instalado"
}

#########################################################################
# 4. INSTALAR MYSQL 8.0
#########################################################################

install_mysql() {
    print_warning "Instalando MySQL 8.0..."
    
    # Generar password aleatorio si no fue provisto
    if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
        MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    fi
    
    # Pre-configurar password para instalación no interactiva
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
    
    apt install -y mysql-server
    
    # Configuración segura básica
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    # Optimización MySQL para multi-tenant
    cat > /etc/mysql/mysql.conf.d/woo-enterprise.cnf <<'EOF'
[mysqld]
# Performance
max_connections = 200
max_allowed_packet = 64M
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Charset
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Query cache (disabled en MySQL 8)
# Usar Redis en su lugar

# Logs (temporal, deshabilitar en producción)
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
EOF

    systemctl restart mysql
    
    # Guardar credenciales
    cat > /root/.my.cnf <<EOF
[client]
user=root
password=$MYSQL_ROOT_PASSWORD
EOF
    chmod 600 /root/.my.cnf
    
    print_success "MySQL 8.0 instalado"
    print_warning "MySQL root password guardado en /root/.my.cnf"
}

#########################################################################
# 5. INSTALAR REDIS
#########################################################################

install_redis() {
    print_warning "Instalando Redis..."
    apt install -y redis-server
    
    # Configuración
    sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
    sed -i 's/# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
    systemctl enable redis-server
    systemctl restart redis-server
    print_success "Redis instalado"
}

#########################################################################
# 6. INSTALAR WP-CLI
#########################################################################

install_wpcli() {
    print_warning "Instalando WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    
    # Verificar
    wp --info
    print_success "WP-CLI instalado"
}

#########################################################################
# 7. INSTALAR COMPOSER
#########################################################################

install_composer() {
    print_warning "Instalando Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    mv composer.phar /usr/local/bin/composer
    rm composer-setup.php
    print_success "Composer instalado"
}

#########################################################################
# 8. CONFIGURAR FIREWALL (UFW)
#########################################################################

setup_firewall() {
    print_warning "Configurando firewall..."
    apt install -y ufw
    
    # Reglas básicas
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 'Nginx Full'
    
    # Habilitar sin prompt
    echo "y" | ufw enable
    print_success "Firewall configurado"
}

#########################################################################
# 9. CREAR ESTRUCTURA DE DIRECTORIOS
#########################################################################

setup_directories() {
    print_warning "Creando estructura de directorios..."
    
    # Directorio principal
    mkdir -p /var/www/woo-enterprise
    
    # Subdirectorios
    mkdir -p /var/www/woo-enterprise/logs
    mkdir -p /var/www/woo-enterprise/scripts
    mkdir -p /var/www/woo-enterprise/backups
    mkdir -p /var/www/woo-enterprise/tmp
    
    # Permisos
    chown -R www-data:www-data /var/www/woo-enterprise
    chmod -R 755 /var/www/woo-enterprise
    
    print_success "Estructura creada en /var/www/woo-enterprise"
}

#########################################################################
# 10. CREAR DATABASE MASTER
#########################################################################

create_master_database() {
    print_warning "Creando database master..."
    
    # Generar password para usuario WP
    if [[ -z "$WP_DB_PASS" ]]; then
        WP_DB_PASS=$(openssl rand -base64 32)
    fi
    
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS master_wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS';
GRANT ALL PRIVILEGES ON \`master_wp\`.* TO '$WP_DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`tenant_%\`.* TO '$WP_DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Guardar credenciales
    cat > /root/.wp-db-credentials <<EOF
WP_DB_USER=$WP_DB_USER
WP_DB_PASS=$WP_DB_PASS
EOF
    chmod 600 /root/.wp-db-credentials
    
    print_success "Database master_wp creada"
    print_warning "Credenciales guardadas en /root/.wp-db-credentials"
}

#########################################################################
# 11. INSTALAR WORDPRESS CORE
#########################################################################

install_wordpress() {
    print_warning "Instalando WordPress..."
    
    cd /var/www/woo-enterprise
    
    # Descargar WordPress
    sudo -u www-data wp core download --locale=es_ES
    
    # Crear wp-config.php
    sudo -u www-data wp config create \
        --dbname=master_wp \
        --dbuser=$WP_DB_USER \
        --dbpass=$WP_DB_PASS \
        --dbhost=localhost \
        --dbcharset=utf8mb4 \
        --extra-php <<PHP
/* Multi-tenant constants */
define('WOO_ENTERPRISE_MASTER_DB', 'master_wp');
define('WOO_ENTERPRISE_VERSION', '1.0.0');

/* Redis Object Cache */
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);

/* Disable file editing */
define('DISALLOW_FILE_EDIT', true);

/* Performance */
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
PHP

    print_success "WordPress descargado y configurado"
}

#########################################################################
# 12. CONFIGURAR NGINX VHOST
#########################################################################

setup_nginx_vhost() {
    print_warning "Configurando Nginx vhost..."
    
    if [[ -z "$DOMAIN" ]]; then
        DOMAIN="woo-enterprise.local"
        print_warning "No se especificó dominio, usando: $DOMAIN"
    fi
    
    cat > /etc/nginx/sites-available/woo-enterprise <<EOF
server {
    listen 80;
    server_name $DOMAIN *.${DOMAIN};
    
    root /var/www/woo-enterprise;
    index index.php index.html;
    
    # Logs
    access_log /var/www/woo-enterprise/logs/access.log;
    error_log /var/www/woo-enterprise/logs/error.log;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # WordPress permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }
    
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }
    
    # Cache static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires max;
        log_not_found off;
    }
}
EOF

    # Habilitar sitio
    ln -sf /etc/nginx/sites-available/woo-enterprise /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test y reload
    nginx -t
    systemctl reload nginx
    
    print_success "Nginx vhost configurado para $DOMAIN"
}

#########################################################################
# 13. INSTALAR CERTBOT (SSL)
#########################################################################

install_certbot() {
    print_warning "Instalando Certbot..."
    apt install -y certbot python3-certbot-nginx
    
    if [[ ! -z "$ADMIN_EMAIL" ]] && [[ ! -z "$DOMAIN" ]]; then
        print_warning "Para obtener certificado SSL ejecuta:"
        echo "certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $ADMIN_EMAIL --agree-tos --no-eff-email"
    fi
    
    print_success "Certbot instalado"
}

#########################################################################
# 14. SETUP AUTOMATICO DE BACKUPS
#########################################################################

setup_backups() {
    print_warning "Configurando backups automáticos..."
    
    cat > /var/www/woo-enterprise/scripts/backup-tenant.sh <<'BACKUP_SCRIPT'
#!/bin/bash
# Backup individual de tenant

TENANT_ID=$1
BACKUP_DIR="/var/www/woo-enterprise/backups"
DATE=$(date +%Y%m%d_%H%M%S)

if [[ -z "$TENANT_ID" ]]; then
    echo "Uso: $0 <tenant_id>"
    exit 1
fi

# Obtener nombre de DB del tenant
DB_NAME=$(mysql master_wp -sse "SELECT db_name FROM master_tenants WHERE id=$TENANT_ID")

if [[ -z "$DB_NAME" ]]; then
    echo "Error: Tenant $TENANT_ID no encontrado"
    exit 1
fi

# Crear backup
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"
mysqldump --single-transaction --routines --triggers $DB_NAME | gzip > $BACKUP_FILE

# Mantener solo últimos 7 días
find $BACKUP_DIR -name "${DB_NAME}_*.sql.gz" -mtime +7 -delete

echo "Backup completado: $BACKUP_FILE"
BACKUP_SCRIPT

    chmod +x /var/www/woo-enterprise/scripts/backup-tenant.sh
    
    # Cron job para backup diario (3AM)
    (crontab -l 2>/dev/null; echo "0 3 * * * /var/www/woo-enterprise/scripts/backup-all-tenants.sh") | crontab -
    
    print_success "Sistema de backups configurado"
}

#########################################################################
# 15. CREAR SCRIPT DE PROVISION DE TENANT
#########################################################################

create_provision_script() {
    cat > /var/www/woo-enterprise/scripts/provision-tenant.sh <<'PROVISION_SCRIPT'
#!/bin/bash
# Provision de nuevo tenant

set -e

TENANT_SLUG=$1
TENANT_NAME=$2
VERTICAL=$3
DOMAIN=$4
ADMIN_EMAIL=${5:-"admin@${DOMAIN}"}

if [[ -z "$TENANT_SLUG" ]] || [[ -z "$TENANT_NAME" ]] || [[ -z "$VERTICAL" ]] || [[ -z "$DOMAIN" ]]; then
    echo "Uso: $0 <slug> <nombre> <vertical> <domain> [admin_email]"
    echo "Ejemplo: $0 farmacia-abc 'Farmacia ABC' pharmacy farmacia-abc.com admin@farmacia-abc.com"
    exit 1
fi

echo "🚀 Provisionando tenant: $TENANT_NAME"

# 1. Generar nombre único de DB
TIMESTAMP=$(date +%s)
DB_NAME="tenant_${TIMESTAMP}_wp"

echo "📦 Creando database: $DB_NAME"

# 2. Crear database
mysql -u root <<EOF
CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

# 3. Instalar WordPress en nueva DB
echo "⚙️ Instalando WordPress..."
cd /var/www/woo-enterprise

wp core install \
    --dbname=$DB_NAME \
    --url="https://$DOMAIN" \
    --title="$TENANT_NAME" \
    --admin_user="admin" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root

# 4. Instalar WooCommerce
echo "🛒 Instalando WooCommerce..."
wp plugin install woocommerce --activate --dbname=$DB_NAME --allow-root

# 5. Instalar plugin vertical si existe
if [[ -d "/var/www/woo-enterprise/wp-content/plugins/woo-vertical-$VERTICAL" ]]; then
    wp plugin activate woo-vertical-$VERTICAL --dbname=$DB_NAME --allow-root
fi

# 6. Registrar tenant en master_wp
echo "📝 Registrando tenant..."
UUID=$(uuidgen)
ADMIN_PASS=$(openssl rand -base64 16)

mysql master_wp <<EOF
INSERT INTO master_tenants (
    uuid, slug, name, vertical, db_name, db_host, db_prefix,
    primary_domain, subdomain, status, plan, created_at
) VALUES (
    '$UUID',
    '$TENANT_SLUG',
    '$TENANT_NAME',
    '$VERTICAL',
    '$DB_NAME',
    'localhost',
    'wp_',
    '$DOMAIN',
    '$DOMAIN',
    'active',
    'basic',
    NOW()
);
EOF

TENANT_ID=$(mysql master_wp -sse "SELECT id FROM master_tenants WHERE uuid='$UUID'")

echo ""
echo "✅ Tenant provisionado exitosamente!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tenant ID: $TENANT_ID"
echo "Database: $DB_NAME"
echo "URL: https://$DOMAIN"
echo "Admin: admin"
echo "Password: $ADMIN_PASS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️ IMPORTANTE: Guarda estas credenciales de forma segura"
echo ""
echo "Siguiente paso: Configurar DNS para apuntar $DOMAIN a este servidor"
PROVISION_SCRIPT

    chmod +x /var/www/woo-enterprise/scripts/provision-tenant.sh
    print_success "Script de provisión creado"
}

#########################################################################
# 16. RESUMEN FINAL
#########################################################################

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✅ INSTALACIÓN COMPLETADA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Stack instalado:"
    echo "   • Nginx $(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')"
    echo "   • PHP $(php -v | head -n1 | grep -oP '\d+\.\d+\.\d+')"
    echo "   • MySQL $(mysql --version | grep -oP '\d+\.\d+\.\d+')"
    echo "   • Redis $(redis-server --version | grep -oP '\d+\.\d+\.\d+')"
    echo "   • WP-CLI $(wp --version | grep -oP '\d+\.\d+\.\d+')"
    echo ""
    echo "📁 Directorios:"
    echo "   • WordPress: /var/www/woo-enterprise"
    echo "   • Logs: /var/www/woo-enterprise/logs"
    echo "   • Scripts: /var/www/woo-enterprise/scripts"
    echo "   • Backups: /var/www/woo-enterprise/backups"
    echo ""
    echo "🔑 Credenciales:"
    echo "   • MySQL root: /root/.my.cnf"
    echo "   • WordPress DB: /root/.wp-db-credentials"
    echo ""
    echo "🚀 Próximos pasos:"
    echo ""
    echo "1. Configurar DNS para apuntar tu dominio a esta IP:"
    ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print "   → " $2}' | cut -d/ -f1
    echo ""
    echo "2. Obtener certificado SSL:"
    echo "   certbot --nginx -d tu-dominio.com -d www.tu-dominio.com"
    echo ""
    echo "3. Finalizar instalación de WordPress:"
    echo "   http://$DOMAIN/wp-admin/install.php"
    echo ""
    echo "4. Instalar plugin woo-enterprise-core"
    echo ""
    echo "5. Crear primer tenant:"
    echo "   /var/www/woo-enterprise/scripts/provision-tenant.sh \\"
    echo "       farmacia-abc 'Farmacia ABC' pharmacy farmacia-abc.com"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

#########################################################################
# EJECUTAR INSTALACIÓN
#########################################################################

main() {
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  WooCommerce Enterprise Platform - Setup"
    echo "  Ubuntu 22.04 LTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Solicitar datos básicos
    read -p "Dominio principal (ej: woo-enterprise.com): " DOMAIN
    read -p "Email del administrador: " ADMIN_EMAIL
    read -sp "Password para MySQL root (Enter para auto-generar): " MYSQL_ROOT_PASSWORD
    echo ""
    read -sp "Password para usuario WP DB (Enter para auto-generar): " WP_DB_PASS
    echo ""
    
    # Confirmación
    echo ""
    echo "Configuración:"
    echo "  Dominio: $DOMAIN"
    echo "  Email: $ADMIN_EMAIL"
    read -p "¿Continuar? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Instalación cancelada"
        exit 0
    fi
    
    # Verificar root
    check_root
    
    # Ejecutar instalación
    update_system
    install_nginx
    install_php
    install_mysql
    install_redis
    install_wpcli
    install_composer
    setup_firewall
    setup_directories
    create_master_database
    install_wordpress
    setup_nginx_vhost
    install_certbot
    setup_backups
    create_provision_script
    
    # Resumen
    print_summary
}

# Ejecutar
main "$@"