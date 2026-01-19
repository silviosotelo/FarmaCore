cat > install-woo.sh <<'INSTALLER'
#!/bin/bash
#########################################################################
# Instalador Simple que FUNCIONA
# Sin boludeces que se cuelguen
#########################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}➜${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
   fail "Ejecutá como root: sudo bash install-woo.sh"
   exit 1
fi

clear
echo "═══════════════════════════════════════════════════"
echo "  WooCommerce Enterprise - Instalador Simple"
echo "═══════════════════════════════════════════════════"
echo ""

#########################################################################
# MENÚ SIMPLE
#########################################################################

mostrar_menu() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "  Estado del Sistema"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    # Verificar estado
    systemctl is-active --quiet nginx && echo -e "Nginx:     ${GREEN}✓ Corriendo${NC}" || echo -e "Nginx:     ${RED}✗ No instalado${NC}"
    systemctl is-active --quiet php8.2-fpm && echo -e "PHP:       ${GREEN}✓ Corriendo${NC}" || echo -e "PHP:       ${RED}✗ No instalado${NC}"
    systemctl is-active --quiet mysql && echo -e "MySQL:     ${GREEN}✓ Corriendo${NC}" || echo -e "MySQL:     ${RED}✗ No instalado${NC}"
    systemctl is-active --quiet redis-server && echo -e "Redis:     ${GREEN}✓ Corriendo${NC}" || echo -e "Redis:     ${RED}✗ No instalado${NC}"
    command -v wp &>/dev/null && echo -e "WP-CLI:    ${GREEN}✓ Instalado${NC}" || echo -e "WP-CLI:    ${RED}✗ No instalado${NC}"
    [ -f /var/www/woo-enterprise/wp-config.php ] && echo -e "WordPress: ${GREEN}✓ Instalado${NC}" || echo -e "WordPress: ${RED}✗ No instalado${NC}"
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "  Opciones"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "  1) Instalar Stack Completo (recomendado)"
    echo "  2) Instalar solo Nginx"
    echo "  3) Instalar solo PHP 8.2"
    echo "  4) Instalar solo MySQL"
    echo "  5) Instalar solo Redis"
    echo "  6) Instalar WP-CLI"
    echo "  7) Instalar WordPress"
    echo "  8) Configurar Nginx (dominio)"
    echo ""
    echo "  9) Ver logs del sistema"
    echo "  0) Salir"
    echo ""
    echo -n "Elegí una opción: "
}

#########################################################################
# INSTALACIONES SIMPLES
#########################################################################

instalar_nginx() {
    info "Instalando Nginx..."
    
    apt-get update -qq
    apt-get install -y nginx
    
    # Config simple
    cat > /etc/nginx/conf.d/woo.conf <<'EOF'
client_max_body_size 64M;
fastcgi_read_timeout 300;
EOF
    
    systemctl enable nginx
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        ok "Nginx instalado"
    else
        fail "Nginx falló"
    fi
}

instalar_php() {
    info "Instalando PHP 8.2..."
    
    add-apt-repository ppa:ondrej/php -y
    apt-get update -qq
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd \
        php8.2-mbstring php8.2-xml php8.2-zip php8.2-redis
    
    # Config rápida
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /etc/php/8.2/fpm/php.ini
    sed -i 's/post_max_size = .*/post_max_size = 64M/' /etc/php/8.2/fpm/php.ini
    sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini
    
    systemctl enable php8.2-fpm
    systemctl restart php8.2-fpm
    
    if systemctl is-active --quiet php8.2-fpm; then
        ok "PHP 8.2 instalado"
    else
        fail "PHP falló"
    fi
}

instalar_mysql() {
    info "Instalando MySQL..."
    
    # Password aleatorio
    MYSQL_PASS=$(openssl rand -base64 20)
    
    export DEBIAN_FRONTEND=noninteractive
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASS"
    
    apt-get install -y mysql-server
    
    # Guardar password
    cat > /root/.my.cnf <<EOF
[client]
user=root
password=$MYSQL_PASS
EOF
    chmod 600 /root/.my.cnf
    
    # Secure básico
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "FLUSH PRIVILEGES;"
    
    if systemctl is-active --quiet mysql; then
        ok "MySQL instalado (password en /root/.my.cnf)"
    else
        fail "MySQL falló"
    fi
}

instalar_redis() {
    info "Instalando Redis..."
    
    apt-get install -y redis-server
    
    systemctl enable redis-server
    systemctl restart redis-server
    
    if systemctl is-active --quiet redis-server; then
        ok "Redis instalado"
    else
        fail "Redis falló"
    fi
}

instalar_wpcli() {
    info "Instalando WP-CLI..."
    
    # Simple y directo
    curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
    chmod +x /usr/local/bin/wp
    
    # Directorios
    mkdir -p /root/.wp-cli/cache
    
    if command -v wp &>/dev/null; then
        ok "WP-CLI instalado"
    else
        fail "WP-CLI falló"
    fi
}

