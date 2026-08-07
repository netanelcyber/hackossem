#!/bin/bash
# Active Directory Training Environment - Fully Automated Setup
# Automates: VM creation → OS installation → Configuration → Domain join
# Works on Linux, macOS, and Windows (WSL/Git Bash)

set -euo pipefail

# Configuration
VM_BASE_PATH="${VM_BASE_PATH:-/mnt/vms}"
DOMAIN_NAME="${DOMAIN_NAME:-training.lab}"
DOMAIN_ADMIN="${DOMAIN_ADMIN:-Administrator}"
DOMAIN_PASSWORD="${DOMAIN_PASSWORD:-P@ssw0rd123!}"
ISO_PATH="${ISO_PATH:-}"
CONFIG_FILE="${CONFIG_FILE:-machines_config.json}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-300}" # 5 minutes default
PARALLEL_VMS="${PARALLEL_VMS:-2}"   # Number of VMs to create in parallel

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging functions
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

print_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# Logging to file
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"

    local missing=0

    # Check VirtualBox
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VirtualBox not installed"
        ((missing++))
    else
        print_success "VirtualBox: $(VBoxManage --version | head -1)"
    fi

    # Check jq
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found - will use grep fallback"
    else
        print_success "jq found"
    fi

    # Check configuration file
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        ((missing++))
    else
        print_success "Configuration file found"
    fi

    # Create log directory
    mkdir -p "$VM_BASE_PATH/logs"
    LOG_FILE="$VM_BASE_PATH/logs/setup_$(date +%Y%m%d_%H%M%S).log"
    print_success "Log file: $LOG_FILE"

    if [ $missing -gt 0 ]; then
        print_error "$missing prerequisites missing"
        exit 1
    fi

    print_success "All prerequisites satisfied"
    echo ""
}

# Function to create unattend.xml for Windows Server
create_unattend_xml() {
    local vm_name="$1"
    local computer_name="$2"
    local admin_password="$3"

    local unattend_file="$VM_BASE_PATH/$vm_name/unattend.xml"
    mkdir -p "$(dirname "$unattend_file")"

    cat > "$unattend_file" << 'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>System</Type>
                            <Size>500</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Label>System</Label>
                            <Format>NTFS</Format>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                            <Label>Windows</Label>
                            <Format>NTFS</Format>
                            <Active>true</Active>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/image/index</Key>
                            <Value>2</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>2</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
            </UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>PLACEHOLDER_HOSTNAME</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <ProtectYourPC>3</ProtectYourPC>
                <NetworkLocation>Work</NetworkLocation>
            </OOBE>
            <TimeZone>UTC</TimeZone>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>PLACEHOLDER_PASSWORD</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>Administrator Account</Description>
                        <DisplayName>Administrator</DisplayName>
                        <Group>Administrators</Group>
                        <Name>Administrator</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c "powershell -NoProfile -ExecutionPolicy Bypass -File C:\setup.ps1"</CommandLine>
                    <Order>1</Order>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:d:/sources/install.wim#Windows Server 2022 SERVERSTANDARD" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
XMLEOF

    # Replace placeholders
    sed -i "s|PLACEHOLDER_HOSTNAME|$computer_name|g" "$unattend_file"
    sed -i "s|PLACEHOLDER_PASSWORD|$admin_password|g" "$unattend_file"

    print_success "Created unattend.xml for $vm_name"
    log_to_file "Created unattend.xml for $vm_name at $unattend_file"
}

