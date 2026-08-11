#!/bin/bash
##############################################################################
# GOAD VirtualBox: Health Check
# Verifies lab is properly configured and provisioned
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/health-check.log"
mkdir -p "$(dirname "$LOG_FILE")"

INVENTORY_FILE=""

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
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INVENTORY_FILE" ]]; then
  INVENTORY_FILE="${SCRIPT_DIR}/../inventory/hosts.ini"
fi

echo "GOAD VirtualBox Health Check" | tee "$LOG_FILE"
echo "============================" | tee -a "$LOG_FILE"
echo "Inventory: $INVENTORY_FILE" | tee -a "$LOG_FILE"
echo

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: VMs running
echo "Checking VMs..." | tee -a "$LOG_FILE"
running_vms=$(VBoxManage list runningvms | wc -l)
if [[ $running_vms -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} $running_vms VM(s) running" | tee -a "$LOG_FILE"
  ((CHECKS_PASSED++))
else
  echo -e "${RED}✗${NC} No VMs running" | tee -a "$LOG_FILE"
  ((CHECKS_FAILED++))
fi

# Check 2: WinRM connectivity
echo | tee -a "$LOG_FILE"
echo "Checking WinRM connectivity..." | tee -a "$LOG_FILE"
if command -v ansible &> /dev/null; then
  if ansible -i "$INVENTORY_FILE" windows -m win_ping --limit dc01 &>/dev/null; then
    echo -e "${GREEN}✓${NC} WinRM connectivity OK" | tee -a "$LOG_FILE"
    ((CHECKS_PASSED++))
  else
    echo -e "${RED}✗${NC} WinRM connectivity failed" | tee -a "$LOG_FILE"
    echo "     Run: ansible -i $INVENTORY_FILE windows -m win_ping -vvv" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
  fi
else
  echo -e "${YELLOW}⚠${NC} Ansible not installed, skipping WinRM check" | tee -a "$LOG_FILE"
fi

# Check 3: Domain exists
echo | tee -a "$LOG_FILE"
echo "Checking Active Directory..." | tee -a "$LOG_FILE"
if command -v ansible &> /dev/null; then
  if ansible -i "$INVENTORY_FILE" dc01 -m win_command -a "Get-ADDomain" 2>/dev/null | grep -q "goad.local"; then
    echo -e "${GREEN}✓${NC} Domain 'goad.local' exists" | tee -a "$LOG_FILE"
    ((CHECKS_PASSED++))
  else
    echo -e "${RED}✗${NC} Domain 'goad.local' not found" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
  fi
else
  echo -e "${YELLOW}⚠${NC} Ansible not installed, skipping domain check" | tee -a "$LOG_FILE"
fi

# Check 4: Users created
echo | tee -a "$LOG_FILE"
echo "Checking AD users..." | tee -a "$LOG_FILE"
if command -v ansible &> /dev/null; then
  user_count=$(ansible -i "$INVENTORY_FILE" dc01 -m win_command -a "Get-ADUser -Filter * | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "0")
  if [[ $user_count -gt 10 ]]; then
    echo -e "${GREEN}✓${NC} $user_count AD users found" | tee -a "$LOG_FILE"
    ((CHECKS_PASSED++))
  else
    echo -e "${RED}✗${NC} Fewer than expected AD users ($user_count)" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
  fi
else
  echo -e "${YELLOW}⚠${NC} Ansible not installed, skipping user check" | tee -a "$LOG_FILE"
fi

# Summary
echo | tee -a "$LOG_FILE"
echo "============================" | tee -a "$LOG_FILE"
echo "Checks passed: $CHECKS_PASSED" | tee -a "$LOG_FILE"
echo "Checks failed: $CHECKS_FAILED" | tee -a "$LOG_FILE"

if [[ $CHECKS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ Lab is healthy!${NC}" | tee -a "$LOG_FILE"
  exit 0
else
  echo -e "${RED}✗ Lab has issues, see above${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
