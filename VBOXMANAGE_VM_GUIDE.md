# 🖥️ VBoxManage VM Creation Guide (No Vagrant)

## Overview

Create and manage VirtualBox VMs without Vagrant using VBoxManage command-line tool. This provides more control and doesn't require Vagrant.

---

## Prerequisites

### Software
- **VirtualBox 6.1+** - Download: https://www.virtualbox.org/wiki/Downloads
- **Ubuntu 22.04 ISO** - Download: https://releases.ubuntu.com/jammy/
- **Git** - For cloning repository
- **Bash** - For running scripts

### Hardware
- **RAM**: 2GB per VM (10GB+ for 5 VMs)
- **Disk**: 20GB per VM (100GB+ for 5 VMs)
- **CPU**: 2+ cores per VM

### Network
- Host-only network: `vboxnet0` (created by VirtualBox)
- NAT network: Built-in to VirtualBox

---

## Quick Start

### 1. Download Ubuntu ISO

```bash
# Download Ubuntu 22.04 Server ISO (~1.2 GB)
wget https://releases.ubuntu.com/jammy/ubuntu-22.04-live-server-amd64.iso -O ~/ubuntu-22.04.iso

# Verify checksum (optional)
sha256sum ~/ubuntu-22.04.iso
```

### 2. Create VMs

```bash
# Make script executable
chmod +x create-vms-vboxmanage.sh

# Run the creation script
./create-vms-vboxmanage.sh

# This creates 5 VMs:
# - VulnLab-ad-lab-1 (2GB RAM, 2 CPU, 20GB disk)
# - VulnLab-ad-lab-2
# - VulnLab-ad-lab-3
# - VulnLab-ad-lab-4
# - VulnLab-ad-lab-5
```

### 3. Install Operating System

For each VM, attach ISO and boot:

```bash
# Attach ISO to VM
VBoxManage storageattach VulnLab-ad-lab-1 \
  --storagectl "SATA Controller" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium ~/ubuntu-22.04.iso

# Start VM
VBoxManage startvm VulnLab-ad-lab-1

# Follow Ubuntu installation wizard (interactive)
# When complete, the ISO auto-ejects
```

### 4. Install Dependencies

SSH into each VM and install:

```bash
ssh -p 2049 ubuntu@localhost

# In VM:
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv git curl

# Clone this repo
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem

# Install Python dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run the application
python3 app.py
```

---

## VBoxManage Commands Reference

### VM Lifecycle

```bash
# List all VMs
VBoxManage list vms

# List running VMs
VBoxManage list runningvms

# Start VM
VBoxManage startvm "VulnLab-ad-lab-1"

# Start VM headless (no GUI)
VBoxManage startvm "VulnLab-ad-lab-1" --type headless

# Stop VM (graceful)
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff

# Pause VM
VBoxManage controlvm "VulnLab-ad-lab-1" pause

# Resume VM
VBoxManage controlvm "VulnLab-ad-lab-1" resume

# Reboot VM
VBoxManage controlvm "VulnLab-ad-lab-1" reset

# Delete VM
VBoxManage unregistervm "VulnLab-ad-lab-1" --delete
```

### VM Configuration

```bash
# Modify memory
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096

# Modify CPU count
VBoxManage modifyvm "VulnLab-ad-lab-1" --cpus 4

# Modify VRAM
VBoxManage modifyvm "VulnLab-ad-lab-1" --vram 32

# Get VM information
VBoxManage showvminfo "VulnLab-ad-lab-1"

# Get VM info (brief)
VBoxManage showvminfo "VulnLab-ad-lab-1" --compact
```

### Storage Management

