cat > uninstall-woo-enterprise-full.sh <<'FULL_UNINSTALL_SCRIPT'
#!/bin/bash
#########################################################################
# WooCommerce Enterprise Platform - FULL Uninstall
# Removes EVERYTHING including Nginx, PHP, MySQL, Redis
#########################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

print_error() { echo -e "${RED}✗ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_bold() { echo -e "${BOLD}$1${NC}"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

display_warning() {
    clear
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${RED}${BOLD}  ⚠️  FULL SYSTEM UNINSTALL  ⚠️${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${RED}THIS WILL REMOVE EVERYTHING:${NC}"
    echo ""
    echo "  📦 Nginx (complete removal)"
    echo "  📦 PHP 8.2 (all extensions)"
    echo "  📦 MySQL 8.0 (ALL databases)"
    echo "  📦 Redis"
    echo "  📦 WP-CLI"
    echo "  📦 Composer"
    echo "  📁 All WordPress files"
    echo "  🗄️  ALL databases"
    echo "  📝 All configuration files"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

confirm_full_uninstall() {
    echo "Type 'PURGE EVERYTHING' to confirm FULL uninstall:"
    read -r confirmation
    
    if [[ "$confirmation" != "PURGE EVERYTHING" ]]; then
        print_warning "Full uninstall cancelled"
        exit 0
    fi
}

main() {
    check_root
    display_warning
    confirm_full_uninstall
    
    echo ""
    print_bold "Starting FULL uninstall..."
    echo ""
    
    # First run standard uninstall
    if [ -f "./uninstall-woo-enterprise.sh" ]; then
        print_warning "Running standard uninstall first..."
        # Auto-answer prompts
        echo -e "n\nDELETE EVERYTHING\nyes" | bash ./uninstall-woo-enterprise.sh
    fi
    
    # Remove packages
    print_bold "Removing packages..."
    
    # Stop services
    systemctl stop nginx 2>/dev/null || true
    systemctl stop php8.2-fpm 2>/dev/null || true
    systemctl stop mysql 2>/dev/null || true
    systemctl stop redis-server 2>/dev/null || true
    
    # Purge packages
    apt-get purge -y nginx nginx-common nginx-core 2>/dev/null || true
    apt-get purge -y php8.2* 2>/dev/null || true
    apt-get purge -y mysql-server mysql-client mysql-common 2>/dev/null || true
    apt-get purge -y redis-server redis-tools 2>/dev/null || true
    
    # Remove WP-CLI and Composer
    rm -f /usr/local/bin/wp
    rm -f /usr/local/bin/composer
    
    # Autoremove unused dependencies
    apt-get autoremove -y
    apt-get autoclean
    
    # Remove configuration directories
    rm -rf /etc/nginx
    rm -rf /etc/php
    rm -rf /etc/mysql
    rm -rf /etc/redis
    rm -rf /var/lib/mysql
    rm -rf /var/lib/redis
    
    print_success "Full uninstall completed"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✅ SYSTEM CLEANED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Your system is now clean. To reinstall:"
    echo "  ./setup-woo-enterprise-complete.sh"
    echo ""
}

main "$@"
FULL_UNINSTALL_SCRIPT

chmod +x uninstall-woo-enterprise-full.sh