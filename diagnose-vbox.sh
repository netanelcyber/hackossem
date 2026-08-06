#!/bin/bash
# VirtualBox Diagnostic Script
# تشخيص مشاكل VirtualBox | VirtualBoxの診断スクリプト

echo "════════════════════════════════════════════════════════════"
echo "🔧 VirtualBox Diagnostic Tool"
echo "════════════════════════════════════════════════════════════"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_vboxmanage() {
    echo "════════════════════════════════════════════════════════════"
    echo "1️⃣  Checking VBoxManage Installation"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    if ! command -v VBoxManage &> /dev/null; then
        echo -e "${RED}❌ VBoxManage not found in PATH${NC}"
        echo ""
        echo "Solution:"
        echo "  1. Install VirtualBox:"
        echo "     sudo apt-get install virtualbox"
        echo ""
        echo "  2. Add to PATH (if installed in non-standard location):"
        echo "     export PATH=/usr/lib/virtualbox:\$PATH"
        echo ""
        return 1
    fi

    echo -e "${GREEN}✅ VBoxManage found${NC}"
    VBoxManage --version
    echo ""
    return 0
}

check_vbox_service() {
    echo "════════════════════════════════════════════════════════════"
    echo "2️⃣  Checking VirtualBox Service"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    if ! VBoxManage list vms &> /dev/null; then
        echo -e "${RED}❌ VirtualBox service not responding${NC}"
        echo ""
        echo "Solutions:"
        echo "  1. Try restarting VirtualBox:"
        echo "     sudo systemctl restart virtualbox"
        echo ""
        echo "  2. Or restart the VirtualBox kernel module:"
        echo "     sudo modprobe -r vboxdrv"
        echo "     sudo modprobe vboxdrv"
        echo ""
        return 1
    fi

    echo -e "${GREEN}✅ VirtualBox service responding${NC}"
    echo ""
    return 0
}

