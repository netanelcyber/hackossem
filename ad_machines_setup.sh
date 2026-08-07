#!/bin/bash
# Active Directory Training Machines - VirtualBox Setup Script (Bash)
# Creates 10 training VMs joined to the same domain
# Works on Linux, macOS, and Windows (WSL/Git Bash)

set -euo pipefail

# Configuration
VM_BASE_PATH="${VM_BASE_PATH:-/mnt/vms}"
DOMAIN_NAME="${DOMAIN_NAME:-training.lab}"
DOMAIN_ADMIN="${DOMAIN_ADMIN:-Administrator}"
DOMAIN_PASSWORD="${DOMAIN_PASSWORD:-P@ssw0rd123!}"
BASE_IMAGE_PATH="${BASE_IMAGE_PATH:-/mnt/iso/windows-server-2022.iso}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arrays for machine configuration
declare -a VM_NAMES=("AD-DC01" "AD-WS01" "AD-WS02" "AD-SRV01" "AD-SRV02" "AD-WS03" "AD-WS04" "AD-SQL01" "AD-MAIL01" "AD-WEB01")
declare -a VM_IPS=("192.168.100.10" "192.168.100.20" "192.168.100.21" "192.168.100.30" "192.168.100.31" "192.168.100.22" "192.168.100.23" "192.168.100.40" "192.168.100.50" "192.168.100.60")
declare -a VM_ROLES=("DomainController" "Workstation" "Workstation" "FileServer" "FileServer" "Workstation" "Workstation" "SQLServer" "MailServer" "WebServer")
declare -a VM_MEMORY=("2048" "2048" "2048" "2048" "2048" "2048" "2048" "4096" "3072" "2048")
declare -a VM_CPUS=("2" "2" "2" "2" "2" "2" "2" "4" "3" "2")
declare -a VM_DISK=("51200" "40960" "40960" "102400" "102400" "40960" "40960" "102400" "102400" "51200")

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
    print_success "VirtualBox found: $(VBoxManage --version)"
}

# Function to create VirtualBox VM
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
        --register

    # Configure VM resources
    VBoxManage modifyvm "$vm_name" \
        --memory "$ram" \
        --cpus "$cpus" \
        --vram 128 \
        --accelerate3d off

    # Configure network
    VBoxManage modifyvm "$vm_name" \
        --nic1 bridged \
        --bridgeadapter1 "eth0" \
        --nictype1 "82540EM"

    # Create storage controller
    VBoxManage storagectl "$vm_name" \
        --name "SATA Controller" \
        --add sata \
        --controller IntelAhci

    # Create and attach disk
    local disk_path="$VM_BASE_PATH/$vm_name/${vm_name}.vdi"
    mkdir -p "$(dirname "$disk_path")"

    VBoxManage createmedium disk \
        --filename "$disk_path" \
        --size "$disk_size" \
        --format VDI

    # Attach disk to controller
    VBoxManage storageattach "$vm_name" \
        --storagectl "SATA Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium "$disk_path"

    # Attach IDE controller for ISO
    VBoxManage storagectl "$vm_name" \
        --name "IDE Controller" \
        --add ide

    # Attach ISO if it exists
    if [ -f "$BASE_IMAGE_PATH" ]; then
        VBoxManage storageattach "$vm_name" \
            --storagectl "IDE Controller" \
            --port 0 \
            --device 0 \
            --type dvddrive \
            --medium "$BASE_IMAGE_PATH"
    fi

    print_success "VM $vm_name created successfully"
}

