#!/bin/bash
# Active Directory Training Machines Manager (Bash)
# Manages 10 VirtualBox VMs configured for AD training
# Works on Linux, macOS, and Windows (WSL/Git Bash)

set -euo pipefail

# Configuration
CONFIG_FILE="${1:-machines_config.json}"
VM_BASE_PATH="${VM_BASE_PATH:-/mnt/vms}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if VBoxManage is installed
check_vboxmanage() {
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VBoxManage not found. Please install VirtualBox."
        exit 1
    fi
}

# Function to load JSON configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    print_success "Configuration loaded: $CONFIG_FILE"
}

# Function to get all machine names from JSON
get_machines() {
    if command -v jq &> /dev/null; then
        jq -r '.machines[].name' "$CONFIG_FILE"
    else
        print_warning "jq not found, using grep fallback"
        grep '"name"' "$CONFIG_FILE" | grep -oP '"name"\s*:\s*"\K[^"]+' | head -10
    fi
}

# Function to get machine info from JSON
get_machine_info() {
    local machine_name="$1"
    if command -v jq &> /dev/null; then
        jq ".machines[] | select(.name==\"$machine_name\")" "$CONFIG_FILE"
    fi
}

# Function to get VM status
get_vm_status() {
    local vm_name="$1"
    local status=$(VBoxManage showvminfo "$vm_name" --machinereadable 2>/dev/null | grep "^VMState=" | cut -d'=' -f2 | tr -d '"' || echo "Not Found")
    echo "$status"
}

# Function to start a VM
start_vm() {
    local vm_name="$1"
    print_info "Starting $vm_name..."

    if VBoxManage startvm "$vm_name" --type headless 2>/dev/null; then
        print_success "$vm_name started"
        return 0
    else
        print_error "Failed to start $vm_name"
        return 1
    fi
}

# Function to stop a VM
stop_vm() {
    local vm_name="$1"
    print_info "Stopping $vm_name..."

    if VBoxManage controlvm "$vm_name" poweroff 2>/dev/null; then
        print_success "$vm_name stopped"
        return 0
    else
        print_error "Failed to stop $vm_name"
        return 1
    fi
}

# Function to create a VM
create_vm() {
    local vm_name="$1"
    local ram="$2"
    local cpus="$3"
    local disk_size="$4"

    print_info "Creating VM: $vm_name"

    # Create VM
    VBoxManage createvm \
        --name "$vm_name" \
        --ostype "Windows2022_64" \
        --basefolder "$VM_BASE_PATH" \
        --register 2>/dev/null

    # Configure resources
    VBoxManage modifyvm "$vm_name" \
        --memory "$ram" \
        --cpus "$cpus" \
        --vram 128 2>/dev/null

    # Configure network
    VBoxManage modifyvm "$vm_name" \
        --nic1 bridged \
        --bridgeadapter1 "eth0" \
        --nictype1 "82540EM" 2>/dev/null

    # Create storage controller
    VBoxManage storagectl "$vm_name" \
        --name "SATA Controller" \
        --add sata \
        --controller IntelAhci 2>/dev/null

    # Create disk
    local disk_path="$VM_BASE_PATH/$vm_name/${vm_name}.vdi"
    mkdir -p "$(dirname "$disk_path")"

    VBoxManage createmedium disk \
        --filename "$disk_path" \
        --size "$disk_size" \
        --format VDI 2>/dev/null

    # Attach disk
    VBoxManage storageattach "$vm_name" \
        --storagectl "SATA Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium "$disk_path" 2>/dev/null

    # Attach IDE controller
    VBoxManage storagectl "$vm_name" \
        --name "IDE Controller" \
        --add ide 2>/dev/null

    print_success "$vm_name created"
}

# Function to delete a VM
delete_vm() {
    local vm_name="$1"
    print_info "Deleting VM: $vm_name"

    local status=$(get_vm_status "$vm_name")

    if [ "$status" != "Not Found" ]; then
        # Stop VM if running
        if [ "$status" != "poweroff" ]; then
            VBoxManage controlvm "$vm_name" poweroff 2>/dev/null || true
            sleep 2
        fi

        # Unregister and delete
        if VBoxManage unregistervm "$vm_name" --delete 2>/dev/null; then
            print_success "$vm_name deleted"
            return 0
        else
            print_error "Failed to delete $vm_name"
            return 1
        fi
    else
        print_warning "$vm_name not found"
        return 0
    fi
}

