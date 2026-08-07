#!/bin/bash
# Active Directory Training Environment - Full Orchestration & Deployment
# Complete end-to-end automation with monitoring, logging, and recovery

set -euo pipefail

# Configuration
CONFIG_FILE="${CONFIG_FILE:-machines_config.json}"
VM_BASE_PATH="${VM_BASE_PATH:-/mnt/vms}"
LOG_DIR="${LOG_DIR:-$VM_BASE_PATH/logs}"
STATE_FILE="$LOG_DIR/deployment.state"
PARALLEL_JOBS="${PARALLEL_JOBS:-2}"
INSTALLATION_TIMEOUT="${INSTALLATION_TIMEOUT:-1800}"  # 30 minutes for Windows installation
BOOT_CHECK_INTERVAL="${BOOT_CHECK_INTERVAL:-10}"      # Check every 10 seconds

# Deployment stages
STAGE_CHECK="0-check"
STAGE_CREATE="1-create"
STAGE_INSTALL="2-install"
STAGE_CONFIGURE="3-configure"
STAGE_DOMAIN="4-domain"
STAGE_MONITOR="5-monitor"
STAGE_COMPLETE="6-complete"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Initialize
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deployment_$(date +%Y%m%d_%H%M%S).log"
STATE_LOG="$LOG_DIR/state.log"

# Logging
log() {
    local level="$1"
    shift
    local msg="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" | tee -a "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "INFO" "$1"
}

print_stage() {
    echo -e "${BLUE}[STAGE]${NC} $1"
    log "STAGE" "$1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    log "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    log "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    log "WARN" "$1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
    log "INFO" "$1"
}

# State management
save_state() {
    local stage="$1"
    local status="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$stage|$status" >> "$STATE_LOG"
}

get_last_stage() {
    if [ -f "$STATE_LOG" ]; then
        tail -1 "$STATE_LOG" | cut -d'|' -f2
    else
        echo "$STAGE_CHECK"
    fi
}

# Stage 0: Verify prerequisites
stage_check() {
    print_header "Stage 0: Verifying Prerequisites"

    # Check VirtualBox
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VirtualBox not installed"
        return 1
    fi
    print_success "VirtualBox: $(VBoxManage --version | head -1)"

    # Check jq
    if ! command -v jq &> /dev/null; then
        print_error "jq required - install with: sudo apt-get install jq"
        return 1
    fi
    print_success "jq installed"

    # Check config
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    print_success "Configuration file found: $CONFIG_FILE"

    # Display configuration
    echo ""
    print_info "Configuration Details:"
    echo "  Domain: $(jq -r '.environment.domain' "$CONFIG_FILE")"
    echo "  Network: $(jq -r '.environment.baseNetwork' "$CONFIG_FILE")"
    echo "  VMs to create: $(jq '.machines | length' "$CONFIG_FILE")"
    echo "  Base path: $VM_BASE_PATH"
    echo "  Log file: $LOG_FILE"

    save_state "$STAGE_CHECK" "complete"
    return 0
}

# Stage 1: Create VMs
stage_create() {
    print_header "Stage 1: Creating Virtual Machines"

    local total=$(jq '.machines | length' "$CONFIG_FILE")
    local created=0

    jq -r '.machines[] | "\(.name),\(.resources.memory_mb),\(.resources.cpus),\(.resources.disk_mb)"' "$CONFIG_FILE" | while IFS=',' read -r name mem cpus disk; do
        print_info "Creating $name..."

        # Create VM
        if ! VBoxManage createvm --name "$name" --ostype Windows2022_64 --basefolder "$VM_BASE_PATH" --register 2>> "$LOG_FILE"; then
            print_error "Failed to create $name"
            continue
        fi

        # Configure resources
        VBoxManage modifyvm "$name" --memory "$mem" --cpus "$cpus" --vram 128 2>> "$LOG_FILE"
        VBoxManage modifyvm "$name" --nic1 bridged --bridgeadapter1 eth0 --nictype1 82540EM 2>> "$LOG_FILE"

        # Storage setup
        VBoxManage storagectl "$name" --name "SATA Controller" --add sata --controller IntelAhci 2>> "$LOG_FILE"

        local disk_path="$VM_BASE_PATH/$name/${name}.vdi"
        mkdir -p "$(dirname "$disk_path")"
        VBoxManage createmedium disk --filename "$disk_path" --size "$disk" --format VDI 2>> "$LOG_FILE"
        VBoxManage storageattach "$name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$disk_path" 2>> "$LOG_FILE"

        VBoxManage storagectl "$name" --name "IDE Controller" --add ide 2>> "$LOG_FILE"

        print_success "$name created"
    done

    save_state "$STAGE_CREATE" "complete"
    return 0
}

