#!/bin/bash
##############################################################################
# GOAD VirtualBox: Network Setup
# Creates isolated internal network for GOAD VMs
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/network-setup.log"
mkdir -p "$(dirname "$LOG_FILE")"

NETWORK_NAME="goad-internal"
NETWORK_IP="192.168.1.1"
NETWORK_MASK="255.255.255.0"
DHCP_LOWER="192.168.1.100"
DHCP_UPPER="192.168.1.200"

GREEN='\033[0;32m'
NC='\033[0m'

echo "GOAD VirtualBox Network Setup" | tee "$LOG_FILE"
echo "=============================" | tee -a "$LOG_FILE"
echo

# Check if network already exists
if VBoxManage list networks | grep -q "Name.*$NETWORK_NAME"; then
  echo "Network '$NETWORK_NAME' already exists. Verifying configuration..." | tee -a "$LOG_FILE"

  # Get current DHCP status
  local dhcp_enabled=$(VBoxManage dhcpserver options "$NETWORK_NAME" --id 0 2>/dev/null | grep -c "Enabled" || echo "0")

  if [[ $dhcp_enabled -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} Network is properly configured." | tee -a "$LOG_FILE"
    exit 0
  fi
fi

echo "Creating internal network: $NETWORK_NAME" | tee -a "$LOG_FILE"

# Try to add DHCP server for the network
if VBoxManage dhcpserver add \
  --network="$NETWORK_NAME" \
  --server-ip="$NETWORK_IP" \
  --netmask="$NETWORK_MASK" \
  --lower-ip="$DHCP_LOWER" \
  --upper-ip="$DHCP_UPPER" \
  --enable 2>&1 | tee -a "$LOG_FILE"; then

  echo -e "${GREEN}✓${NC} Network created successfully" | tee -a "$LOG_FILE"
  echo "  Name:       $NETWORK_NAME" | tee -a "$LOG_FILE"
  echo "  IP:         $NETWORK_IP" | tee -a "$LOG_FILE"
  echo "  Netmask:    $NETWORK_MASK" | tee -a "$LOG_FILE"
  echo "  DHCP Range: $DHCP_LOWER - $DHCP_UPPER" | tee -a "$LOG_FILE"
else
  # Network might already exist, try to modify DHCP
  echo "Network may already exist. Attempting to enable DHCP..." | tee -a "$LOG_FILE"

  if VBoxManage dhcpserver modify \
    --network="$NETWORK_NAME" \
    --enable 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${GREEN}✓${NC} DHCP enabled on existing network" | tee -a "$LOG_FILE"
  else
    echo "Warning: Could not verify DHCP configuration" | tee -a "$LOG_FILE"
  fi
fi

echo
echo "Verifying network configuration..." | tee -a "$LOG_FILE"
VBoxManage list networks | grep -A 5 "$NETWORK_NAME" | tee -a "$LOG_FILE"

echo
echo -e "${GREEN}✓ Network setup complete${NC}" | tee -a "$LOG_FILE"
