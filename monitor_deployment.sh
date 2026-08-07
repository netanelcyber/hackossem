#!/bin/bash
# Active Directory Deployment Monitor
# Real-time monitoring of VM creation and installation progress

set -euo pipefail

# Configuration
CONFIG_FILE="${CONFIG_FILE:-machines_config.json}"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-5}"  # seconds
LOG_FILE="${LOG_FILE:-/mnt/vms/logs/deployment_*.log}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Get latest log file
get_latest_log() {
    ls -t /mnt/vms/logs/deployment_*.log 2>/dev/null | head -1
}

# Display dashboard
display_dashboard() {
    clear

    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  Active Directory Deployment Monitor                       ║${NC}"
    echo -e "${MAGENTA}║  Updated: $(date '+%Y-%m-%d %H:%M:%S')                            ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # VirtualBox Status
    echo -e "${CYAN}━━━ VirtualBox Status ━━━${NC}"
    echo ""

    if ! command -v VBoxManage &> /dev/null; then
        echo -e "${RED}✗ VBoxManage not found${NC}"
        return 1
    fi

    # Count VMs
    local total_vms=$(VBoxManage list vms 2>/dev/null | wc -l)
    local running_vms=$(VBoxManage list runningvms 2>/dev/null | wc -l)

    echo -e "Total VMs:   ${CYAN}$total_vms${NC}"
    echo -e "Running:     ${GREEN}$running_vms${NC}"
    echo -e "Stopped:     ${YELLOW}$((total_vms - running_vms))${NC}"
    echo ""

    # VM Details
    echo -e "${CYAN}━━━ VM Details ━━━${NC}"
    echo ""

    if command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
        printf "${BOLD}%-15s %-15s %-18s %-15s${NC}\n" \
            "Name" "Role" "IP" "Status"
        echo "───────────────────────────────────────────────────────"

        jq -r '.machines[] | "\(.name),\(.role),\(.ip)"' "$CONFIG_FILE" | while IFS=',' read -r name role ip; do
            local status=$(VBoxManage showvminfo "$name" --machinereadable 2>/dev/null | grep "^VMState=" | cut -d'=' -f2 | tr -d '"' || echo "unknown")
            local ping_status="offline"
            local color="$RED"

            if [ "$status" = "running" ]; then
                color="$GREEN"
                if ping -c 1 -W 2 "$ip" &>/dev/null 2>&1; then
                    ping_status="online"
                else
                    ping_status="booting"
                    color="$YELLOW"
                fi
            elif [ "$status" = "poweroff" ]; then
                color="$YELLOW"
                ping_status="offline"
            fi

            printf "%-15s %-15s %-18s ${color}%-15s${NC}\n" \
                "$name" "$role" "$ip" "$ping_status"
        done
    else
        echo "Config file not found: $CONFIG_FILE"
        echo "Run from directory containing machines_config.json"
    fi

    echo ""

    # Log Status
    echo -e "${CYAN}━━━ Deployment Log ━━━${NC}"
    echo ""

    local latest_log=$(get_latest_log)
    if [ -n "$latest_log" ] && [ -f "$latest_log" ]; then
        echo -e "Log file: ${CYAN}$latest_log${NC}"
        echo ""
        echo "Latest entries:"
        tail -5 "$latest_log" | sed 's/^/  /'
    else
        echo "No deployment log found"
    fi

    echo ""

    # Statistics
    echo -e "${CYAN}━━━ Installation Progress ━━━${NC}"
    echo ""

    if [ -n "$latest_log" ] && [ -f "$latest_log" ]; then
        local total_logs=$(wc -l < "$latest_log")
        local success_count=$(grep -c "\[SUCCESS\]" "$latest_log" || echo 0)
        local error_count=$(grep -c "\[ERROR\]" "$latest_log" || echo 0)
        local warn_count=$(grep -c "\[WARN\]" "$latest_log" || echo 0)

        printf "%-20s %s\n" "Total Log Entries:" "$total_logs"
        printf "%-20s %s\n" "Successes:" "$success_count"
        printf "%-20s %s\n" "Warnings:" "$warn_count"
        printf "%-20s %s\n" "Errors:" "$error_count"
    fi

    echo ""

    # Instructions
    echo -e "${CYAN}━━━ Controls ━━━${NC}"
    echo ""
    echo "Press ${BOLD}Ctrl+C${NC} to exit monitoring"
    echo "Refresh interval: ${CYAN}${REFRESH_INTERVAL}s${NC}"
    echo ""
    echo "To change refresh rate:"
    echo "  ${YELLOW}REFRESH_INTERVAL=10 $0${NC}"
    echo ""
}

# Main loop
main() {
    trap 'clear; echo "Monitoring stopped"; exit 0' INT TERM

    while true; do
        display_dashboard
        sleep "$REFRESH_INTERVAL"
    done
}

# Run main
main "$@"