```bash
# Create storage controller
VBoxManage storagectl "VulnLab-ad-lab-1" \
  --name "SATA Controller" \
  --add sata \
  --controller IntelAhci

# Create virtual disk (20GB)
VBoxManage createmedium disk \
  --filename ~/VirtualBox\ VMs/VulnLab-ad-lab-1/disk.vdi \
  --size 20480 \
  --format VDI

# Attach disk to VM
VBoxManage storageattach "VulnLab-ad-lab-1" \
  --storagectl "SATA Controller" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium ~/VirtualBox\ VMs/VulnLab-ad-lab-1/disk.vdi

# Attach ISO to VM
VBoxManage storageattach "VulnLab-ad-lab-1" \
  --storagectl "SATA Controller" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium ~/ubuntu-22.04.iso

# Remove ISO (eject)
VBoxManage storageattach "VulnLab-ad-lab-1" \
  --storagectl "SATA Controller" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium emptydrive

# List media (disks, ISOs)
VBoxManage list media
```

### Networking

```bash
# Configure NAT adapter
VBoxManage modifyvm "VulnLab-ad-lab-1" --nic1 nat

# Configure Host-only adapter
VBoxManage modifyvm "VulnLab-ad-lab-1" --nic2 hostonly

# Configure adapter for specific host-only network
VBoxManage modifyvm "VulnLab-ad-lab-1" --hostonlyadapter2 "vboxnet0"

# Add port forwarding (SSH example)
VBoxManage modifyvm "VulnLab-ad-lab-1" \
  --natpf1 "SSH,tcp,,2049,,22"

# Remove port forwarding
VBoxManage modifyvm "VulnLab-ad-lab-1" \
  --natpf1 delete "SSH"

# Get network info
VBoxManage showvminfo "VulnLab-ad-lab-1" | grep -A 5 "NIC"
```

### Snapshots

```bash
# Create snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" \
  take "before-testing" \
  --description "Backup before testing"

# List snapshots
VBoxManage snapshot "VulnLab-ad-lab-1" list

# Restore snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" restore "before-testing"

# Delete snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" delete "before-testing"
```

### Export/Import

```bash
# Export VM as OVA
VBoxManage export "VulnLab-ad-lab-1" \
  -o "lab-ad-lab-1.ova" \
  --vsys 0 \
  --product "VulnLab AD Lab 1" \
  --vendor "VulnLab" \
  --version "1.0"

# Import OVA
VBoxManage import "lab-ad-lab-1.ova" \
  --vsys 0 \
  --vmname "VulnLab-ad-lab-1-imported"
```

---

## Automation Scripts

### Setup Script (Auto-Install Dependencies)

Create `/home/ubuntu/setup.sh` inside VM:

```bash
#!/bin/bash
set -e

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y \
  python3 python3-pip python3-venv \
  git curl wget \
  build-essential libssl-dev

# Create app user
sudo useradd -m -s /bin/bash hackossem || true

# Clone repository
cd /home/hackossem || mkdir -p /home/hackossem
sudo chown hackossem:hackossem /home/hackossem
git clone https://github.com/netanelcyber/hackossem.git . || true

# Setup Python environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create systemd service
sudo tee /etc/systemd/system/hackossem.service > /dev/null <<EOF
[Unit]
Description=VulnLab Hackossem Application
After=network.target

[Service]
Type=simple
User=hackossem
WorkingDirectory=/home/hackossem
Environment="PATH=/home/hackossem/venv/bin"
ExecStart=/home/hackossem/venv/bin/python3 app.py
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable hackossem
sudo systemctl start hackossem

echo "✅ Setup complete!"
```

Then from host:

```bash
# Copy setup script to VM
scp -P 2049 setup.sh ubuntu@localhost:/home/ubuntu/

# SSH in and run it
ssh -p 2049 ubuntu@localhost "bash ~/setup.sh"
```

---

## Port Mapping Reference

| Lab | VM Name | SSH Port | App Port | IP |
|-----|---------|----------|----------|-----|
| 1 | VulnLab-ad-lab-1 | 2049 | 5001 | 192.168.56.11 |
| 2 | VulnLab-ad-lab-2 | 2050 | 5002 | 192.168.56.12 |
| 3 | VulnLab-ad-lab-3 | 2051 | 5003 | 192.168.56.13 |
| 4 | VulnLab-ad-lab-4 | 2052 | 5004 | 192.168.56.14 |
| 5 | VulnLab-ad-lab-5 | 2053 | 5005 | 192.168.56.15 |

### SSH Access

