cat > reinstall-woo-enterprise.sh <<'REINSTALL_SCRIPT'
#!/bin/bash
#########################################################################
# Quick Reinstall - Uninstall + Install in one command
#########################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✗ This script must be run as root${NC}"
        exit 1
    fi
}

main() {
    check_root
    
    clear
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  WooCommerce Enterprise - Quick Reinstall"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if uninstall script exists
    if [ ! -f "./uninstall-woo-enterprise.sh" ]; then
        echo -e "${RED}✗ uninstall-woo-enterprise.sh not found${NC}"
        exit 1
    fi
    
    # Check if install script exists
    if [ ! -f "./setup-woo-enterprise-complete.sh" ]; then
        echo -e "${RED}✗ setup-woo-enterprise-complete.sh not found${NC}"
        exit 1
    fi
    
    print_warning "This will:"
    echo "  1. Uninstall current installation (WITH backup)"
    echo "  2. Clean all state files"
    echo "  3. Run fresh installation"
    echo ""
    
    read -p "Continue? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Reinstall cancelled"
        exit 0
    fi
    
    # Step 1: Uninstall (auto-answer with backup)
    print_success "Step 1: Running uninstall..."
    echo -e "y\nDELETE EVERYTHING\nyes" | bash ./uninstall-woo-enterprise.sh
    
    # Step 2: Clean state
    print_success "Step 2: Cleaning state files..."
    rm -f /tmp/woo-enterprise-setup.state
    rm -f /tmp/woo-enterprise-setup.lock
    
    # Step 3: Fresh install
    print_success "Step 3: Starting fresh installation..."
    echo ""
    
    bash ./setup-woo-enterprise-complete.sh
}

main "$@"
REINSTALL_SCRIPT

chmod +x reinstall-woo-enterprise.sh