#!/bin/bash
# Create VMs using VBoxManage (without Vagrant)
# יצירת VMs באמצעות VBoxManage (ללא Vagrant)

set -e

echo "════════════════════════════════════════════════════════════"
echo "🖥️  Create VMs with VBoxManage (No Vagrant Required)"
echo "════════════════════════════════════════════════════════════"
echo ""

# Configuration
VM_BASE_PATH="${HOME}/VirtualBox VMs"
ISO_PATH="${HOME}/ubuntu-22.04-live-server-amd64.iso"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check prerequisites
echo "🔍 Checking prerequisites..."
echo ""

if ! command -v VBoxManage &> /dev/null; then
    echo "❌ VirtualBox not installed!"
    echo "Install: sudo apt-get install virtualbox virtualbox-ext-pack"
    exit 1
fi

echo "✅ VBoxManage: $(VBoxManage --version)"
echo ""

# Define labs
declare -a LABS=(
  "ad-lab-1|Active Directory Basics|2049|192.168.56.11"
  "ad-lab-2|LDAP Enumeration|2050|192.168.56.12"
  "ad-lab-3|Kerberos ASREProast|2051|192.168.56.13"
  "ad-lab-4|Privilege Escalation|2052|192.168.56.14"
  "ad-lab-5|Golden Ticket|2053|192.168.56.15"
)

echo "════════════════════════════════════════════════════════════"
echo "📋 Lab Configuration:"
echo "════════════════════════════════════════════════════════════"
echo ""

counter=1
for lab in "${LABS[@]}"; do
    IFS='|' read -r id name port ip <<< "$lab"
    echo "[$counter] $name"
    echo "    ID: $id"
    echo "    Port: $port"
    echo "    IP: $ip"
    echo ""
    counter=$((counter + 1))
done

echo "════════════════════════════════════════════════════════════"
echo "⚙️  VM Creation Settings:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Memory per VM: 2048 MB"
echo "CPUs per VM: 2"
echo "Disk per VM: 20 GB"
echo "Network: NAT + Host-only (192.168.56.x)"
echo "OS: Ubuntu 22.04 Server"
echo ""

read -p "Continue with VM creation? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 Creating VMs..."
echo "════════════════════════════════════════════════════════════"
echo ""

counter=1
for lab in "${LABS[@]}"; do
    IFS='|' read -r id name port ip <<< "$lab"

    echo "[$counter/5] Creating $name..."
    echo ""

    # VM name for VirtualBox
    vm_name="VulnLab-$id"

    # Check if VM already exists
    if VBoxManage list vms | grep -q "\"$vm_name\""; then
        echo "    ⚠️  VM already exists: $vm_name"
        echo "    Skipping..."
        counter=$((counter + 1))
        echo ""
        continue
    fi

    # Create VM
    echo "    📝 Creating VM..."
    VBoxManage createvm --name "$vm_name" --ostype Ubuntu_64 --register

    # Configure VM
    echo "    ⚙️  Configuring VM..."
    VBoxManage modifyvm "$vm_name" --memory 2048 --cpus 2 --vram 16

    # Create and attach storage controller
    echo "    💾 Creating storage..."
    VBoxManage storagectl "$vm_name" --name "SATA Controller" --add sata --controller IntelAhci

    # Create virtual hard disk (20GB)
    hdd_path="${VM_BASE_PATH}/${vm_name}/${vm_name}.vdi"
    mkdir -p "${VM_BASE_PATH}/${vm_name}"

    VBoxManage createmedium disk --filename "$hdd_path" --size 20480 --format VDI
    VBoxManage storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$hdd_path"

    # Configure networking
    echo "    🌐 Configuring networking..."

    # NAT adapter for internet
    VBoxManage modifyvm "$vm_name" --nic1 nat
    VBoxManage modifyvm "$vm_name" --natpf1 "SSH,tcp,,${port},,22"

    # Host-only adapter for internal network
    VBoxManage modifyvm "$vm_name" --nic2 hostonly --hostonlyadapter2 "vboxnet0"

    # Set boot order
    VBoxManage modifyvm "$vm_name" --boot1 disk --boot2 dvd

    echo "    ✅ VM created: $vm_name"
    echo ""

    counter=$((counter + 1))
done

echo "════════════════════════════════════════════════════════════"
echo "✅ VM Creation Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "📋 Created VMs:"
VBoxManage list vms | grep "VulnLab-"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 Next Steps:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Download Ubuntu 22.04 ISO (if not already done):"
echo "    wget https://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso"
echo ""
echo "2️⃣  Attach ISO and start VM (example):"
echo "    VBoxManage storageattach VulnLab-ad-lab-1 --storagectl 'SATA Controller' --port 1 --device 0 --type dvddrive --medium /path/to/ubuntu-22.04.iso"
echo "    VBoxManage startvm VulnLab-ad-lab-1"
echo ""
echo "3️⃣  Complete Ubuntu installation in VM (interactive)"
echo ""
echo "4️⃣  After installation, install dependencies:"
echo "    sudo apt-get update"
echo "    sudo apt-get install -y python3 python3-pip python3-venv git curl"
echo ""
echo "5️⃣  Clone this repo and run setup:"
echo "    git clone https://github.com/netanelcyber/hackossem.git"
echo "    cd hackossem"
echo "    python3 -m venv venv"
echo "    source venv/bin/activate"
echo "    pip install -r requirements.txt"
echo ""
echo "See VBOXMANAGE_VM_GUIDE.md for detailed instructions"
echo ""