# Function to show all VMs status
show_status() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Active Directory Training Environment${NC}"
    echo -e "${CYAN}========================================${NC}"

    if command -v jq &> /dev/null; then
        local domain=$(jq -r '.environment.domain' "$CONFIG_FILE")
        local network=$(jq -r '.environment.baseNetwork' "$CONFIG_FILE")
        echo -e "${GREEN}Domain:${NC} $domain"
        echo -e "${GREEN}Network:${NC} $network"
    fi

    echo ""
    echo -e "${BLUE}$(printf '%-15s %-15s %-18s %-15s %-10s %-5s\n' 'Name' 'Role' 'IP' 'Status' 'Memory' 'CPUs')${NC}"
    echo -e "${BLUE}$(printf '%0.s-' {1..78})${NC}"

    local machines=$(get_machines)
    while IFS= read -r vm_name; do
        if [ -z "$vm_name" ]; then
            continue
        fi

        local status=$(get_vm_status "$vm_name")
        local info=$(get_machine_info "$vm_name")

        if command -v jq &> /dev/null && [ -n "$info" ]; then
            local role=$(echo "$info" | jq -r '.role')
            local ip=$(echo "$info" | jq -r '.ip')
            local memory=$(echo "$info" | jq -r '.resources.memory_mb')
            local cpus=$(echo "$info" | jq -r '.resources.cpus')

            # Color status based on state
            local status_color="$RED"
            if [ "$status" = "running" ]; then
                status_color="$GREEN"
            elif [ "$status" = "poweroff" ]; then
                status_color="$YELLOW"
            fi

            printf '%-15s %-15s %-18s ' "$vm_name" "$role" "$ip"
            printf "${status_color}%-15s${NC} " "$status"
            printf '%-10s %-5s\n' "${memory}MB" "$cpus"
        else
            # Fallback without jq
            printf '%-15s %-15s %-18s ' "$vm_name" "?" "?"
            printf "${status_color}%-15s${NC} " "$status"
            printf '%-10s %-5s\n' "?" "?"
        fi
    done <<< "$machines"

    echo ""
}

# Function to create all VMs
create_all() {
    print_info "Creating all VMs from configuration..."
    echo ""

    local success=0
    local failed=0
    local machines=$(get_machines)

    while IFS= read -r vm_name; do
        if [ -z "$vm_name" ]; then
            continue
        fi

        if command -v jq &> /dev/null; then
            local info=$(get_machine_info "$vm_name")
            local ram=$(echo "$info" | jq -r '.resources.memory_mb')
            local cpus=$(echo "$info" | jq -r '.resources.cpus')
            local disk=$(echo "$info" | jq -r '.resources.disk_mb')

            if create_vm "$vm_name" "$ram" "$cpus" "$disk"; then
                ((success++))
            else
                ((failed++))
            fi
        fi

        sleep 0.5
    done <<< "$machines"

    echo ""
    print_success "Creation complete: $success created, $failed failed"
}

# Function to start all VMs
start_all() {
    print_info "Starting all VMs..."
    echo ""

    local machines=$(get_machines)
    local count=0

    while IFS= read -r vm_name; do
        if [ -z "$vm_name" ]; then
            continue
        fi

        if start_vm "$vm_name"; then
            ((count++))
        fi
        sleep 1
    done <<< "$machines"

    echo ""
    print_success "Started $count VMs"
}

# Function to stop all VMs
stop_all() {
    print_info "Stopping all VMs..."
    echo ""

    local machines=$(get_machines)
    local count=0

    while IFS= read -r vm_name; do
        if [ -z "$vm_name" ]; then
            continue
        fi

        if stop_vm "$vm_name"; then
            ((count++))
        fi
        sleep 1
    done <<< "$machines"

    echo ""
    print_success "Stopped $count VMs"
}

# Function to delete all VMs
delete_all() {
    print_warning "This will delete all VMs!"
    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return 0
    fi

    print_info "Deleting all VMs..."
    echo ""

    local machines=$(get_machines)
    local count=0

    while IFS= read -r vm_name; do
        if [ -z "$vm_name" ]; then
            continue
        fi

        if delete_vm "$vm_name"; then
            ((count++))
        fi
    done <<< "$machines"

    echo ""
    print_success "Deleted $count VMs"
}

# Function to show help
show_help() {
    cat << EOF
${CYAN}Active Directory Training Machines Manager${NC}

${YELLOW}Usage:${NC}
    $0 [command] [options]

${YELLOW}Commands:${NC}
    create-all      Create all VMs
    start-all       Start all VMs
    stop-all        Stop all VMs
    status          Show status of all VMs
    delete-all      Delete all VMs
    start <vm>      Start specific VM
    stop <vm>       Stop specific VM
    delete <vm>     Delete specific VM
    help            Show this help message

${YELLOW}Options:${NC}
    --config FILE   Use alternative config file (default: machines_config.json)
    --base PATH     Use alternative base path (default: /mnt/vms)

${YELLOW}Examples:${NC}
    $0 create-all
    $0 start-all
    $0 status
    $0 stop AD-DC01
    $0 --config /path/to/config.json status

EOF
}

# Main function
main() {
    check_vboxmanage
    load_config

    local command="${1:-help}"

    case "$command" in
        create-all)
            create_all
            ;;
        start-all)
            start_all
            ;;
        stop-all)
            stop_all
            ;;
        status)
            show_status
            ;;
        delete-all)
            delete_all
            ;;
        start)
            if [ -z "${2:-}" ]; then
                print_error "VM name required"
                exit 1
            fi
            start_vm "$2"
            ;;
        stop)
            if [ -z "${2:-}" ]; then
                print_error "VM name required"
                exit 1
            fi
            stop_vm "$2"
            ;;
        delete)
            if [ -z "${2:-}" ]; then
                print_error "VM name required"
                exit 1
            fi
            delete_vm "$2"
            ;;
        --config)
            CONFIG_FILE="$2"
            main "${@:3}"
            ;;
        --base)
            VM_BASE_PATH="$2"
            main "${@:3}"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
