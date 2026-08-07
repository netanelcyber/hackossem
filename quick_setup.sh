#!/bin/bash
# Active Directory Training Environment - Quick Setup (Bash)
# Works on Linux, macOS, and Windows (WSL/Git Bash)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/machines_config.json"
MANAGE_SCRIPT="${SCRIPT_DIR}/manage_ad_machines.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Make scripts executable
chmod +x "$MANAGE_SCRIPT" 2>/dev/null || true

# Function to print colored output
print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Function to check dependencies
check_dependencies() {
    print_header "Checking Dependencies"

    local missing=0

    # Check for VirtualBox
    if command -v VBoxManage &> /dev/null; then
        print_success "VirtualBox found: $(VBoxManage --version)"
    else
        print_error "VirtualBox not installed"
        ((missing++))
    fi

    # Check for jq (optional but recommended)
    if command -v jq &> /dev/null; then
        print_success "jq found (JSON parser)"
    else
        print_warning "jq not found (optional, but recommended for full functionality)"
    fi

    # Check for configuration file
    if [ -f "$CONFIG_FILE" ]; then
        print_success "Configuration file found"
    else
        print_error "Configuration file not found: $CONFIG_FILE"
        ((missing++))
    fi

    if [ $missing -gt 0 ]; then
        print_error "$missing dependencies missing"
        echo ""
        echo "Installation instructions:"
        echo "  Ubuntu/Debian: sudo apt-get install virtualbox virtualbox-dkms jq"
        echo "  macOS: brew install virtualbox jq"
        echo "  Windows: Download from https://www.virtualbox.org/wiki/Downloads"
        echo ""
        exit 1
    fi

    print_success "All dependencies satisfied"
}

# Function to show main menu
show_menu() {
    echo ""
    echo -e "${CYAN}Active Directory Training Environment${NC}"
    echo -e "${CYAN}Quick Setup Menu${NC}"
    echo ""
    echo "  1) Create all 10 VMs"
    echo "  2) Start all VMs"
    echo "  3) Stop all VMs"
    echo "  4) Show status"
    echo "  5) Delete all VMs"
    echo "  6) Run management script"
    echo "  7) View configuration"
    echo "  8) Exit"
    echo ""
}

# Function to view configuration
view_config() {
    print_header "Configuration Details"

    if command -v jq &> /dev/null; then
        echo "Domain: $(jq -r '.environment.domain' "$CONFIG_FILE")"
        echo "Network: $(jq -r '.environment.baseNetwork' "$CONFIG_FILE")"
        echo "Hypervisor: $(jq -r '.environment.hypervisor' "$CONFIG_FILE")"
        echo ""
        echo "Machines:"
        jq -r '.machines[] | "  \(.name) - \(.displayName) (\(.role)) @ \(.ip)"' "$CONFIG_FILE"
        echo ""
    else
        cat "$CONFIG_FILE"
    fi
}

# Function to handle create all
handle_create_all() {
    print_header "Creating All VMs"

    print_warning "This will create 10 VirtualBox VMs"
    print_warning "Ensure you have 800GB+ free disk space and 32GB+ RAM"
    echo ""
    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return
    fi

    "$MANAGE_SCRIPT" create-all
}

# Function to handle start all
handle_start_all() {
    print_header "Starting All VMs"

    "$MANAGE_SCRIPT" start-all

    echo ""
    print_info "VMs are starting in headless mode"
    print_info "Connect to them using:"
    echo "  - VirtualBox GUI: VirtualBox"
    echo "  - SSH: ssh -u Administrator <vm-ip>"
    echo "  - RDP: Remote Desktop to <vm-ip>"
}

# Function to handle stop all
handle_stop_all() {
    print_header "Stopping All VMs"

    "$MANAGE_SCRIPT" stop-all
}

# Function to handle status
handle_status() {
    "$MANAGE_SCRIPT" status
}

