#!/bin/bash
##############################################################################
# GOAD VirtualBox: VM Creation Script
# Creates VirtualBox VMs for GOAD (full or light variant)
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOAD_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$GOAD_DIR/logs/create-vms.log"
mkdir -p "$(dirname "$LOG_FILE")"

VARIANT="full"
ISO_2016=""
ISO_2019=""
DISK_PATH="${HOME}/VirtualBox VMs"
NETWORK="goad-internal"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --iso-2016)
      ISO_2016="$2"
      shift 2
      ;;
    --iso-2019)
      ISO_2019="$2"
      shift 2
      ;;
    --disk-path)
      DISK_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "GOAD VirtualBox VM Creation" | tee "$LOG_FILE"
echo "===========================" | tee -a "$LOG_FILE"
echo "Variant: $VARIANT" | tee -a "$LOG_FILE"
echo

# Validate inputs
if [[ "$VARIANT" != "full" && "$VARIANT" != "light" ]]; then
  echo -e "${RED}Error: variant must be 'full' or 'light'${NC}"
  exit 1
fi

# Define VMs based on variant
declare -A vms_os
declare -A vms_ram
declare -A vms_cpu
declare -A vms_disk
declare -A vms_ip

if [[ "$VARIANT" == "full" ]]; then
  vms_os[dc01]="Windows2016_64"
  vms_os[dc02]="Windows2016_64"
  vms_os[srv02]="Windows2019_64"
  vms_os[srv03]="Windows2019_64"
  vms_os[ws01]="Windows10_64"

  for vm in dc01 dc02 srv02 srv03; do
    vms_ram[$vm]=2048
    vms_cpu[$vm]=2
  done
  vms_ram[ws01]=2048
  vms_cpu[ws01]=2

  vms_disk[dc01]=60
  vms_disk[dc02]=60
  vms_disk[srv02]=60
  vms_disk[srv03]=60
  vms_disk[ws01]=40

  vms_ip[dc01]="192.168.1.11"
  vms_ip[dc02]="192.168.1.12"
  vms_ip[srv02]="192.168.1.22"
  vms_ip[srv03]="192.168.1.23"
  vms_ip[ws01]="192.168.1.30"
else
  vms_os[dc01]="Windows2016_64"
  vms_os[srv02]="Windows2019_64"
  vms_os[ws01]="Windows10_64"

  for vm in dc01 srv02 ws01; do
    vms_ram[$vm]=2048
    vms_cpu[$vm]=2
  done

  vms_disk[dc01]=60
  vms_disk[srv02]=60
  vms_disk[ws01]=40

  vms_ip[dc01]="192.168.1.11"
  vms_ip[srv02]="192.168.1.22"
  vms_ip[ws01]="192.168.1.30"
fi

# Function to create a single VM
create_vm() {
  local vm_name=$1
  local os_type=$2
  local ram=$3
  local cpu=$4
  local disk_size=$5

  echo "Creating VM: $vm_name" | tee -a "$LOG_FILE"

  # Check if VM already exists
  if VBoxManage list vms | grep -q "\"$vm_name\""; then
    echo "  WARNING: VM already exists. Skipping." | tee -a "$LOG_FILE"
    return
  fi

  # Create VM
  VBoxManage createvm --name "$vm_name" --ostype "$os_type" --register 2>&1 | tee -a "$LOG_FILE"

  # Create disk
  local disk_path_full="$DISK_PATH/$vm_name/${vm_name}.vdi"
  mkdir -p "$(dirname "$disk_path_full")"

  VBoxManage createmedium disk --filename "$disk_path_full" --size $(($disk_size * 1024)) 2>&1 | tee -a "$LOG_FILE"

  # Create storage controller
  VBoxManage storagectl "$vm_name" --name "SATA" --add sata --controller IntelAHCI 2>&1 | tee -a "$LOG_FILE"

  # Attach disk
  VBoxManage storageattach "$vm_name" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$disk_path_full" 2>&1 | tee -a "$LOG_FILE"

  # Attach ISO (if available)
  if [[ "$os_type" == "Windows2016_64" && -n "$ISO_2016" && -f "$ISO_2016" ]]; then
    VBoxManage storageattach "$vm_name" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO_2016" 2>&1 | tee -a "$LOG_FILE"
  elif [[ "$os_type" == "Windows2019_64" && -n "$ISO_2019" && -f "$ISO_2019" ]]; then
    VBoxManage storageattach "$vm_name" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO_2019" 2>&1 | tee -a "$LOG_FILE"
  elif [[ "$os_type" == "Windows10_64" ]]; then
    # For workstations, use 2019 ISO if available (Windows 10 boot environment)
    if [[ -n "$ISO_2019" && -f "$ISO_2019" ]]; then
      VBoxManage storageattach "$vm_name" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO_2019" 2>&1 | tee -a "$LOG_FILE"
    fi
  fi

  # Configure VM
  VBoxManage modifyvm "$vm_name" --memory "$ram" --cpus "$cpu" 2>&1 | tee -a "$LOG_FILE"
  VBoxManage modifyvm "$vm_name" --vram 32 --accelerate3d off 2>&1 | tee -a "$LOG_FILE"
  VBoxManage modifyvm "$vm_name" --clipboard bidirectional 2>&1 | tee -a "$LOG_FILE"

  # Add network interface
  VBoxManage modifyvm "$vm_name" --nic1 intnet --intnet1 "$NETWORK" 2>&1 | tee -a "$LOG_FILE"

  # Set boot order
  VBoxManage modifyvm "$vm_name" --boot1 dvd --boot2 disk --boot3 none --boot4 none 2>&1 | tee -a "$LOG_FILE"

  # Enable RDP
  VBoxManage modifyvm "$vm_name" --vrde on --vrdeport 3389 2>&1 | tee -a "$LOG_FILE"

  echo -e "${GREEN}✓ VM created: $vm_name${NC}" | tee -a "$LOG_FILE"
}

# Create all VMs
echo "Creating VMs for GOAD-$VARIANT..." | tee -a "$LOG_FILE"
echo

for vm_name in "${!vms_os[@]}"; do
  create_vm "$vm_name" "${vms_os[$vm_name]}" "${vms_ram[$vm_name]}" "${vms_cpu[$vm_name]}" "${vms_disk[$vm_name]}"
done

echo
echo "VirtualBox VM List:" | tee -a "$LOG_FILE"
VBoxManage list vms | tee -a "$LOG_FILE"

echo
echo "=== Next Steps ===" | tee -a "$LOG_FILE"
echo "1. Start each VM with: VBoxManage startvm <vm_name> --type gui" | tee -a "$LOG_FILE"
echo "2. Install Windows Server/10 on each VM" | tee -a "$LOG_FILE"
echo "3. Set static IPs:" | tee -a "$LOG_FILE"
for vm_name in "${!vms_ip[@]}"; do
  echo "   $vm_name: ${vms_ip[$vm_name]}" | tee -a "$LOG_FILE"
done
echo "4. Enable WinRM on each VM (see docs/04-WINRM-SETUP.md)" | tee -a "$LOG_FILE"
echo "5. Run: bash scripts/apply-provisioning.sh" | tee -a "$LOG_FILE"

echo
echo -e "${GREEN}✓ VM creation complete${NC}" | tee -a "$LOG_FILE"
