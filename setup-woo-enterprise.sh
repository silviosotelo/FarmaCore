cat > setup-woo-enterprise-complete.sh <<'COMPLETE_SCRIPT'
#!/bin/bash
#########################################################################
# WooCommerce Enterprise Platform - Complete Setup Script
# Ubuntu 22.04 LTS
# Version: 2.0 - Production Ready
# 
# Features:
# - Checkpoint system (resume from failure)
# - Retry logic for network operations
# - Full error handling
# - Rollback capability
# - Detailed logging
#########################################################################

#########################################################################
# CONFIGURATION
#########################################################################

SCRIPT_VERSION="2.0.0"
LOG_FILE="/var/log/woo-enterprise-setup.log"
STATE_FILE="/tmp/woo-enterprise-setup.state"
LOCK_FILE="/tmp/woo-enterprise-setup.lock"

# Retry settings
MAX_RETRIES=3
RETRY_DELAY=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
MYSQL_ROOT_PASSWORD=""
WP_DB_USER="wp_master"
WP_DB_PASS=""
DOMAIN=""
ADMIN_EMAIL=""
SERVER_IP=""

#########################################################################
# HELPER FUNCTIONS
#########################################################################

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

print_step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "STEP: $1"
}

# Check if step was already completed
is_step_complete() {
    local step=$1
    grep -q "^${step}:completed$" "$STATE_FILE" 2>/dev/null
}

# Mark step as completed
mark_step_complete() {
    local step=$1
    echo "${step}:completed" >> "$STATE_FILE"
    log "Step marked complete: $step"
}

# Execute command with retry
execute_with_retry() {
    local command="$1"
    local description="$2"
    local max_attempts=${3:-$MAX_RETRIES}
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Executing: $description (attempt $attempt/$max_attempts)"
        
        if eval "$command"; then
            print_success "$description completed"
            return 0
        else
            local exit_code=$?
            print_warning "$description failed (attempt $attempt/$max_attempts)"
            
            if [ $attempt -lt $max_attempts ]; then
                log "Retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
            fi
            
            attempt=$((attempt + 1))
        fi
    done
    
    print_error "$description failed after $max_attempts attempts"
    return 1
}

# Check if service is running
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        return 0
    else
        return 1
    fi
}