# Function to handle delete all
handle_delete_all() {
    print_header "Delete All VMs"

    print_error "This will permanently delete all VMs and their data!"
    echo ""
    read -p "Type 'DELETE ALL' to confirm: " confirm

    if [ "$confirm" = "DELETE ALL" ]; then
        "$MANAGE_SCRIPT" delete-all
    else
        print_info "Cancelled"
    fi
}

# Function to show quick commands
show_quick_commands() {
    echo ""
    echo -e "${YELLOW}Quick Commands:${NC}"
    echo ""
    echo "  Direct management:"
    echo "    $MANAGE_SCRIPT create-all       # Create all VMs"
    echo "    $MANAGE_SCRIPT start-all        # Start all VMs"
    echo "    $MANAGE_SCRIPT stop-all         # Stop all VMs"
    echo "    $MANAGE_SCRIPT status           # Show status"
    echo "    $MANAGE_SCRIPT start AD-DC01    # Start specific VM"
    echo "    $MANAGE_SCRIPT stop AD-WS01     # Stop specific VM"
    echo ""
    echo "  Setup scripts:"
    echo "    bash $SCRIPT_DIR/ad_machines_setup.sh"
    echo ""
}

# Function to show setup wizard
setup_wizard() {
    print_header "Active Directory Setup Wizard"

    echo "This wizard will guide you through setting up the AD training environment"
    echo ""
    echo "Step 1: Verify prerequisites"
    check_dependencies
    echo ""

    echo "Step 2: Review configuration"
    view_config
    echo ""

    read -p "Press Enter to continue..."

    echo ""
    echo "Step 3: Create VMs"
    read -p "Create all 10 VMs now? (yes/no): " create_confirm

    if [ "$create_confirm" = "yes" ]; then
        handle_create_all
    else
        print_info "You can create VMs later using:"
        echo "  $MANAGE_SCRIPT create-all"
    fi

    echo ""
    print_success "Setup wizard completed!"
    show_quick_commands
}

# Function to run interactive mode
interactive_mode() {
    while true; do
        show_menu
        read -p "Select option (1-8): " choice

        case $choice in
            1)
                handle_create_all
                ;;
            2)
                handle_start_all
                ;;
            3)
                handle_stop_all
                ;;
            4)
                handle_status
                read -p "Press Enter to continue..."
                ;;
            5)
                handle_delete_all
                ;;
            6)
                print_info "Use: $MANAGE_SCRIPT [command]"
                show_quick_commands
                read -p "Press Enter to continue..."
                ;;
            7)
                view_config
                read -p "Press Enter to continue..."
                ;;
            8)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
    done
}

# Main function
main() {
    # Check if running with command line argument
    if [ $# -gt 0 ]; then
        case "$1" in
            --no-check)
                interactive_mode
                ;;
            --wizard)
                setup_wizard
                ;;
            --help)
                echo "Active Directory Training Environment - Quick Setup"
                echo ""
                echo "Usage: $0 [option]"
                echo ""
                echo "Options:"
                echo "  (no args)     Interactive menu"
                echo "  --wizard      Setup wizard"
                echo "  --no-check    Skip dependency check"
                echo "  --help        Show this help"
                echo ""
                echo "Direct management:"
                echo "  $MANAGE_SCRIPT create-all"
                echo "  $MANAGE_SCRIPT start-all"
                echo "  $MANAGE_SCRIPT stop-all"
                echo "  $MANAGE_SCRIPT status"
                echo ""
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use: $0 --help"
                exit 1
                ;;
        esac
    else
        # Check dependencies first
        check_dependencies
        echo ""

        # Ask user what they want to do
        echo "Welcome to Active Directory Training Environment!"
        echo ""
        read -p "Run interactive menu? (yes/no): " menu_choice

        if [ "$menu_choice" = "yes" ]; then
            interactive_mode
        else
            show_quick_commands
        fi
    fi
}

# Run main function
main "$@"