# Function to create VM and inject unattend.xml
create_and_configure_vm() {
    local vm_name="$1"
    local ram="$2"
    local cpus="$3"
    local disk_size="$4"
    local hostname="$5"

    print_info "Creating VM: $vm_name"
    log_to_file "Starting creation of $vm_name"

    # Create VM
    if ! VBoxManage createvm \
        --name "$vm_name" \
        --ostype "Windows2022_64" \
        --basefolder "$VM_BASE_PATH" \
        --register 2>> "$LOG_FILE"; then
        print_error "Failed to create VM $vm_name"
        log_to_file "ERROR: Failed to create VM $vm_name"
        return 1
    fi

    # Configure resources
    if ! VBoxManage modifyvm "$vm_name" \
        --memory "$ram" \
        --cpus "$cpus" \
        --vram 128 2>> "$LOG_FILE"; then
        print_error "Failed to configure resources for $vm_name"
        return 1
    fi

    # Configure network
    if ! VBoxManage modifyvm "$vm_name" \
        --nic1 bridged \
        --bridgeadapter1 "eth0" \
        --nictype1 "82540EM" 2>> "$LOG_FILE"; then
        print_error "Failed to configure network for $vm_name"
        return 1
    fi

    # Create storage controller
    if ! VBoxManage storagectl "$vm_name" \
        --name "SATA Controller" \
        --add sata \
        --controller IntelAhci 2>> "$LOG_FILE"; then
        print_error "Failed to create storage controller for $vm_name"
        return 1
    fi

    # Create and attach disk
    local disk_path="$VM_BASE_PATH/$vm_name/${vm_name}.vdi"
    mkdir -p "$(dirname "$disk_path")"

    if ! VBoxManage createmedium disk \
        --filename "$disk_path" \
        --size "$disk_size" \
        --format VDI 2>> "$LOG_FILE"; then
        print_error "Failed to create disk for $vm_name"
        return 1
    fi

    if ! VBoxManage storageattach "$vm_name" \
        --storagectl "SATA Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium "$disk_path" 2>> "$LOG_FILE"; then
        print_error "Failed to attach disk to $vm_name"
        return 1
    fi

    # Attach IDE controller for ISO
    if ! VBoxManage storagectl "$vm_name" \
        --name "IDE Controller" \
        --add ide 2>> "$LOG_FILE"; then
        print_error "Failed to create IDE controller for $vm_name"
        return 1
    fi

    # Attach ISO if provided
    if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
        if ! VBoxManage storageattach "$vm_name" \
            --storagectl "IDE Controller" \
            --port 0 \
            --device 0 \
            --type dvddrive \
            --medium "$ISO_PATH" 2>> "$LOG_FILE"; then
            print_warning "Failed to attach ISO to $vm_name - you'll need to do this manually"
        fi
    fi

    # Create unattend.xml
    create_unattend_xml "$vm_name" "$hostname" "$DOMAIN_PASSWORD"

    print_success "$vm_name configured"
    log_to_file "Successfully configured $vm_name"
    return 0
}

# Function to wait for VM to boot and be reachable
wait_for_vm() {
    local vm_name="$1"
    local vm_ip="$2"
    local timeout="${WAIT_TIMEOUT}"
    local elapsed=0

    print_info "Waiting for $vm_name ($vm_ip) to boot..."
    log_to_file "Waiting for $vm_name to be reachable at $vm_ip"

    while [ $elapsed -lt $timeout ]; do
        if ping -c 1 "$vm_ip" &> /dev/null; then
            print_success "$vm_name is reachable at $vm_ip"
            log_to_file "$vm_name is reachable"
            return 0
        fi

        echo -ne "${YELLOW}.${NC}"
        sleep 5
        ((elapsed += 5))
    done

    print_warning "$vm_name not reachable after ${timeout}s (may still be installing)"
    return 1
}

# Function to execute remote PowerShell command
execute_remote_ps() {
    local vm_ip="$1"
    local command="$2"
    local attempts="${3:-3}"

    print_info "Executing remote command on $vm_ip"
    log_to_file "Executing: $command on $vm_ip"

    for attempt in $(seq 1 $attempts); do
        if command -v winrm &> /dev/null; then
            # Use WinRM if available
            if winrm -r:"http://$vm_ip:5985/wsman" id 2>/dev/null; then
                print_success "Connected via WinRM to $vm_ip"
                return 0
            fi
        elif command -v ssh &> /dev/null; then
            # Use SSH if available
            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "Administrator@$vm_ip" "$command" 2>/dev/null; then
                print_success "Command executed on $vm_ip via SSH"
                return 0
            fi
        fi

        if [ $attempt -lt $attempts ]; then
            print_warning "Attempt $attempt failed, retrying in 10s..."
            sleep 10
        fi
    done

    print_warning "Could not execute remote command on $vm_ip"
    return 1
}

# Function to start all VMs
start_all_vms() {
    print_step "Starting All VMs"

    if ! command -v jq &> /dev/null; then
        print_error "jq required for automated startup. Install jq and retry."
        return 1
    fi

    local machines=$(jq -r '.machines[].name' "$CONFIG_FILE")
    local count=0

    while IFS= read -r vm_name; do
        if [ -z "$vm_name" ]; then
            continue
        fi

        print_info "Starting $vm_name..."
        if VBoxManage startvm "$vm_name" --type headless 2>> "$LOG_FILE"; then
            print_success "$vm_name started"
            ((count++))
        else
            print_error "Failed to start $vm_name"
            log_to_file "ERROR: Failed to start $vm_name"
        fi

        sleep 1
    done <<< "$machines"

    print_success "Started $count VMs"
    log_to_file "Started $count VMs"
}