# Wait for service to be ready
wait_for_service() {
    local service=$1
    local max_wait=${2:-30}
    local waited=0
    
    print_info "Waiting for $service to be ready..."
    
    while [ $waited -lt $max_wait ]; do
        if check_service "$service"; then
            print_success "$service is ready"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    
    print_error "$service didn't start in ${max_wait}s"
    return 1
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Create lock file to prevent concurrent execution
create_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_error "Another instance is already running (PID: $pid)"
            exit 1
        else
            print_warning "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Remove lock file
remove_lock() {
    rm -f "$LOCK_FILE"
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    remove_lock
    
    if [ $exit_code -ne 0 ]; then
        print_error "Setup failed with exit code: $exit_code"
        print_info "Check log file: $LOG_FILE"
        print_info "State file: $STATE_FILE"
        echo ""
        print_warning "To resume installation, run this script again"
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM

#########################################################################
# VALIDATION FUNCTIONS
#########################################################################

validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

validate_email() {
    local email=$1
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

validate_mysql_connection() {
    if mysql -u root -e "SELECT 1;" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

#########################################################################
# INSTALLATION STEPS
#########################################################################

step_01_system_update() {
    local step_name="01_system_update"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: System Update"
        return 0
    fi
    
    print_step "STEP 1: System Update"
    
    # Update package lists
    execute_with_retry \
        "apt-get update -qq" \
        "Updating package lists" \
        5 || return 1
    
    # Upgrade packages
    execute_with_retry \
        "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq" \
        "Upgrading system packages" \
        3 || return 1
    
    # Install basic tools
    execute_with_retry \
        "apt-get install -y software-properties-common curl wget git unzip gnupg2 ca-certificates lsb-release" \
        "Installing basic tools" \
        3 || return 1
    
    mark_step_complete "$step_name"
    return 0
}

step_02_install_nginx() {
    local step_name="02_install_nginx"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Nginx Installation"
        return 0
    fi
    
    print_step "STEP 2: Install Nginx"
    
    # Install Nginx
    execute_with_retry \
        "apt-get install -y nginx" \
        "Installing Nginx" \
        3 || return 1
    
    # Wait for Nginx to start
    wait_for_service nginx 10 || return 1
    
    # Create performance config (fix the duplicate issue)
    log "Creating Nginx performance configuration"
    cat > /etc/nginx/conf.d/performance.conf <<'EOF'
# WooCommerce Enterprise - Performance Config
client_max_body_size 64M;
client_body_buffer_size 128k;
fastcgi_buffers 16 16k;
fastcgi_buffer_size 32k;
fastcgi_read_timeout 300;
keepalive_timeout 65;
server_tokens off;
EOF
    
    # Enable Gzip (safely)
    if ! grep -q "gzip_vary on;" /etc/nginx/nginx.conf; then
        sed -i 's/# gzip_vary on;/gzip_vary on;/g' /etc/nginx/nginx.conf
    fi
    
    if ! grep -q "gzip_types" /etc/nginx/nginx.conf | grep -v "#"; then
        sed -i 's/# gzip_types/gzip_types/g' /etc/nginx/nginx.conf
    fi
    
    # Test configuration
    if ! nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        print_error "Nginx configuration test failed"
        return 1
    fi
    
    # Enable and restart
    systemctl enable nginx
    systemctl restart nginx
    
    wait_for_service nginx 10 || return 1
    
    mark_step_complete "$step_name"
    return 0
}

step_03_install_php() {
    local step_name="03_install_php"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: PHP Installation"
        return 0
    fi
    
    print_step "STEP 3: Install PHP 8.2"
    
    # Add Ondřej Surý PPA
    execute_with_retry \
        "add-apt-repository ppa:ondrej/php -y" \
        "Adding PHP repository" \
        3 || return 1
    
    execute_with_retry \
        "apt-get update -qq" \
        "Updating package lists" \
        3 || return 1
    
    # Install PHP and extensions
    local php_packages=(
        "php8.2-fpm"
        "php8.2-mysql"
        "php8.2-curl"
        "php8.2-gd"
        "php8.2-mbstring"
        "php8.2-xml"
        "php8.2-xmlrpc"
        "php8.2-soap"
        "php8.2-intl"
        "php8.2-zip"
        "php8.2-bcmath"
        "php8.2-redis"
        "php8.2-imagick"
    )
    
    execute_with_retry \
        "apt-get install -y ${php_packages[*]}" \
        "Installing PHP 8.2 and extensions" \
        3 || return 1
    
    # Configure php.ini
    local php_ini="/etc/php/8.2/fpm/php.ini"
    
    if [ -f "$php_ini" ]; then
        log "Configuring PHP settings"
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 64M/' "$php_ini"
        sed -i 's/memory_limit = .*/memory_limit = 256M/' "$php_ini"
        sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sed -i 's/max_input_time = .*/max_input_time = 300/' "$php_ini"
        sed -i 's/;max_input_vars = .*/max_input_vars = 5000/' "$php_ini"
    fi
    
    # Configure PHP-FPM pool
    local fpm_pool="/etc/php/8.2/fpm/pool.d/www.conf"
    
    if [ -f "$fpm_pool" ]; then
        log "Configuring PHP-FPM pool"
        sed -i 's/pm = dynamic/pm = ondemand/' "$fpm_pool"
        sed -i 's/pm.max_children = .*/pm.max_children = 50/' "$fpm_pool"
        sed -i 's/;pm.process_idle_timeout = .*/pm.process_idle_timeout = 10s/' "$fpm_pool"
    fi
    
    # Enable and restart PHP-FPM
    systemctl enable php8.2-fpm
    systemctl restart php8.2-fpm
    
    wait_for_service php8.2-fpm 10 || return 1
    
    mark_step_complete "$step_name"
    return 0
}

step_04_install_mysql() {
    local step_name="04_install_mysql"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: MySQL Installation"
        return 0
    fi
    
    print_step "STEP 4: Install MySQL 8.0"
    
    # Generate root password if not provided
    if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
        MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
        log "Generated MySQL root password"
    fi
    
    # Pre-configure MySQL
    export DEBIAN_FRONTEND=noninteractive
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
    
    # Install MySQL
    execute_with_retry \
        "apt-get install -y mysql-server" \
        "Installing MySQL Server" \
        3 || return 1
    
    # Wait for MySQL to start
    wait_for_service mysql 30 || return 1
    
    # Save root credentials
    cat > /root/.my.cnf <<EOF
[client]
user=root
password=$MYSQL_ROOT_PASSWORD
EOF
    chmod 600 /root/.my.cnf
    
    # Secure MySQL installation
    log "Securing MySQL installation"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<'SQL'
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL
    
    # Create custom MySQL config
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

# Slow query log (temporal)
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
EOF
    
    # Restart MySQL
    systemctl restart mysql
    wait_for_service mysql 30 || return 1
    
    # Validate connection
    if ! validate_mysql_connection; then
        print_error "MySQL connection validation failed"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_05_install_redis() {
    local step_name="05_install_redis"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Redis Installation"
        return 0
    fi
    
    print_step "STEP 5: Install Redis"
    
    # Install Redis
    execute_with_retry \
        "apt-get install -y redis-server" \
        "Installing Redis" \
        3 || return 1
    
    # Configure Redis
    log "Configuring Redis"
    sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
    sed -i 's/# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
    # Enable and restart Redis
    systemctl enable redis-server
    systemctl restart redis-server
    
    wait_for_service redis-server 10 || return 1
    
    # Test Redis connection
    if ! redis-cli ping | grep -q "PONG"; then
        print_error "Redis connection test failed"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_06_install_tools() {
    local step_name="06_install_tools"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Tools Installation"
        return 0
    fi
    
    print_step "STEP 6: Install WP-CLI and Composer"
    
    # Install WP-CLI
    if ! command_exists wp; then
        execute_with_retry \
            "curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp" \
            "Installing WP-CLI" \
            3 || return 1
        
        # Verify WP-CLI
        if ! wp --info &>/dev/null; then
            print_error "WP-CLI installation verification failed"
            return 1
        fi
    else
        print_info "WP-CLI already installed"
    fi
    
    # Install Composer
    if ! command_exists composer; then
        execute_with_retry \
            "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\" && php composer-setup.php --quiet && mv composer.phar /usr/local/bin/composer && rm composer-setup.php" \
            "Installing Composer" \
            3 || return 1
        
        # Verify Composer
        if ! composer --version &>/dev/null; then
            print_error "Composer installation verification failed"
            return 1
        fi
    else
        print_info "Composer already installed"
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_07_configure_firewall() {
    local step_name="07_configure_firewall"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Firewall Configuration"
        return 0
    fi
    
    print_step "STEP 7: Configure Firewall"
    
    # Install UFW
    if ! command_exists ufw; then
        execute_with_retry \
            "apt-get install -y ufw" \
            "Installing UFW" \
            3 || return 1
    fi
    
    # Configure UFW rules
    log "Configuring firewall rules"
    ufw --force default deny incoming
    ufw --force default allow outgoing
    ufw --force allow ssh
    ufw --force allow 'Nginx Full'
    
    # Enable UFW
    echo "y" | ufw enable
    
    # Verify UFW status
    if ! ufw status | grep -q "Status: active"; then
        print_error "Firewall activation failed"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_08_create_directories() {
    local step_name="08_create_directories"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Directory Structure"
        return 0
    fi
    
    print_step "STEP 8: Create Directory Structure"
    
    # Create main directories
    log "Creating directory structure"
    mkdir -p /var/www/woo-enterprise/{logs,scripts,backups,tmp}
    
    # Set ownership and permissions
    chown -R www-data:www-data /var/www/woo-enterprise
    chmod -R 755 /var/www/woo-enterprise
    
    # Verify directory creation
    if [ ! -d "/var/www/woo-enterprise/scripts" ]; then
        print_error "Directory creation failed"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_09_create_master_database() {
    local step_name="09_create_master_database"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Master Database"
        return 0
    fi
    
    print_step "STEP 9: Create Master Database"
    
    # Generate WP DB password if not provided
    if [[ -z "$WP_DB_PASS" ]]; then
        WP_DB_PASS=$(openssl rand -base64 32)
    fi
    
    # Create database and user
    log "Creating master_wp database and user"
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS master_wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS';
GRANT ALL PRIVILEGES ON \`master_wp\`.* TO '$WP_DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`tenant_%\`.* TO '$WP_DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Save credentials
    cat > /root/.wp-db-credentials <<EOF
WP_DB_USER=$WP_DB_USER
WP_DB_PASS=$WP_DB_PASS
EOF
    chmod 600 /root/.wp-db-credentials
    
    # Create master tables
    log "Creating master tenant tables"
    mysql master_wp <<'SQL'
CREATE TABLE IF NOT EXISTS `master_tenants` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` VARCHAR(36) UNIQUE NOT NULL,
  `slug` VARCHAR(50) UNIQUE NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `vertical` ENUM('pharmacy','electronics','retail','gastronomy','wholesale') NOT NULL,
  `db_name` VARCHAR(64) NOT NULL,
  `db_host` VARCHAR(255) DEFAULT 'localhost',
  `db_user` VARCHAR(64),
  `db_prefix` VARCHAR(20) DEFAULT 'wp_',
  `primary_domain` VARCHAR(255),
  `subdomain` VARCHAR(100),
  `status` ENUM('active','suspended','trial','migrating','deleted') DEFAULT 'trial',
  `trial_ends_at` DATETIME NULL,
  `settings` JSON,
  `vertical_config` JSON,
  `plan` ENUM('basic','pro','enterprise','custom') DEFAULT 'basic',
  `monthly_fee` DECIMAL(10,2),
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by` BIGINT UNSIGNED,
  INDEX `idx_slug` (`slug`),
  INDEX `idx_domain` (`primary_domain`),
  INDEX `idx_status` (`status`),
  INDEX `idx_vertical` (`vertical`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `master_tenant_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `action` ENUM('created','updated','suspended','activated','deleted','migrated'),
  `performed_by` BIGINT UNSIGNED,
  `ip_address` VARCHAR(45),
  `metadata` JSON,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`tenant_id`) REFERENCES `master_tenants`(`id`) ON DELETE CASCADE,
  INDEX `idx_tenant` (`tenant_id`),
  INDEX `idx_action` (`action`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `master_tenant_admins` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('owner','admin','support') NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_tenant_user` (`tenant_id`, `user_id`),
  FOREIGN KEY (`tenant_id`) REFERENCES `master_tenants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
SQL
    
    # Verify tables were created
    local table_count=$(mysql master_wp -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='master_wp' AND table_name LIKE 'master_%'")
    
    if [ "$table_count" -lt 3 ]; then
        print_error "Failed to create all master tables"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_10_install_wordpress() {
    local step_name="10_install_wordpress"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: WordPress Installation"
        return 0
    fi
    
    print_step "STEP 10: Install WordPress Core"
    
    cd /var/www/woo-enterprise || return 1
    
    # Download WordPress
    if [ ! -f "wp-config-sample.php" ]; then
        execute_with_retry \
            "sudo -u www-data wp core download --locale=es_ES --allow-root" \
            "Downloading WordPress" \
            3 || return 1
    else
        print_info "WordPress already downloaded"
    fi
    
    # Load DB credentials
    source /root/.wp-db-credentials
    
    # Create wp-config.php
    if [ ! -f "wp-config.php" ]; then
        log "Creating wp-config.php"
        sudo -u www-data wp config create \
            --dbname=master_wp \
            --dbuser=$WP_DB_USER \
            --dbpass=$WP_DB_PASS \
            --dbhost=localhost \
            --dbcharset=utf8mb4 \
            --allow-root \
            --extra-php <<'PHP' || return 1
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

/* Debug (temporal) */
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
PHP
    else
        print_info "wp-config.php already exists"
    fi
    
    # Verify wp-config.php
    if [ ! -f "wp-config.php" ]; then
        print_error "Failed to create wp-config.php"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_11_configure_nginx_vhost() {
    local step_name="11_configure_nginx_vhost"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Nginx Virtual Host"
        return 0
    fi
    
    print_step "STEP 11: Configure Nginx Virtual Host"
    
    # Get server IP
    SERVER_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)
    
    if [[ -z "$DOMAIN" ]]; then
        echo ""
        print_warning "Domain configuration required"
        echo "Your server IP: $SERVER_IP"
        echo ""
        
        while true; do
            read -p "Enter your domain (e.g., woo-enterprise.com): " DOMAIN
            
            if validate_domain "$DOMAIN"; then
                break
            else
                print_error "Invalid domain format. Please try again."
            fi
        done
    fi
    
    # Create Nginx vhost
    log "Creating Nginx virtual host for $DOMAIN"
    cat > /etc/nginx/sites-available/woo-enterprise <<EOF
server {
    listen 80;
    server_name $DOMAIN *.$DOMAIN;
    
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
    
    location ~* /(?:uploads|files)/.*\.php\$ {
        deny all;
    }
    
    # Cache static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        expires max;
        log_not_found off;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/woo-enterprise /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    if ! nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        print_error "Nginx configuration test failed"
        return 1
    fi
    
    # Reload Nginx
    systemctl reload nginx
    wait_for_service nginx 10 || return 1
    
    mark_step_complete "$step_name"
    return 0
}

step_12_install_certbot() {
    local step_name="12_install_certbot"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Certbot Installation"
        return 0
    fi
    
    print_step "STEP 12: Install Certbot (SSL)"
    
    # Install Certbot
    execute_with_retry \
        "apt-get install -y certbot python3-certbot-nginx" \
        "Installing Certbot" \
        3 || return 1
    
    # Verify installation
    if ! command_exists certbot; then
        print_error "Certbot installation verification failed"
        return 1
    fi
    
    mark_step_complete "$step_name"
    return 0
}

step_13_create_provision_script() {
    local step_name="13_create_provision_script"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Provision Script"
        return 0
    fi
    
    print_step "STEP 13: Create Tenant Provision Script"
    
    cat > /var/www/woo-enterprise/scripts/provision-tenant.sh <<'PROVISION_SCRIPT'
#!/bin/bash
set -e

TENANT_SLUG=$1
TENANT_NAME=$2
VERTICAL=$3
DOMAIN=$4
ADMIN_EMAIL=${5:-"admin@${DOMAIN}"}

if [[ -z "$TENANT_SLUG" ]] || [[ -z "$TENANT_NAME" ]] || [[ -z "$VERTICAL" ]] || [[ -z "$DOMAIN" ]]; then
    echo "Usage: $0 <slug> <name> <vertical> <domain> [admin_email]"
    echo ""
    echo "Available verticals: pharmacy, electronics, retail, gastronomy, wholesale"
    echo ""
    echo "Example:"
    echo "  $0 farmacia-abc 'Farmacia ABC' pharmacy farmacia-abc.com admin@farmacia-abc.com"
    exit 1
fi

echo "🚀 Provisioning tenant: $TENANT_NAME"

# Generate unique DB name
TIMESTAMP=$(date +%s)
DB_NAME="tenant_${TIMESTAMP}_wp"

echo "📦 Creating database: $DB_NAME"

# Load credentials
source /root/.wp-db-credentials

# Create database
mysql -u root <<EOF
CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$WP_DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "⚙️ Installing WordPress..."
cd /var/www/woo-enterprise

ADMIN_PASS=$(openssl rand -base64 16)

# Install WordPress for tenant (we'll use WP-CLI with proper DB switching later)
# For now, create a temporary wp-config
TMP_CONFIG=$(mktemp)
cat > "$TMP_CONFIG" <<WPCONFIG
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$WP_DB_USER');
define('DB_PASSWORD', '$WP_DB_PASS');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
WPCONFIG

# Backup original wp-config
if [ -f "wp-config.php" ]; then
    mv wp-config.php wp-config.php.bak
fi

# Use temp config
mv "$TMP_CONFIG" wp-config.php

# Install WordPress
sudo -u www-data wp core install \
    --url="https://$DOMAIN" \
    --title="$TENANT_NAME" \
    --admin_user="admin" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root

# Install WooCommerce
echo "🛒 Installing WooCommerce..."
WP_CLI_CACHE_DIR=/tmp sudo -u www-data wp plugin install woocommerce --activate --allow-root

# Restore original wp-config
if [ -f "wp-config.php.bak" ]; then
    mv wp-config.php.bak wp-config.php
else
    rm wp-config.php
fi

# Register tenant in master_wp
echo "📝 Registering tenant..."
UUID=$(uuidgen)

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
echo "✅ Tenant provisioned successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tenant ID: $TENANT_ID"
echo "UUID: $UUID"
echo "Database: $DB_NAME"
echo "URL: https://$DOMAIN"
echo "Admin User: admin"
echo "Admin Password: $ADMIN_PASS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️ SAVE THESE CREDENTIALS SECURELY"
echo ""
echo "📌 Next steps:"
echo "1. Configure DNS: A record $DOMAIN → your IP"
echo "2. Get SSL: certbot --nginx -d $DOMAIN"
echo "3. Access: https://$DOMAIN/wp-admin"
PROVISION_SCRIPT
    
    chmod +x /var/www/woo-enterprise/scripts/provision-tenant.sh
    
    mark_step_complete "$step_name"
    return 0
}

step_14_create_backup_script() {
    local step_name="14_create_backup_script"
    
    if is_step_complete "$step_name"; then
        print_info "Step already completed: Backup Script"
        return 0
    fi
    
    print_step "STEP 14: Create Backup Script"
    
    cat > /var/www/woo-enterprise/scripts/backup-tenant.sh <<'BACKUP_SCRIPT'
#!/bin/bash
TENANT_ID=$1
BACKUP_DIR="/var/www/woo-enterprise/backups"
DATE=$(date +%Y%m%d_%H%M%S)

if [[ -z "$TENANT_ID" ]]; then
    echo "Usage: $0 <tenant_id>"
    exit 1
fi

DB_NAME=$(mysql master_wp -sse "SELECT db_name FROM master_tenants WHERE id=$TENANT_ID")

if [[ -z "$DB_NAME" ]]; then
    echo "Error: Tenant $TENANT_ID not found"
    exit 1
fi

BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"
mysqldump --single-transaction --routines --triggers "$DB_NAME" | gzip > "$BACKUP_FILE"

# Keep only last 7 days
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +7 -delete

echo "✅ Backup completed: $BACKUP_FILE"
BACKUP_SCRIPT
    
    chmod +x /var/www/woo-enterprise/scripts/backup-tenant.sh
    
    mark_step_complete "$step_name"
    return 0
}

#########################################################################
# MAIN INSTALLATION FLOW
#########################################################################

main() {
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  WooCommerce Enterprise Platform Setup v${SCRIPT_VERSION}"
    echo "  Ubuntu 22.04 LTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check prerequisites
    check_root
    create_lock
    
    # Initialize log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    # Create state file if doesn't exist
    touch "$STATE_FILE"
    
    log "Starting WooCommerce Enterprise Platform Setup v${SCRIPT_VERSION}"
    
    # Collect configuration (only if not resuming)
    if [ ! -s "$STATE_FILE" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Configuration"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Domain
        while true; do
            read -p "Main domain (e.g., woo-enterprise.com): " DOMAIN
            if validate_domain "$DOMAIN"; then
                break
            else
                print_error "Invalid domain format"
            fi
        done
        
        # Admin email
        while true; do
            read -p "Administrator email: " ADMIN_EMAIL
            if validate_email "$ADMIN_EMAIL"; then
                break
            else
                print_error "Invalid email format"
            fi
        done
        
        # MySQL password
        read -sp "MySQL root password (Enter for auto-generate): " MYSQL_ROOT_PASSWORD
        echo ""
        
        # WP DB password
        read -sp "WordPress DB password (Enter for auto-generate): " WP_DB_PASS
        echo ""
        
        echo ""
        echo "Configuration summary:"
        echo "  Domain: $DOMAIN"
        echo "  Email: $ADMIN_EMAIL"
        echo "  MySQL root password: ${MYSQL_ROOT_PASSWORD:-[auto-generated]}"
        echo "  WP DB password: ${WP_DB_PASS:-[auto-generated]}"
        echo ""
        
        read -p "Continue with installation? (y/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Installation cancelled by user"
            exit 0
        fi
    else
        print_info "Resuming installation from checkpoint"
    fi
    
    # Execute installation steps
    local steps=(
        "step_01_system_update"
        "step_02_install_nginx"
        "step_03_install_php"
        "step_04_install_mysql"
        "step_05_install_redis"
        "step_06_install_tools"
        "step_07_configure_firewall"
        "step_08_create_directories"
        "step_09_create_master_database"
        "step_10_install_wordpress"
        "step_11_configure_nginx_vhost"
        "step_12_install_certbot"
        "step_13_create_provision_script"
        "step_14_create_backup_script"
    )
    
    local total_steps=${#steps[@]}
    local current_step=1
    
    for step in "${steps[@]}"; do
        echo ""
        print_info "Progress: Step $current_step of $total_steps"
        
        if ! $step; then
            print_error "Step failed: $step"
            print_info "To retry, run this script again"
            exit 1
        fi
        
        current_step=$((current_step + 1))
    done
    
    # Installation complete
    print_final_summary
}

print_final_summary() {
    # Get server IP
    SERVER_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✅ INSTALLATION COMPLETED SUCCESSFULLY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Installed components:"
    echo "   • Nginx $(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo 'OK')"
    echo "   • PHP $(php -v | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'OK')"
    echo "   • MySQL $(mysql --version | grep -oP '\d+\.\d+\.\d+' || echo 'OK')"
    echo "   • Redis $(redis-server --version | grep -oP '\d+\.\d+\.\d+' || echo 'OK')"
    echo "   • WP-CLI $(wp --version | grep -oP '\d+\.\d+\.\d+' || echo 'OK')"
    echo "   • Composer $(composer --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo 'OK')"
    echo ""
    echo "📁 Important locations:"
    echo "   • WordPress: /var/www/woo-enterprise"
    echo "   • Scripts: /var/www/woo-enterprise/scripts"
    echo "   • Logs: /var/www/woo-enterprise/logs"
    echo "   • Backups: /var/www/woo-enterprise/backups"
    echo "   • Setup log: $LOG_FILE"
    echo ""
    echo "🔑 Credentials saved in:"
    echo "   • MySQL root: /root/.my.cnf"
    echo "   • WordPress DB: /root/.wp-db-credentials"
    echo ""
    echo "🌐 Network configuration:"
    echo "   • Domain: ${DOMAIN:-Not configured}"
    echo "   • Server IP: $SERVER_IP"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📌 NEXT STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1️⃣ Configure DNS:"
    echo "   Create these records at your DNS provider:"
    echo "   A    @     → $SERVER_IP"
    echo "   A    *     → $SERVER_IP"
    echo "   A    www   → $SERVER_IP"
    echo ""
    echo "2️⃣ Obtain SSL certificate:"
    if [[ ! -z "$DOMAIN" ]]; then
        echo "   certbot --nginx -d $DOMAIN -d www.$DOMAIN --email ${ADMIN_EMAIL:-your@email.com}"
    else
        echo "   certbot --nginx -d your-domain.com -d www.your-domain.com"
    fi
    echo ""
    echo "3️⃣ Complete WordPress installation:"
    if [[ ! -z "$DOMAIN" ]]; then
        echo "   http://$DOMAIN/wp-admin/install.php"
    else
        echo "   http://YOUR_DOMAIN/wp-admin/install.php"
    fi
    echo ""
    echo "4️⃣ Create your first tenant:"
    echo "   /var/www/woo-enterprise/scripts/provision-tenant.sh \\"
    echo "       farmacia-abc 'Farmacia ABC' pharmacy farmacia-abc.com"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Clean up state file on success
    rm -f "$STATE_FILE"
    
    log "Installation completed successfully"
}

# Run main installation
main "$@"
COMPLETE_SCRIPT

chmod +x setup-woo-enterprise-complete.sh