instalar_wordpress() {
    info "Instalando WordPress..."
    
    # Verificar dependencias
    if ! systemctl is-active --quiet mysql; then
        fail "MySQL no está corriendo. Instalalo primero (opción 4)"
        return 1
    fi
    
    if ! command -v wp &>/dev/null; then
        fail "WP-CLI no está instalado. Instalalo primero (opción 6)"
        return 1
    fi
    
    # Crear directorio
    mkdir -p /var/www/woo-enterprise
    cd /var/www/woo-enterprise
    
    # Descargar WordPress (sin sudo -u www-data que se cuelga)
    info "Descargando WordPress..."
    wp core download --locale=es_ES --allow-root --force
    
    # Crear DB
    info "Creando base de datos..."
    WP_DB_PASS=$(openssl rand -base64 20)
    
    mysql <<EOF
CREATE DATABASE IF NOT EXISTS master_wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'wp_master'@'localhost' IDENTIFIED BY '$WP_DB_PASS';
GRANT ALL PRIVILEGES ON master_wp.* TO 'wp_master'@'localhost';
GRANT ALL PRIVILEGES ON \`tenant_%\`.* TO 'wp_master'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Guardar credenciales
    cat > /root/.wp-db-creds <<EOF
WP_DB_USER=wp_master
WP_DB_PASS=$WP_DB_PASS
EOF
    
    # Crear wp-config
    info "Configurando WordPress..."
    wp config create \
        --dbname=master_wp \
        --dbuser=wp_master \
        --dbpass="$WP_DB_PASS" \
        --allow-root \
        --force
    
    # Crear tabla tenants
    mysql master_wp <<'SQL'
CREATE TABLE IF NOT EXISTS master_tenants (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  slug VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  db_name VARCHAR(64) NOT NULL,
  domain VARCHAR(255),
  status VARCHAR(20) DEFAULT 'active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
    
    # Permisos
    chown -R www-data:www-data /var/www/woo-enterprise
    
    ok "WordPress instalado"
    ok "Credenciales DB en: /root/.wp-db-creds"
}

configurar_nginx() {
    info "Configurando Nginx..."
    
    echo ""
    echo -n "Ingresá tu dominio (ej: ejemplo.com): "
    read DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        fail "Dominio vacío"
        return 1
    fi
    
    cat > /etc/nginx/sites-available/woo <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN *.$DOMAIN;
    root /var/www/woo-enterprise;
    index index.php;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/woo /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl reload nginx
    
    ok "Nginx configurado para: $DOMAIN"
    info "Configurá tu DNS: A record $DOMAIN → $(hostname -I | awk '{print $1}')"
}

instalar_todo() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "  Instalación Completa"
    echo "═══════════════════════════════════════════════════"
    echo ""
    warn "Esto instalará: Nginx, PHP, MySQL, Redis, WP-CLI, WordPress"
    echo ""
    echo -n "¿Continuar? (s/n): "
    read -n 1 REPLY
    echo ""
    
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        return
    fi
    
    echo ""
    info "Actualizando sistema..."
    apt-get update -qq
    
    echo ""
    instalar_nginx
    sleep 1
    
    echo ""
    instalar_php
    sleep 1
    
    echo ""
    instalar_mysql
    sleep 1
    
    echo ""
    instalar_redis
    sleep 1
    
    echo ""
    instalar_wpcli
    sleep 1
    
    echo ""
    instalar_wordpress
    sleep 1
    
    echo ""
    configurar_nginx
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    ok "Instalación completada"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "Accedé a: http://$DOMAIN/wp-admin/install.php"
    echo ""
}

ver_logs() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "  Logs del Sistema"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    echo "1) Ver últimas 50 líneas de Nginx error log"
    echo "2) Ver últimas 50 líneas de PHP error log"
    echo "3) Ver últimas 50 líneas de MySQL error log"
    echo "4) Ver status de todos los servicios"
    echo "0) Volver"
    echo ""
    echo -n "Elegí: "
    read OPT
    
    case $OPT in
        1) tail -50 /var/log/nginx/error.log 2>/dev/null || echo "No hay logs" ;;
        2) tail -50 /var/log/php8.2-fpm.log 2>/dev/null || echo "No hay logs" ;;
        3) tail -50 /var/log/mysql/error.log 2>/dev/null || echo "No hay logs" ;;
        4) 
            systemctl status nginx --no-pager
            systemctl status php8.2-fpm --no-pager
            systemctl status mysql --no-pager
            systemctl status redis-server --no-pager
            ;;
    esac
    
    echo ""
    read -p "Presioná Enter para continuar..."
}

#########################################################################
# LOOP PRINCIPAL
#########################################################################

while true; do
    mostrar_menu
    read OPT
    
    case $OPT in
        1) instalar_todo ;;
        2) instalar_nginx ;;
        3) instalar_php ;;
        4) instalar_mysql ;;
        5) instalar_redis ;;
        6) instalar_wpcli ;;
        7) instalar_wordpress ;;
        8) configurar_nginx ;;
        9) ver_logs ;;
        0) 
            clear
            echo "Chau!"
            exit 0
            ;;
        *)
            warn "Opción inválida"
            sleep 1
            ;;
    esac
    
    echo ""
    read -p "Presioná Enter para volver al menú..."
done
INSTALLER

chmod +x install-woo.sh