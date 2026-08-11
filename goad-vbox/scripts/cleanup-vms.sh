#!/bin/bash
##############################################################################
# GOAD VirtualBox: Cleanup Script
# Removes all GOAD VMs and their storage
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/cleanup.log"
mkdir -p "$(dirname "$LOG_FILE")"

VARIANT="full"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${RED}GOAD VirtualBox Cleanup${NC}" | tee "$LOG_FILE"
echo "========================" | tee -a "$LOG_FILE"

# Define VMs based on variant
if [[ "$VARIANT" == "full" ]]; then
  VMS=(dc01 dc02 srv02 srv03 ws01)
else
  VMS=(dc01 srv02 ws01)
fi

# Show what will be deleted
echo
echo "This will DELETE the following VMs and all their data:" | tee -a "$LOG_FILE"
for vm in "${VMS[@]}"; do
  echo "  - $vm" | tee -a "$LOG_FILE"
done

echo
if [[ "$FORCE" != "true" ]]; then
  echo -ne "Are you sure? (type 'yes' to confirm): "
  read -r confirmation

  if [[ "$confirmation" != "yes" ]]; then
    echo "Aborted." | tee -a "$LOG_FILE"
    exit 0
  fi
fi

echo
echo "Cleaning up..." | tee -a "$LOG_FILE"

for vm in "${VMS[@]}"; do
  echo "Removing VM: $vm" | tee -a "$LOG_FILE"

  # Stop VM if running
  if VBoxManage list runningvms | grep -q "\"$vm\""; then
    echo "  Stopping VM..." | tee -a "$LOG_FILE"
    VBoxManage controlvm "$vm" poweroff 2>&1 | tee -a "$LOG_FILE" || true
    sleep 2
  fi

  # Unregister VM and delete files
  if VBoxManage list vms | grep -q "\"$vm\""; then
    echo "  Unregistering and deleting VM..." | tee -a "$LOG_FILE"
    VBoxManage unregistervm "$vm" --delete 2>&1 | tee -a "$LOG_FILE"
  fi

  echo -e "${GREEN}✓ Removed: $vm${NC}" | tee -a "$LOG_FILE"
done

echo
echo -e "${GREEN}✓ Cleanup complete${NC}" | tee -a "$LOG_FILE"