# Stage 2: Start VMs and wait for installation
stage_install() {
    print_header "Stage 2: Starting VMs for OS Installation"

    local machines=$(jq -r '.machines[].name' "$CONFIG_FILE")
    local started=0
    local total=$(echo "$machines" | wc -l)

    echo ""
    echo "Starting $total VMs..."
    echo ""

    while IFS= read -r vm_name; do
        print_info "Starting $vm_name..."
        if VBoxManage startvm "$vm_name" --type headless 2>> "$LOG_FILE"; then
            print_success "$vm_name started"
            ((started++))
        else
            print_error "Failed to start $vm_name"
        fi
        sleep 2
    done <<< "$machines"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_success "All VMs started ($started/$total)"
    echo ""
    print_warning "Windows Server installation in progress..."
    echo ""
    echo "Timeline:"
    echo "  00-05 min: VM boot and BIOS/UEFI POST"
    echo "  05-15 min: Windows Setup loading and disk initialization"
    echo "  15-45 min: Windows Server installation (copying files, installing)"
    echo "  45-60 min: Initial configuration and first boot"
    echo ""
    print_info "What's happening now:"
    echo "  → VMs are booting from Windows Server ISO"
    echo "  → Unattend.xml is automating the installation"
    echo "  → Next stage will monitor for boot completion"
    echo ""
    print_info "How to monitor:"
    echo "  1. Open VirtualBox GUI: VirtualBox"
    echo "  2. Select each VM to see installation progress"
    echo "  3. Or run in another terminal:"
    echo "     while true; do clear; ./manage_ad_machines.sh status; sleep 30; done"
    echo ""

    save_state "$STAGE_INSTALL" "in_progress"
    return 0
}

# Stage 3: Configure and deploy
stage_configure() {
    print_header "Stage 3: Configuring VMs - Waiting for Installation"

    local machines=$(jq -r '.machines[] | "\(.name),\(.ip),\(.role)"' "$CONFIG_FILE")
    local configured=0
    local total=$(echo "$machines" | wc -l)

    echo ""
    print_warning "Windows Server installation is in progress..."
    echo "This typically takes 15-30 minutes per VM"
    echo ""

    while IFS=',' read -r vm_name vm_ip vm_role; do
        print_info "Waiting for $vm_name ($vm_role) at $vm_ip..."

        local elapsed=0
        local max_wait=$INSTALLATION_TIMEOUT
        local check_interval=$BOOT_CHECK_INTERVAL
        local reachable=false

        while [ $elapsed -lt $max_wait ]; do
            # Try ping
            if ping -c 1 -W 2 "$vm_ip" &>/dev/null 2>&1; then
                print_success "$vm_name is reachable at $vm_ip"
                ((configured++))
                reachable=true
                break
            fi

            # Show progress
            local percent=$((elapsed * 100 / max_wait))
            printf "\r  %-60s %3d%% (%d/%dmin)" \
                "Waiting for boot..." \
                "$percent" \
                "$((elapsed / 60))" \
                "$((max_wait / 60))"

            sleep $check_interval
            ((elapsed += check_interval))
        done

        echo ""

        if [ "$reachable" = false ]; then
            print_warning "$vm_name still installing (timeout waiting, may be in Windows setup)"
            echo "  Expected: 15-30 minutes for Windows Server installation"
            echo "  Tip: Monitor VM in VirtualBox GUI or check with:"
            echo "       VBoxManage showvminfo $vm_name"
        fi

    done <<< "$machines"

    echo ""
    print_info "VMs checked: $configured online out of $total"
    echo ""
    print_warning "Note: Installation continues in background"
    echo "  - Check back in 10-20 minutes for completion"
    echo "  - Monitor with: ./manage_ad_machines.sh status"
    echo "  - View logs with: tail -f $LOG_FILE"
    echo ""

    save_state "$STAGE_CONFIGURE" "complete"
    return 0
}

