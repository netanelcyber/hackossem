#!/bin/bash
##############################################################################
# GOAD VirtualBox: Apply Provisioning
# Runs Ansible playbooks to configure the AD lab
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOAD_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$GOAD_DIR/logs/provision.log"
mkdir -p "$(dirname "$LOG_FILE")"

INVENTORY_FILE=""
VARIANT="full"
VERBOSITY="-v"
DRY_RUN=false

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --inventory)
      INVENTORY_FILE="$2"
      shift 2
      ;;
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --verbose)
      VERBOSITY="-vvv"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set default inventory
if [[ -z "$INVENTORY_FILE" ]]; then
  INVENTORY_FILE="$GOAD_DIR/inventory/hosts.ini"
fi

echo "GOAD VirtualBox Provisioning" | tee "$LOG_FILE"
echo "============================" | tee -a "$LOG_FILE"
echo "Inventory: $INVENTORY_FILE" | tee -a "$LOG_FILE"
echo "Variant: $VARIANT" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo

# Verify inventory exists
if [[ ! -f "$INVENTORY_FILE" ]]; then
  echo -e "${RED}Error: Inventory file not found: $INVENTORY_FILE${NC}"
  exit 1
fi

# Verify Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
  echo -e "${RED}Error: Ansible not installed${NC}"
  exit 1
fi

echo "Testing connectivity..." | tee -a "$LOG_FILE"
if ! ansible -i "$INVENTORY_FILE" windows -m win_ping &>/dev/null; then
  echo -e "${RED}Error: Cannot connect to VMs via WinRM${NC}"
  echo "Run: ansible -i $INVENTORY_FILE windows -m win_ping -vvv" | tee -a "$LOG_FILE"
  exit 1
fi
echo -e "${GREEN}✓ Connectivity OK${NC}" | tee -a "$LOG_FILE"
echo

# Define playbooks to run
declare -a PLAYBOOKS=(
  "0-preflight.yml"
  "1-domain-setup.yml"
  "2-users-groups.yml"
  "3-gpo-policies.yml"
  "4-services.yml"
  "5-misconfigs.yml"
)

# Run playbooks
run_count=0
fail_count=0

for playbook in "${PLAYBOOKS[@]}"; do
  playbook_path="$GOAD_DIR/playbooks/$playbook"

  # Skip if playbook doesn't exist
  if [[ ! -f "$playbook_path" ]]; then
    echo -e "${YELLOW}⚠ Playbook not found: $playbook (skipping)${NC}" | tee -a "$LOG_FILE"
    continue
  fi

  echo
  echo "================================================" | tee -a "$LOG_FILE"
  echo "Running playbook: $playbook" | tee -a "$LOG_FILE"
  echo "================================================" | tee -a "$LOG_FILE"

  # Build ansible-playbook command
  local cmd="ansible-playbook -i \"$INVENTORY_FILE\" \"$playbook_path\" $VERBOSITY"

  if [[ "$DRY_RUN" == "true" ]]; then
    cmd="$cmd --check"
    echo "(Dry-run mode)" | tee -a "$LOG_FILE"
  fi

  # Run playbook
  if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${GREEN}✓ $playbook completed successfully${NC}" | tee -a "$LOG_FILE"
    ((run_count++))
  else
    echo -e "${RED}✗ $playbook failed${NC}" | tee -a "$LOG_FILE"
    ((fail_count++))

    # Ask if user wants to continue
    echo -ne "Continue with next playbook? (y/n): "
    read -r continue_choice
    if [[ "$continue_choice" != "y" ]]; then
      echo "Aborting." | tee -a "$LOG_FILE"
      exit 1
    fi
  fi

  # Small delay between playbooks
  sleep 2
done

# Summary
echo
echo "================================================" | tee -a "$LOG_FILE"
echo "Provisioning Complete" | tee -a "$LOG_FILE"
echo "================================================" | tee -a "$LOG_FILE"
echo "Playbooks run: $run_count" | tee -a "$LOG_FILE"
echo "Playbooks failed: $fail_count" | tee -a "$LOG_FILE"

if [[ $fail_count -eq 0 ]]; then
  echo -e "${GREEN}✓ All playbooks completed successfully!${NC}" | tee -a "$LOG_FILE"
  echo
  echo "Next steps:" | tee -a "$LOG_FILE"
  echo "1. Verify lab: bash scripts/health-check.sh --inventory $INVENTORY_FILE" | tee -a "$LOG_FILE"
  echo "2. RDP into VMs: xfreerdp /u:goad\\\\Administrator /p:PASSWORD /v:192.168.1.11" | tee -a "$LOG_FILE"
  echo "3. Start pentesting!" | tee -a "$LOG_FILE"
  exit 0
else
  echo -e "${RED}✗ Some playbooks failed${NC}" | tee -a "$LOG_FILE"
  echo "Check log file for details: $LOG_FILE" | tee -a "$LOG_FILE"
  exit 1
fi
