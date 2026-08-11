#!/bin/bash
##############################################################################
# GOAD VirtualBox: Prerequisites Check
# Verifies VirtualBox, Ansible, disk space, and RAM availability
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/check-requirements.log"
mkdir -p "$(dirname "$LOG_FILE")"

PASS="✓"
FAIL="✗"
WARN="⚠"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "GOAD VirtualBox Prerequisites Check" | tee "$LOG_FILE"
echo "====================================" | tee -a "$LOG_FILE"
echo

# Track failures
CHECKS_FAILED=0
WARNINGS=0

# Helper functions
check_command() {
  local cmd=$1
  local name=$2
  if command -v "$cmd" &> /dev/null; then
    local version=$("$cmd" --version 2>&1 | head -1)
    echo -e "${GREEN}${PASS}${NC} $name: $version" | tee -a "$LOG_FILE"
  else
    echo -e "${RED}${FAIL}${NC} $name: NOT FOUND" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
  fi
}

check_vboxmanage() {
  if command -v VBoxManage &> /dev/null; then
    local version=$(VBoxManage --version 2>&1)
    echo -e "${GREEN}${PASS}${NC} VirtualBox: $version" | tee -a "$LOG_FILE"

    # Check if vboxdrv kernel module is loaded (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if lsmod | grep -q vboxdrv; then
        echo -e "${GREEN}${PASS}${NC} VirtualBox kernel module loaded" | tee -a "$LOG_FILE"
      else
        echo -e "${RED}${FAIL}${NC} VirtualBox kernel module NOT loaded" | tee -a "$LOG_FILE"
        echo "     Run: sudo modprobe vboxdrv" | tee -a "$LOG_FILE"
        ((CHECKS_FAILED++))
      fi
    fi
  else
    echo -e "${RED}${FAIL}${NC} VirtualBox (VBoxManage): NOT FOUND" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
  fi
}

check_disk_space() {
  local required_gb=${1:-100}
  local check_path=${2:-/var/lib/vbox}

  if [[ ! -d "$check_path" ]]; then
    check_path="/home"
  fi

  local available=$(df -BG "$check_path" | tail -1 | awk '{print $4}' | sed 's/G//')

  if [[ $available -ge $required_gb ]]; then
    echo -e "${GREEN}${PASS}${NC} Disk space: ${available}GB available (need $required_gb GB)" | tee -a "$LOG_FILE"
  else
    echo -e "${RED}${FAIL}${NC} Disk space: Only ${available}GB available (need $required_gb GB)" | tee -a "$LOG_FILE"
    ((CHECKS_FAILED++))
  fi
}

check_ram() {
  local required_gb=${1:-12}
  local available=$(free -BG | grep "^Mem" | awk '{print $7}' | sed 's/G//')

  if [[ $available -ge $required_gb ]]; then
    echo -e "${GREEN}${PASS}${NC} RAM available: ${available}GB (need $required_gb GB)" | tee -a "$LOG_FILE"
  else
    echo -e "${YELLOW}${WARN}${NC} RAM available: ${available}GB (recommended $required_gb GB)" | tee -a "$LOG_FILE"
    ((WARNINGS++))
  fi
}

# Run checks
echo "=== VirtualBox ===" | tee -a "$LOG_FILE"
check_vboxmanage
echo

echo "=== Required Tools ===" | tee -a "$LOG_FILE"
check_command "ansible" "Ansible"
check_command "git" "Git"
check_command "python3" "Python3"
echo

echo "=== System Resources ===" | tee -a "$LOG_FILE"
check_disk_space 100 "/var/lib/vbox"
check_ram 12
echo

echo "=== Network ===" | tee -a "$LOG_FILE"
if VBoxManage list networks | grep -q "goad-internal"; then
  echo -e "${GREEN}${PASS}${NC} VirtualBox network 'goad-internal' exists" | tee -a "$LOG_FILE"
else
  echo -e "${YELLOW}${WARN}${NC} VirtualBox network 'goad-internal' not found (will be created)" | tee -a "$LOG_FILE"
fi
echo

echo "=== Python Modules ===" | tee -a "$LOG_FILE"
if python3 -c "import ansible" &>/dev/null; then
  local ansible_ver=$(python3 -c "import ansible; print(ansible.__version__)")
  echo -e "${GREEN}${PASS}${NC} Ansible Python module: $ansible_ver" | tee -a "$LOG_FILE"
else
  echo -e "${RED}${FAIL}${NC} Ansible Python module: NOT FOUND" | tee -a "$LOG_FILE"
  ((CHECKS_FAILED++))
fi

if python3 -c "import winrm" &>/dev/null; then
  echo -e "${GREEN}${PASS}${NC} PyWinRM module available" | tee -a "$LOG_FILE"
else
  echo -e "${YELLOW}${WARN}${NC} PyWinRM module not found (install: pip install pywinrm)" | tee -a "$LOG_FILE"
  ((WARNINGS++))
fi
echo

# Summary
echo "====================================" | tee -a "$LOG_FILE"
if [[ $CHECKS_FAILED -eq 0 ]]; then
  if [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${NC}" | tee -a "$LOG_FILE"
    exit 0
  else
    echo -e "${YELLOW}All critical checks passed, but $WARNINGS warnings${NC}" | tee -a "$LOG_FILE"
    exit 0
  fi
else
  echo -e "${RED}$CHECKS_FAILED critical checks failed${NC}" | tee -a "$LOG_FILE"
  echo "Fix the issues above before proceeding." | tee -a "$LOG_FILE"
  exit 1
fi