# Function to create post-installation configuration script
create_setup_script() {
    local vm_name="$1"
    local vm_ip="$2"
    local vm_role="$3"
    local script_path="$VM_BASE_PATH/$vm_name/setup.ps1"

    mkdir -p "$(dirname "$script_path")"

    cat > "$script_path" << 'PSSCRIPT'
# Post-installation configuration script
# This script is executed inside the VM after Windows installation

$IPv4Address = '$IP_ADDRESS'
$Gateway = '192.168.100.1'
$DNS = '192.168.100.10'
$DomainName = '$DOMAIN_NAME'
$DomainAdmin = '$DOMAIN_ADMIN'
$DomainPassword = '$DOMAIN_PASSWORD'
$VMRole = '$VM_ROLE'

# Set static IP
$InterfaceIndex = (Get-NetAdapter)[0].InterfaceIndex
New-NetIPAddress -IPAddress $IPv4Address -PrefixLength 24 `
    -DefaultGateway $Gateway -InterfaceIndex $InterfaceIndex `
    -ErrorAction SilentlyContinue

# Set DNS
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex `
    -ServerAddresses $DNS -ErrorAction SilentlyContinue

# Rename computer
Rename-Computer -NewName '$VM_NAME' -Force -ErrorAction SilentlyContinue

# Configure by role
switch ($VMRole) {
    'DomainController' {
        Write-Host "Configuring Domain Controller..."
        Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

        $SafeModePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
        Install-ADDSForest -DomainName $DomainName `
            -SafeModeAdministratorPassword $SafeModePassword -Force
    }

    'Workstation' {
        Write-Host "Configuring Workstation..."
        $Credential = New-Object System.Management.Automation.PSCredential(
            "$DomainName\$DomainAdmin",
            (ConvertTo-SecureString $DomainPassword -AsPlainText -Force)
        )
        Add-Computer -DomainName $DomainName -Credential $Credential -Force
    }

    'FileServer' {
        Write-Host "Configuring File Server..."
        Install-WindowsFeature File-Services, FS-FileServer -IncludeManagementTools

        $Credential = New-Object System.Management.Automation.PSCredential(
            "$DomainName\$DomainAdmin",
            (ConvertTo-SecureString $DomainPassword -AsPlainText -Force)
        )
        Add-Computer -DomainName $DomainName -Credential $Credential -Force
    }

    'SQLServer' {
        Write-Host "Configuring SQL Server..."
        Install-WindowsFeature NET-Framework-45-Core -IncludeManagementTools

        $Credential = New-Object System.Management.Automation.PSCredential(
            "$DomainName\$DomainAdmin",
            (ConvertTo-SecureString $DomainPassword -AsPlainText -Force)
        )
        Add-Computer -DomainName $DomainName -Credential $Credential -Force
    }

    'MailServer' {
        Write-Host "Configuring Mail Server..."
        Install-WindowsFeature RSAT-AD-Tools -IncludeManagementTools

        $Credential = New-Object System.Management.Automation.PSCredential(
            "$DomainName\$DomainAdmin",
            (ConvertTo-SecureString $DomainPassword -AsPlainText -Force)
        )
        Add-Computer -DomainName $DomainName -Credential $Credential -Force
    }

    'WebServer' {
        Write-Host "Configuring Web Server..."
        Install-WindowsFeature Web-Server, Web-Asp-Net45 -IncludeManagementTools

        $Credential = New-Object System.Management.Automation.PSCredential(
            "$DomainName\$DomainAdmin",
            (ConvertTo-SecureString $DomainPassword -AsPlainText -Force)
        )
        Add-Computer -DomainName $DomainName -Credential $Credential -Force
    }
}

Write-Host "Configuration complete. Restarting..."
Restart-Computer -Force
PSSCRIPT

    # Replace variables in the script
    sed -i "s|\$IP_ADDRESS|$vm_ip|g" "$script_path"
    sed -i "s|\$DOMAIN_NAME|$DOMAIN_NAME|g" "$script_path"
    sed -i "s|\$DOMAIN_ADMIN|$DOMAIN_ADMIN|g" "$script_path"
    sed -i "s|\$DOMAIN_PASSWORD|$DOMAIN_PASSWORD|g" "$script_path"
    sed -i "s|\$VM_NAME|$vm_name|g" "$script_path"
    sed -i "s|\$VM_ROLE|$vm_role|g" "$script_path"

    print_success "Setup script created: $script_path"
}

# Main execution
main() {
    echo -e "${CYAN}"
    echo "=========================================="
    echo "Active Directory Training Environment"
    echo "VirtualBox Setup Script"
    echo "=========================================="
    echo -e "${NC}"

    print_info "Domain: $DOMAIN_NAME"
    print_info "Base Path: $VM_BASE_PATH"
    print_info "Machines to create: ${#VM_NAMES[@]}"
    echo ""

    # Check prerequisites
    check_vboxmanage

    # Create base directory
    if [ ! -d "$VM_BASE_PATH" ]; then
        print_info "Creating base directory: $VM_BASE_PATH"
        mkdir -p "$VM_BASE_PATH"
    fi

    echo ""

    # Create each VM
    for i in "${!VM_NAMES[@]}"; do
        vm_name="${VM_NAMES[$i]}"
        vm_ip="${VM_IPS[$i]}"
        vm_role="${VM_ROLES[$i]}"
        vm_memory="${VM_MEMORY[$i]}"
        vm_cpus="${VM_CPUS[$i]}"
        vm_disk="${VM_DISK[$i]}"

        create_vm "$vm_name" "$vm_memory" "$vm_cpus" "$vm_disk"
        create_setup_script "$vm_name" "$vm_ip" "$vm_role"
        echo ""
    done

    echo -e "${GREEN}"
    echo "=========================================="
    echo "✓ Setup Complete!"
    echo "=========================================="
    echo -e "${NC}"
    echo ""
    print_info "Next steps:"
    echo "  1. Start each VM in VirtualBox"
    echo "  2. Complete Windows Server installation"
    echo "  3. Run the generated setup.ps1 script from inside the VM"
    echo "  4. VMs will automatically join the domain"
    echo ""
}

# Run main function
main "$@"