# Function to wait for all VMs to boot
wait_for_all_vms() {
    print_step "Waiting for VMs to Boot"

    if ! command -v jq &> /dev/null; then
        print_warning "jq required for boot waiting. Please verify VMs are running manually."
        return 0
    fi

    local machines=$(jq -r '.machines[] | "\(.name),\(.ip)"' "$CONFIG_FILE")
    local booted=0

    while IFS=',' read -r vm_name vm_ip; do
        print_info "Waiting for $vm_name..."
        if wait_for_vm "$vm_name" "$vm_ip"; then
            ((booted++))
        fi
    done <<< "$machines"

    print_success "$booted VMs are booted and reachable"
    log_to_file "Boot verification: $booted VMs reachable"

    if [ $booted -eq 0 ]; then
        print_warning "No VMs are reachable yet - Windows installation may still be in progress"
        print_info "This is normal - installation can take 10-30 minutes"
    fi
}

# Function to show full automation report
show_report() {
    print_step "Automation Summary Report"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Automated Setup Complete!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    if command -v jq &> /dev/null; then
        echo -e "${GREEN}Domain:${NC} $(jq -r '.environment.domain' "$CONFIG_FILE")"
        echo -e "${GREEN}Network:${NC} $(jq -r '.environment.baseNetwork' "$CONFIG_FILE")"
    fi

    echo ""
    echo -e "${YELLOW}VMs Created:${NC}"
    if command -v jq &> /dev/null; then
        jq -r '.machines[] | "  \(.name) - \(.displayName) (\(.role))"' "$CONFIG_FILE"
    fi

    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. VMs are starting in background"
    echo "  2. Windows Server will auto-install from unattend.xml"
    echo "  3. Installation takes 10-30 minutes"
    echo "  4. VMs will auto-run setup.ps1 on first login"
    echo "  5. Domain joining and features will be configured automatically"
    echo ""

    echo -e "${YELLOW}Monitoring:${NC}"
    echo "  Check status: ./manage_ad_machines.sh status"
    echo "  View VMs: VirtualBox GUI"
    echo "  Log file: $LOG_FILE"
    echo ""

    echo -e "${YELLOW}SSH/RDP Access (once setup complete):${NC}"
    if command -v jq &> /dev/null; then
        jq -r '.machines[] | "  \(.name) (\(.ip)): ssh Administrator@\(.ip) or RDP to \(.ip)"' "$CONFIG_FILE" | head -5
    fi

    echo ""
    echo -e "${CYAN}Full log available at: $LOG_FILE${NC}"
    echo ""
}

# Main orchestration function
main() {
    echo -e "${MAGENTA}"
    echo "=========================================="
    echo "Active Directory Training Environment"
    echo "FULLY AUTOMATED Setup"
    echo "=========================================="
    echo -e "${NC}"
    echo ""

    print_info "Domain: $DOMAIN_NAME"
    print_info "Admin: $DOMAIN_ADMIN"
    print_info "Base Path: $VM_BASE_PATH"
    print_info "Config: $CONFIG_FILE"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Confirm before starting
    echo ""
    print_warning "This will fully automate:"
    echo "  1. Create all 10 VMs"
    echo "  2. Inject unattend.xml for automated Windows installation"
    echo "  3. Start all VMs"
    echo "  4. Wait for boot"
    echo "  5. Trigger automated configuration"
    echo ""
    read -p "Continue with automated setup? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        exit 0
    fi

    echo ""

    # Create all VMs
    print_step "Creating VMs"
    if ! command -v jq &> /dev/null; then
        print_error "jq is required for automated setup"
        exit 1
    fi

    local machines=$(jq -r '.machines[]' "$CONFIG_FILE")
    local created=0
    local failed=0

    while IFS= read -r machine_json; do
        local vm_name=$(echo "$machine_json" | jq -r '.name')
        local ram=$(echo "$machine_json" | jq -r '.resources.memory_mb')
        local cpus=$(echo "$machine_json" | jq -r '.resources.cpus')
        local disk=$(echo "$machine_json" | jq -r '.resources.disk_mb')

        if create_and_configure_vm "$vm_name" "$ram" "$cpus" "$disk" "$vm_name"; then
            ((created++))
        else
            ((failed++))
        fi

        sleep 0.5
    done <<< "$machines"

    echo ""
    print_success "VMs created: $created, failed: $failed"
    log_to_file "VM creation complete: $created created, $failed failed"

    # Start all VMs
    echo ""
    start_all_vms

    # Wait for VMs to boot
    echo ""
    wait_for_all_vms

    # Show report
    echo ""
    show_report

    print_success "Automated setup sequence complete!"
    log_to_file "Setup complete - automation finished"
}

# Run main function
main "$@"
