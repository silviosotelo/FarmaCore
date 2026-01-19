cat > /var/www/woo-enterprise/scripts/provision-tenant.sh <<'PROVISION'
#!/bin/bash
#########################################################################
# Provisionar Tenant
# Uso: bash provision-tenant.sh <slug> <name> <db_name> <domain>
#########################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}➜${NC} $1"; }

# Parámetros
SLUG=$1
NAME=$2
DB_NAME=$3
DOMAIN=$4

if [ -z "$SLUG" ] || [ -z "$NAME" ] || [ -z "$DB_NAME" ]; then
    fail "Uso: bash provision-tenant.sh <slug> <name> <db_name> <domain>"
fi

echo "═══════════════════════════════════════════════════"
echo "  Provisionando Tenant: $NAME"
echo "═══════════════════════════════════════════════════"
echo ""

# Cargar credenciales DB
source /root/.wp-db-creds

#########################################################################
# 1. CREAR BASE DE DATOS
#########################################################################

info "Creando base de datos: $DB_NAME"

mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$WP_DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

ok "Base de datos creada"

#########################################################################
# 2. INSTALAR WORDPRESS
#########################################################################

info "Instalando WordPress para tenant..."

cd /var/www/woo-enterprise

# Generar password admin
ADMIN_PASS=$(openssl rand -base64 16)

# Crear wp-config temporal para este tenant
TMP_CONFIG=$(mktemp)
cat > "$TMP_CONFIG" <<WPCONFIG
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$WP_DB_USER');
define('DB_PASSWORD', '$WP_DB_PASS');
define('DB_HOST', 'localhost');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if (!defined('ABSPATH')) define('ABSPATH', __DIR__ . '/');
require_once ABSPATH . 'wp-settings.php';
WPCONFIG

# Backup del wp-config original
mv wp-config.php wp-config.php.master

# Usar config temporal
mv "$TMP_CONFIG" wp-config.php

# Instalar WordPress
URL="https://${DOMAIN:-$SLUG.tudominio.com}"

wp core install \
    --url="$URL" \
    --title="$NAME" \
    --admin_user="admin" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="admin@$DOMAIN" \
    --skip-email \
    --allow-root

ok "WordPress instalado"

#########################################################################
# 3. INSTALAR WOOCOMMERCE
#########################################################################

info "Instalando WooCommerce..."

wp plugin install woocommerce --activate --allow-root

ok "WooCommerce instalado"

#########################################################################
# 4. CONFIGURACIÓN BÁSICA
#########################################################################

info "Configurando WooCommerce..."

# Configuración básica de WooCommerce
wp option update woocommerce_store_address "Dirección" --allow-root
wp option update woocommerce_store_city "Ciudad" --allow-root
wp option update woocommerce_default_country "PY" --allow-root
wp option update woocommerce_currency "PYG" --allow-root

ok "WooCommerce configurado"

#########################################################################
# 5. RESTAURAR CONFIGURACIÓN
#########################################################################

info "Restaurando configuración master..."

# Restaurar wp-config original
rm wp-config.php
mv wp-config.php.master wp-config.php

ok "Configuración restaurada"

#########################################################################
# RESUMEN
#########################################################################

echo ""
echo "═══════════════════════════════════════════════════"
ok "Tenant Provisionado Exitosamente"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Tenant:        $NAME"
echo "Slug:          $SLUG"
echo "Base de Datos: $DB_NAME"
echo "URL:           $URL"
echo ""
echo "Credenciales de Admin:"
echo "  Usuario:     admin"
echo "  Password:    $ADMIN_PASS"
echo ""
echo "Accesos:"
echo "  Admin:       $URL/wp-admin"
echo "  Tienda:      $URL"
echo ""
echo "═══════════════════════════════════════════════════"
echo ""
echo "⚠️  IMPORTANTE: Guardá estas credenciales"
echo ""

# Guardar credenciales
cat > "/root/tenant-$SLUG-credentials.txt" <<CREDS
Tenant: $NAME
Slug: $SLUG
DB: $DB_NAME
URL: $URL
Admin User: admin
Admin Pass: $ADMIN_PASS
Created: $(date)
CREDS

ok "Credenciales guardadas en: /root/tenant-$SLUG-credentials.txt"
PROVISION

chmod +x /var/www/woo-enterprise/scripts/provision-tenant.sh