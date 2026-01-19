cat > install-ssl.sh <<'SSL_INSTALLER'
#!/bin/bash
#########################################################################
# Instalador de SSL con Auto-Renovación
# Certbot + Let's Encrypt
#########################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}➜${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
   fail "Ejecutá como root: sudo bash install-ssl.sh"
fi

clear
echo "═══════════════════════════════════════════════════"
echo "  Instalador de SSL con Auto-Renovación"
echo "═══════════════════════════════════════════════════"
echo ""

#########################################################################
# VERIFICACIONES PREVIAS
#########################################################################

info "Verificando requisitos..."

# Verificar Nginx
if ! systemctl is-active --quiet nginx; then
    fail "Nginx no está corriendo. Instalalo primero."
fi

# Verificar si ya hay dominio configurado
CURRENT_DOMAIN=$(grep -r "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v default | head -1 | awk '{print $2}' | cut -d';' -f1 | head -1)

echo ""
if [ -n "$CURRENT_DOMAIN" ]; then
    info "Dominio actual configurado: $CURRENT_DOMAIN"
    echo ""
    echo -n "¿Usar este dominio para SSL? (s/n): "
    read -n 1 USE_CURRENT
    echo ""
    
    if [[ $USE_CURRENT =~ ^[SsYy]$ ]]; then
        DOMAIN=$CURRENT_DOMAIN
    else
        echo -n "Ingresá el dominio: "
        read DOMAIN
    fi
else
    echo -n "Ingresá tu dominio (ej: ejemplo.com): "
    read DOMAIN
fi

if [ -z "$DOMAIN" ]; then
    fail "Dominio vacío"
fi

# Email para renovaciones
echo ""
echo -n "Ingresá tu email (para avisos de renovación): "
read EMAIL

if [ -z "$EMAIL" ]; then
    fail "Email vacío"
fi

# Verificar DNS
echo ""
info "Verificando DNS para $DOMAIN..."

SERVER_IP=$(hostname -I | awk '{print $1}')
DOMAIN_IP=$(dig +short $DOMAIN | tail -1)

if [ -z "$DOMAIN_IP" ]; then
    warn "No se pudo resolver $DOMAIN"
    echo ""
    echo "Asegurate de que tu DNS esté configurado:"
    echo "  A    @     → $SERVER_IP"
    echo "  A    www   → $SERVER_IP"
    echo ""
    echo -n "¿Continuar igual? (s/n): "
    read -n 1 CONTINUE
    echo ""
    
    if [[ ! $CONTINUE =~ ^[SsYy]$ ]]; then
        exit 0
    fi
else
    if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
        warn "El DNS apunta a $DOMAIN_IP pero tu servidor es $SERVER_IP"
        echo ""
        echo -n "¿Continuar igual? (s/n): "
        read -n 1 CONTINUE
        echo ""
        
        if [[ ! $CONTINUE =~ ^[SsYy]$ ]]; then
            exit 0
        fi
    else
        ok "DNS configurado correctamente"
    fi
fi

#########################################################################
# INSTALAR CERTBOT
#########################################################################

echo ""
info "Instalando Certbot..."

apt-get update -qq
apt-get install -y certbot python3-certbot-nginx

ok "Certbot instalado"

#########################################################################
# OBTENER CERTIFICADO SSL
#########################################################################

echo ""
info "Obteniendo certificado SSL para $DOMAIN..."

# Determinar dominios a certificar
DOMAINS="-d $DOMAIN"

# Preguntar por www
if [[ ! $DOMAIN =~ ^www\. ]]; then
    echo ""
    echo -n "¿Incluir www.$DOMAIN? (s/n): "
    read -n 1 INCLUDE_WWW
    echo ""
    
    if [[ $INCLUDE_WWW =~ ^[SsYy]$ ]]; then
        DOMAINS="$DOMAINS -d www.$DOMAIN"
    fi
fi

# Preguntar por wildcard
echo ""
echo -n "¿Incluir wildcard *.$DOMAIN (para subdomains)? (s/n): "
read -n 1 INCLUDE_WILDCARD
echo ""

if [[ $INCLUDE_WILDCARD =~ ^[SsYy]$ ]]; then
    warn "Wildcard requiere validación DNS manual"
    echo ""
    
    # Obtener certificado wildcard
    certbot certonly \
        --manual \
        --preferred-challenges=dns \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN" \
        -d "*.$DOMAIN"
else
    # Obtener certificado normal (automático con nginx)
    certbot --nginx \
        $DOMAINS \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --redirect \
        --non-interactive
fi

if [ $? -eq 0 ]; then
    ok "Certificado SSL obtenido exitosamente"
else
    fail "Error al obtener certificado SSL"
fi

#########################################################################
# CONFIGURAR AUTO-RENOVACIÓN
#########################################################################

echo ""
info "Configurando auto-renovación..."

# Crear script de renovación
cat > /etc/cron.daily/certbot-renewal <<'CRON'
#!/bin/bash
# Auto-renovación de certificados SSL

# Renovar certificados
certbot renew --quiet --post-hook "systemctl reload nginx"

# Log
echo "[$(date)] Renovación ejecutada" >> /var/log/certbot-renewal.log
CRON

chmod +x /etc/cron.daily/certbot-renewal

# Crear timer de systemd (más confiable que cron)
cat > /etc/systemd/system/certbot-renewal.timer <<'TIMER'
[Unit]
Description=Certbot Renewal Timer

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
TIMER

cat > /etc/systemd/system/certbot-renewal.service <<'SERVICE'
[Unit]
Description=Certbot Renewal Service

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
SERVICE

# Activar timer
systemctl daemon-reload
systemctl enable certbot-renewal.timer
systemctl start certbot-renewal.timer

ok "Auto-renovación configurada (se ejecuta diariamente)"

#########################################################################
# VERIFICAR CONFIGURACIÓN NGINX
#########################################################################

echo ""
info "Verificando configuración de Nginx..."

# Test configuración
if nginx -t 2>&1 | grep -q "successful"; then
    ok "Configuración de Nginx válida"
    systemctl reload nginx
    ok "Nginx recargado"
else
    warn "Hay errores en la configuración de Nginx"
    nginx -t
fi

#########################################################################
# RESUMEN
#########################################################################

echo ""
echo "═══════════════════════════════════════════════════"
ok "SSL Configurado Exitosamente"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Dominio(s):        $DOMAIN"
echo "Email:             $EMAIL"
echo "Auto-renovación:   ✓ Activa (diaria)"
echo "Ubicación certs:   /etc/letsencrypt/live/$DOMAIN/"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  URLs de Acceso"
echo "═══════════════════════════════════════════════════"
echo ""
echo "HTTPS:  https://$DOMAIN"
if [[ $INCLUDE_WWW =~ ^[SsYy]$ ]]; then
    echo "        https://www.$DOMAIN"
fi
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Comandos Útiles"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Ver certificados:"
echo "  certbot certificates"
echo ""
echo "Renovar manualmente:"
echo "  certbot renew"
echo ""
echo "Ver status de auto-renovación:"
echo "  systemctl status certbot-renewal.timer"
echo ""
echo "Ver logs de renovación:"
echo "  cat /var/log/certbot-renewal.log"
echo ""

SSL_INSTALLER

chmod +x install-ssl.sh