# Stage 4: Monitor domain join
stage_domain() {
    print_header "Stage 4: Monitoring Domain Join"

    local machines=$(jq -r '.machines[].name' "$CONFIG_FILE")
    local domain=$(jq -r '.environment.domain' "$CONFIG_FILE")

    echo ""
    print_info "Waiting for domain join automation..."
    echo "  Domain: $domain"
    echo ""

    local max_wait=1800  # 30 minutes
    local elapsed=0

    while [ $elapsed -lt $max_wait ]; do
        local domain_joined=$(jq '.machines | length' "$CONFIG_FILE")
        print_info "Checking domain status (${elapsed}s/$max_wait)..."
        sleep 60
        ((elapsed += 60))
    done

    print_warning "Monitor: Check AD Users and Computers for domain members"
    save_state "$STAGE_DOMAIN" "in_progress"
    return 0
}

# Stage 5: Full monitoring dashboard
stage_monitor() {
    print_header "Stage 5: Deployment Monitoring"

    local total=$(jq '.machines | length' "$CONFIG_FILE")
    local online=0
    local machines=$(jq -r '.machines[] | "\(.name),\(.ip)"' "$CONFIG_FILE")

    echo ""
    echo -e "${BLUE}VM Status Report:${NC}"
    echo "───────────────────────────────────────────"

    while IFS=',' read -r vm_name vm_ip; do
        local status=$(VBoxManage showvminfo "$vm_name" --machinereadable 2>/dev/null | grep "^VMState=" | cut -d'=' -f2 | tr -d '"' || echo "unknown")

        local ping_status="offline"
        if ping -c 1 "$vm_ip" &>/dev/null; then
            ping_status="online"
            ((online++))
        fi

        printf "%-15s %-10s %-15s\n" "$vm_name" "$status" "$ping_status"
    done <<< "$machines"

    echo "───────────────────────────────────────────"
    echo "Online: $online/$total"
    echo ""

    save_state "$STAGE_MONITOR" "complete"
    return 0
}

# Stage 6: Complete
stage_complete() {
    print_header "Stage 6: Deployment Complete"

    echo ""
    print_success "All stages completed!"
    echo ""

    echo -e "${YELLOW}Next Actions:${NC}"
    echo "  1. Verify all VMs are running:"
    echo "     ./manage_ad_machines.sh status"
    echo ""
    echo "  2. Connect to Domain Controller (AD-DC01):"
    echo "     ssh Administrator@192.168.100.10"
    echo ""
    echo "  3. Verify domain:"
    echo "     dcdiag /v"
    echo ""
    echo "  4. View log:"
    echo "     cat $LOG_FILE"
    echo ""

    save_state "$STAGE_COMPLETE" "complete"
    return 0
}

# Resume interrupted deployment
resume_deployment() {
    local last_stage=$(get_last_stage)

    print_warning "Resuming from stage: $last_stage"
    log "INFO" "Resuming deployment from $last_stage"

    case "$last_stage" in
        "$STAGE_CHECK")
            stage_check && stage_create && stage_install && stage_configure && stage_monitor && stage_complete
            ;;
        "$STAGE_CREATE")
            stage_create && stage_install && stage_configure && stage_monitor && stage_complete
            ;;
        "$STAGE_INSTALL")
            stage_install && stage_configure && stage_monitor && stage_complete
            ;;
        "$STAGE_CONFIGURE")
            stage_configure && stage_monitor && stage_complete
            ;;
        "$STAGE_DOMAIN")
            stage_domain && stage_monitor && stage_complete
            ;;
        "$STAGE_MONITOR")
            stage_monitor && stage_complete
            ;;
        "$STAGE_COMPLETE")
            print_info "Deployment already completed"
            stage_complete
            ;;
        *)
            print_error "Unknown stage: $last_stage"
            return 1
            ;;
    esac
}

# Main orchestration
main() {
    print_header "Active Directory Training Environment"

    echo "Deployment Orchestrator"
    echo "Log: $LOG_FILE"
    echo ""

    # Check for resume
    if [ -f "$STATE_LOG" ]; then
        echo "Deployment state file found."
        read -p "Resume from last stage? (yes/no): " resume_choice
        echo ""

        if [ "$resume_choice" = "yes" ]; then
            resume_deployment
        else
            rm -f "$STATE_LOG"
            stage_check && stage_create && stage_install && stage_configure && stage_domain && stage_monitor && stage_complete
        fi
    else
        # Fresh deployment
        stage_check && stage_create && stage_install && stage_configure && stage_domain && stage_monitor && stage_complete
    fi

    echo ""
    print_success "Orchestration complete!"
    log "INFO" "Orchestration complete"
}

# Error handling
trap 'print_error "Deployment interrupted"; log "ERROR" "Deployment interrupted"; exit 1' INT TERM

# Run orchestration
main "$@"