```bash
# SSH to Lab 1
ssh -p 2049 ubuntu@localhost

# SSH to Lab 2
ssh -p 2050 ubuntu@localhost

# Or use IP directly (if host-only network is up)
ssh ubuntu@192.168.56.11
```

### Web Access

```bash
# Lab 1 application
http://localhost:5001

# Lab 2 application
http://localhost:5002

# Note: Port forwarding must be configured in VBoxManage
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 "HTTP,tcp,,5001,,5000"
```

---

## Troubleshooting

### VM Creation Fails

```bash
# Check VirtualBox installation
VBoxManage --version

# Verify host-only network exists
VBoxManage list hostonlyifs

# If not, create it
VBoxManage hostonlyif create
```

### Cannot Connect via SSH

```bash
# Check if VM is running
VBoxManage list runningvms

# Check port forwarding is configured
VBoxManage showvminfo "VulnLab-ad-lab-1" | grep natpf

# If missing, add it
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 "SSH,tcp,,2049,,22"

# Restart VM
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff
VBoxManage startvm "VulnLab-ad-lab-1"
```

### Low Performance

```bash
# Check allocated resources
VBoxManage showvminfo "VulnLab-ad-lab-1" | grep -E "Memory|CPU"

# Increase if needed
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096 --cpus 4

# Note: VM must be powered off to modify settings
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff
```

### Disk Full

```bash
# Check disk size
VBoxManage list media | grep -A 2 "VulnLab-ad-lab-1"

# Expand virtual disk (VDI only)
VBoxManage modifymedium "path/to/disk.vdi" --resize 40960  # 40GB

# Note: Must also expand partition inside VM:
# sudo parted /dev/sda resizepart 1 100%
# sudo resize2fs /dev/sda1
```

---

## Comparison: Vagrant vs VBoxManage

| Feature | Vagrant | VBoxManage |
|---------|---------|-----------|
| Setup complexity | ⭐ Simple | ⭐⭐⭐ Complex |
| Configuration | Vagrantfile | Shell scripts |
| OS provisioning | Automatic | Manual |
| Networking | Automatic | Manual |
| Reproducibility | High | Medium |
| Control | Limited | Full |
| Learning curve | Easy | Steep |
| Best for | Rapid iteration | Custom setups |

---

## Advanced Topics

### Clone VM

```bash
# Shut down source VM
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff

# Clone entire VM
VBoxManage clonevm "VulnLab-ad-lab-1" \
  --name "VulnLab-ad-lab-1-copy" \
  --register

# Or clone without snapshots
VBoxManage clonevm "VulnLab-ad-lab-1" \
  --name "VulnLab-ad-lab-1-copy" \
  --register \
  --mode machine
```

### Convert OVA to VDI

```bash
# Extract OVA (it's a TAR archive)
tar -xf lab-ad-lab-1.ova

# Convert disk
VBoxManage convertdd disk-0.vmdk disk.vdi --format VDI
```

### Remote Management

```bash
# Via SSH (requires VRDP enabled)
VBoxManage modifyvm "VulnLab-ad-lab-1" --vrde on
VBoxManage modifyvm "VulnLab-ad-lab-1" --vrdeport 5900

# Connect remotely
rdesktop localhost:5900
```

---

## Performance Tips

### Optimize for Many VMs

```bash
# Reduce memory per VM
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 1024  # 1GB instead of 2GB

# Reduce CPUs
VBoxManage modifyvm "VulnLab-ad-lab-1" --cpus 1  # 1 CPU instead of 2

# Use different disk type (faster)
# When creating: --format VDI or --format VMDK or --format VHD
```

### Parallel Startup

```bash
#!/bin/bash
# Start all VMs in parallel

for i in {1..5}; do
  VBoxManage startvm "VulnLab-ad-lab-$i" --type headless &
done

wait
echo "All VMs started"
```

---

## Reference

- **VirtualBox Manual**: https://www.virtualbox.org/manual/
- **VBoxManage Command Line**: https://www.virtualbox.org/manual/ch08.html
- **Ubuntu ISO Downloads**: https://releases.ubuntu.com/

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready
