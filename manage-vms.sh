#!/bin/bash
# VM Management Script - Start, Stop, SSH, Monitor
# ניהול VMs - התחל, עצור, SSH, מעקב

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Lab configuration
declare -A LABS=(
  [1]="ad-lab-1|Active Directory Basics|2049|5001|192.168.56.11"
  [2]="ad-lab-2|LDAP Enumeration|2050|5002|192.168.56.12"
  [3]="ad-lab-3|Kerberos ASREProast|2051|5003|192.168.56.13"
  [4]="ad-lab-4|Privilege Escalation|2052|5004|192.168.56.14"
  [5]="ad-lab-5|Golden Ticket|2053|5005|192.168.56.15"
)

show_menu() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🖥️  VirtualBox VM Management (No Vagrant)"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Lab Selection:"
    echo "  1️⃣  Lab 1 - Active Directory Basics"
    echo "  2️⃣  Lab 2 - LDAP Enumeration"
    echo "  3️⃣  Lab 3 - Kerberos ASREProast"
    echo "  4️⃣  Lab 4 - Privilege Escalation"
    echo "  5️⃣  Lab 5 - Golden Ticket"
    echo ""
    echo "Operations:"
    echo "  s  - Start VM"
    echo "  t  - Stop VM"
    echo "  r  - Restart VM"
    echo "  x  - SSH into VM"
    echo "  i  - VM Info"
    echo "  a  - Start ALL VMs"
    echo "  h  - Halt ALL VMs"
    echo "  l  - List all VMs"
    echo "  m  - Monitor VMs"
    echo ""
    echo "  0  - Exit"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
}

get_vm_name() {
    local lab_num=$1
    local lab_info="${LABS[$lab_num]}"
    IFS='|' read -r id name port app_port ip <<< "$lab_info"
    echo "VulnLab-${id}"
}

get_lab_info() {
    local lab_num=$1
    local lab_info="${LABS[$lab_num]}"
    echo "$lab_info"
}

start_vm() {
    local lab_num=$1
    local vm_name=$(get_vm_name "$lab_num")

    echo "🚀 Starting $vm_name..."
    VBoxManage startvm "$vm_name" --type headless 2>/dev/null || {
        echo "❌ Failed to start $vm_name"
        return 1
    }

    echo "✅ $vm_name starting (wait 10 seconds for boot)..."
    sleep 10
}

stop_vm() {
    local lab_num=$1
    local vm_name=$(get_vm_name "$lab_num")

    echo "🛑 Stopping $vm_name..."
    VBoxManage controlvm "$vm_name" poweroff 2>/dev/null || {
        echo "❌ Failed to stop $vm_name"
        return 1
    }

    echo "✅ $vm_name stopped"
}

restart_vm() {
    local lab_num=$1
    stop_vm "$lab_num"
    sleep 2
    start_vm "$lab_num"
}

ssh_vm() {
    local lab_num=$1
    local lab_info=$(get_lab_info "$lab_num")
    IFS='|' read -r id name port app_port ip <<< "$lab_info"

    echo "🔐 Connecting to $name..."
    echo "   SSH Port: $port"
    echo "   IP: $ip"
    echo ""
    echo "ssh -p $port ubuntu@localhost"
    echo ""

    ssh -p "$port" ubuntu@localhost 2>/dev/null || {
        echo "⚠️  Connection failed. VM may not be started or network not configured."
        echo "Try: VBoxManage startvm VulnLab-${id} --type headless"
    }
}

vm_info() {
    local lab_num=$1
    local vm_name=$(get_vm_name "$lab_num")
    local lab_info=$(get_lab_info "$lab_num")
    IFS='|' read -r id name port app_port ip <<< "$lab_info"

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "ℹ️  $name"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "VM Name: $vm_name"
    echo "SSH Port: $port"
    echo "App Port: $app_port"
    echo "Internal IP: $ip"
    echo ""
    echo "VirtualBox Info:"
    VBoxManage showvminfo "$vm_name" --compact || echo "❌ VM not found"
    echo ""
}

list_all_vms() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "📋 All VirtualBox VMs"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    VBoxManage list vms || echo "❌ No VMs found"
    echo ""

    echo "Running VMs:"
    VBoxManage list runningvms || echo "   (None)"
    echo ""
}

monitor_vms() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "📊 VM Status"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    for i in {1..5}; do
        vm_name=$(get_vm_name "$i")
        lab_info=$(get_lab_info "$i")
        IFS='|' read -r id name port app_port ip <<< "$lab_info"

        # Check if running
        if VBoxManage list runningvms | grep -q "\"$vm_name\""; then
            status="🟢 Running"
        else
            status="🔴 Stopped"
        fi

        echo "[$i] $name"
        echo "    Status: $status"
        echo "    SSH: localhost:$port"
        echo "    App: http://localhost:$app_port"
        echo ""
    done
}

start_all_vms() {
    echo "🚀 Starting all VMs..."
    echo ""

    for i in {1..5}; do
        vm_name=$(get_vm_name "$i")
        echo "  Starting $vm_name..."
        VBoxManage startvm "$vm_name" --type headless 2>/dev/null || true
    done

    echo ""
    echo "✅ All VMs starting (wait 20 seconds for full boot)..."
    sleep 20

    monitor_vms
}

halt_all_vms() {
    echo "🛑 Stopping all VMs..."
    echo ""

    for i in {1..5}; do
        vm_name=$(get_vm_name "$i")
        echo "  Stopping $vm_name..."
        VBoxManage controlvm "$vm_name" poweroff 2>/dev/null || true
    done

    echo ""
    echo "✅ All VMs stopped"
}

# Main loop
while true; do
    show_menu
    read -p "Select operation: " choice

    case $choice in
        1|2|3|4|5)
            # Lab selected - ask for operation
            lab_num=$choice
            lab_info=$(get_lab_info "$lab_num")
            IFS='|' read -r id name port app_port ip <<< "$lab_info"

            echo ""
            echo "Selected: $name"
            echo "  1 - Start"
            echo "  2 - Stop"
            echo "  3 - Restart"
            echo "  4 - SSH"
            echo "  5 - Info"
            echo ""
            read -p "Choose operation: " op

            case $op in
                1) start_vm "$lab_num" ;;
                2) stop_vm "$lab_num" ;;
                3) restart_vm "$lab_num" ;;
                4) ssh_vm "$lab_num" ;;
                5) vm_info "$lab_num" ;;
                *) echo "Invalid operation" ;;
            esac
            ;;
        s)
            read -p "Enter lab number (1-5): " lab_num
            start_vm "$lab_num"
            ;;
        t)
            read -p "Enter lab number (1-5): " lab_num
            stop_vm "$lab_num"
            ;;
        r)
            read -p "Enter lab number (1-5): " lab_num
            restart_vm "$lab_num"
            ;;
        x)
            read -p "Enter lab number (1-5): " lab_num
            ssh_vm "$lab_num"
            ;;
        i)
            read -p "Enter lab number (1-5): " lab_num
            vm_info "$lab_num"
            ;;
        a)
            start_all_vms
            ;;
        h)
            halt_all_vms
            ;;
        l)
            list_all_vms
            ;;
        m)
            monitor_vms
            ;;
        0)
            echo "Goodbye! 👋"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac

    read -p "Press Enter to continue..."
done