check_vms() {
    echo "════════════════════════════════════════════════════════════"
    echo "3️⃣  Checking Registered VMs"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    vm_count=$(VBoxManage list vms | wc -l)

    if [ "$vm_count" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No VMs registered${NC}"
        echo ""
        echo "Solutions:"
        echo "  1. Create VMs first:"
        echo "     ./create-vms-vboxmanage.sh"
        echo ""
        echo "  2. Or import existing VMs:"
        echo "     VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname 'VulnLab-ad-lab-1'"
        echo ""
        return 1
    fi

    echo -e "${GREEN}✅ Found $vm_count VM(s)${NC}"
    echo ""
    echo "Registered VMs:"
    VBoxManage list vms
    echo ""
    return 0
}

check_specific_vm() {
    echo "════════════════════════════════════════════════════════════"
    echo "4️⃣  Checking Specific VM: VulnLab-ad-lab-1"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    if ! VBoxManage list vms | grep -q "VulnLab-ad-lab-1"; then
        echo -e "${RED}❌ VM 'VulnLab-ad-lab-1' not found${NC}"
        echo ""
        echo "Available VMs:"
        VBoxManage list vms
        echo ""
        echo "Solutions:"
        echo "  1. Create the VM:"
        echo "     ./create-vms-vboxmanage.sh"
        echo ""
        echo "  2. Or check the exact VM name:"
        echo "     VBoxManage list vms"
        echo ""
        return 1
    fi

    echo -e "${GREEN}✅ VM 'VulnLab-ad-lab-1' found${NC}"
    echo ""
    echo "VM Details:"
    VBoxManage showvminfo "VulnLab-ad-lab-1" --compact
    echo ""
    return 0
}

check_vm_config() {
    echo "════════════════════════════════════════════════════════════"
    echo "5️⃣  Checking VM Configuration"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    if ! VBoxManage list vms | grep -q "VulnLab-ad-lab-1"; then
        echo "VM not found - skipping configuration check"
        return 1
    fi

    echo "Memory allocation:"
    VBoxManage showvminfo "VulnLab-ad-lab-1" | grep "Memory size"

    echo ""
    echo "CPU allocation:"
    VBoxManage showvminfo "VulnLab-ad-lab-1" | grep -E "CPU|CPUs"

    echo ""
    echo "Storage controllers:"
    VBoxManage showvminfo "VulnLab-ad-lab-1" | grep "Storage Controller"

    echo ""
    echo "Network adapters:"
    VBoxManage showvminfo "VulnLab-ad-lab-1" | grep "NIC"

    echo ""
    return 0
}

check_host_system() {
    echo "════════════════════════════════════════════════════════════"
    echo "6️⃣  Checking Host System"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    echo "Kernel:"
    uname -a
    echo ""

    echo "Free Memory:"
    free -h | head -2
    echo ""

    echo "Free Disk Space:"
    df -h / | tail -1
    echo ""

    echo "CPU Info:"
    grep "processor" /proc/cpuinfo | wc -l
    echo "  Processor count: $(grep "processor" /proc/cpuinfo | wc -l)"
    echo ""

    # Check virtualization support
    echo "Virtualization Support:"
    if grep -q "vmx\|svm" /proc/cpuinfo; then
        echo -e "  ${GREEN}✅ CPU virtualization enabled${NC}"
    else
        echo -e "  ${RED}❌ CPU virtualization not detected${NC}"
        echo "     May need to enable in BIOS"
    fi
    echo ""
}

check_networking() {
    echo "════════════════════════════════════════════════════════════"
    echo "7️⃣  Checking Networking"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    echo "Host-only networks:"
    VBoxManage list hostonlyifs || echo "   (No host-only networks)"
    echo ""

    echo "NAT networks:"
    VBoxManage list natnetworks || echo "   (No NAT networks)"
    echo ""

    echo "Network adapters for VulnLab-ad-lab-1:"
    if VBoxManage list vms | grep -q "VulnLab-ad-lab-1"; then
        VBoxManage showvminfo "VulnLab-ad-lab-1" | grep -A 5 "NIC"
    else
        echo "   (VM not found)"
    fi
    echo ""
}

check_logs() {
    echo "════════════════════════════════════════════════════════════"
    echo "8️⃣  Checking VirtualBox Logs"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    log_dir="$HOME/.config/VirtualBox"

    if [ ! -d "$log_dir" ]; then
        echo "VirtualBox config directory not found"
        return 1
    fi

    echo "Recent VirtualBox logs:"
    find "$log_dir" -name "*.log" -type f -mtime -1 2>/dev/null | head -5 || echo "   (No recent logs)"
    echo ""

    if [ -f "$log_dir/VBoxSVC.log" ]; then
        echo "Last 20 lines of VBoxSVC.log:"
        tail -20 "$log_dir/VBoxSVC.log"
        echo ""
    fi
}

test_vm_start() {
    echo "════════════════════════════════════════════════════════════"
    echo "9️⃣  Testing VM Start"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    if ! VBoxManage list vms | grep -q "VulnLab-ad-lab-1"; then
        echo "VM not found - cannot test"
        return 1
    fi

    echo "Attempting to start VulnLab-ad-lab-1 with verbose output..."
    echo ""

    # Try with debug output
    if VBoxManage startvm "VulnLab-ad-lab-1" --type headless 2>&1; then
        echo ""
        echo -e "${GREEN}✅ VM started successfully${NC}"
        sleep 3

        # Check if running
        if VBoxManage list runningvms | grep -q "VulnLab-ad-lab-1"; then
            echo -e "${GREEN}✅ VM is running${NC}"
        fi
    else
        echo ""
        echo -e "${RED}❌ Failed to start VM${NC}"
    fi
    echo ""
}

summary() {
    echo "════════════════════════════════════════════════════════════"
    echo "📋 Diagnostic Summary"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Check the issues above and apply suggested solutions."
    echo ""
    echo "Common solutions:"
    echo ""
    echo "1. VBoxManage not found:"
    echo "   sudo apt-get install virtualbox"
    echo ""
    echo "2. VM creation:"
    echo "   ./create-vms-vboxmanage.sh"
    echo ""
    echo "3. Service issues:"
    echo "   sudo systemctl restart virtualbox"
    echo ""
    echo "4. Hardware virtualization not enabled:"
    echo "   - Restart computer"
    echo "   - Enter BIOS (usually Del or F2 during startup)"
    echo "   - Enable VT-x (Intel) or AMD-V (AMD)"
    echo "   - Save and reboot"
    echo ""
    echo "5. Cloud environment (no VirtualBox available):"
    echo "   VirtualBox cannot run in cloud environments"
    echo "   Use Docker or Vagrant on your local machine instead"
    echo ""
}

# Run all checks
check_vboxmanage || {
    echo -e "${RED}VBoxManage not available - stopping diagnosis${NC}"
    echo ""
    echo "This appears to be a cloud environment or VirtualBox is not installed."
    echo "VirtualBox requires:"
    echo "  • Local machine (not cloud)"
    echo "  • Hardware virtualization support"
    echo "  • VirtualBox software installed"
    echo ""
    echo "Alternatives:"
    echo "  1. Use Docker (cloud-friendly):"
    echo "     docker-compose up"
    echo ""
    echo "  2. Use Vagrant (local machine only):"
    echo "     cd lab-vms-vagrant && vagrant up"
    echo ""
    exit 1
}

check_vbox_service || echo -e "${YELLOW}⚠️  Warning: VirtualBox service issues${NC}"
check_vms
check_specific_vm
check_vm_config
check_host_system
check_networking
check_logs
test_vm_start
summary
