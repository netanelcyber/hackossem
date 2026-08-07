# Active Directory Training Environment - Bash Scripts

Cross-platform Bash/Shell scripts for managing 10 Active Directory training VMs in VirtualBox.

## Overview

These Bash scripts provide the same functionality as the PowerShell scripts but work on:
- **Linux** (Ubuntu, Debian, Fedora, etc.)
- **macOS**
- **Windows** (WSL, Git Bash, or native with Cygwin)

## Prerequisites

### Required
- **VirtualBox 7.0+** - Hypervisor
- **Bash 4.0+** - Shell interpreter
- **VBoxManage** - VirtualBox command-line tool

### Optional but Recommended
- **jq** - JSON parser for better configuration handling
- **ssh/RDP client** - For connecting to VMs

### Installation

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y virtualbox virtualbox-dkms jq

# Optional: Add user to vboxusers group
sudo usermod -aG vboxusers $USER
```

#### macOS
```bash
# Using Homebrew
brew install virtualbox jq

# Or download from: https://www.virtualbox.org/wiki/Downloads
```

#### Windows (WSL)
```bash
# Install VirtualBox on Windows host
# Then in WSL:
sudo apt-get update
sudo apt-get install -y jq

# Configure WSL to access Windows VirtualBox
export VBOXMANAGE_PATH="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
```

#### macOS Intel (using native hypervisor)
```bash
brew install virtualbox colima jq

# For ARM64 (Apple Silicon) use UTM or parallel desktop
```

## Script Files

### 1. `ad_machines_setup.sh`
Initial setup script that creates 10 VMs with proper configuration.

**Usage:**
```bash
# Basic usage
bash ad_machines_setup.sh

# With custom parameters
VM_BASE_PATH=/mnt/vms \
DOMAIN_NAME=training.lab \
DOMAIN_ADMIN=Administrator \
DOMAIN_PASSWORD="P@ssw0rd123!" \
bash ad_machines_setup.sh
```

**What it does:**
- Creates VirtualBox VMs with configured resources
- Sets up network adapters (bridged)
- Generates PowerShell setup scripts for each VM
- Creates disk storage for each VM

**Output:**
- 10 VirtualBox VMs ready for OS installation
- PowerShell scripts in each VM directory for post-installation configuration

### 2. `manage_ad_machines.sh`
Main management script for VM lifecycle operations.

**Usage:**
```bash
# Show help
bash manage_ad_machines.sh help

# Show status of all VMs
bash manage_ad_machines.sh status

# Create all VMs
bash manage_ad_machines.sh create-all

# Start all VMs
bash manage_ad_machines.sh start-all

# Stop all VMs
bash manage_ad_machines.sh stop-all

# Delete all VMs (with confirmation)
bash manage_ad_machines.sh delete-all

# Manage individual VMs
bash manage_ad_machines.sh start AD-DC01
bash manage_ad_machines.sh stop AD-WS01
bash manage_ad_machines.sh delete AD-SQL01
```

**Configuration:**
```bash
# Use custom config file
bash manage_ad_machines.sh --config /path/to/config.json status

# Use custom base path
VM_BASE_PATH=/custom/path bash manage_ad_machines.sh status
```

### 3. `quick_setup.sh`
Interactive menu-driven setup script for beginners.

**Usage:**
```bash
# Interactive menu
bash quick_setup.sh

# Setup wizard with guided steps
bash quick_setup.sh --wizard

# Skip dependency check
bash quick_setup.sh --no-check

# Show help
bash quick_setup.sh --help
```

**Features:**
- Dependency verification
- Interactive menu
- Configuration preview
- Step-by-step wizard
- Quick command reference

## 10 Training Machines

All machines connect to domain `training.lab` on network `192.168.100.0/24`:

| # | Name | Role | IP | Memory | CPUs | Disk |
|---|------|------|----|---------|----|------|
| 1 | AD-DC01 | Domain Controller | 192.168.100.10 | 2GB | 2 | 50GB |
| 2 | AD-WS01 | Workstation | 192.168.100.20 | 2GB | 2 | 40GB |
| 3 | AD-WS02 | Workstation | 192.168.100.21 | 2GB | 2 | 40GB |
| 4 | AD-SRV01 | File Server | 192.168.100.30 | 2GB | 2 | 100GB |
| 5 | AD-SRV02 | File Server | 192.168.100.31 | 2GB | 2 | 100GB |
| 6 | AD-WS03 | Workstation | 192.168.100.22 | 2GB | 2 | 40GB |
| 7 | AD-WS04 | Workstation | 192.168.100.23 | 2GB | 2 | 40GB |
| 8 | AD-SQL01 | SQL Server | 192.168.100.40 | 4GB | 4 | 100GB |
| 9 | AD-MAIL01 | Mail Server | 192.168.100.50 | 3GB | 3 | 100GB |
| 10 | AD-WEB01 | Web Server | 192.168.100.60 | 2GB | 2 | 50GB |

## Quick Start

### Step 1: Check Prerequisites
```bash
# Make scripts executable
chmod +x *.sh

# Verify VirtualBox is installed
VBoxManage --version
```

### Step 2: Review Configuration
```bash
# View machine configuration
cat machines_config.json

# Or with jq for better readability
jq '.machines[] | {name, role, ip}' machines_config.json
```

### Step 3: Create VMs
```bash
# Option A: Interactive menu
bash quick_setup.sh

# Option B: Direct command
bash manage_ad_machines.sh create-all

# Option C: Custom setup
VM_BASE_PATH=/mnt/vms bash ad_machines_setup.sh
```

### Step 4: Start VMs
```bash
# Start all VMs
bash manage_ad_machines.sh start-all

# Check status
bash manage_ad_machines.sh status

# Start specific VM
bash manage_ad_machines.sh start AD-DC01
```

### Step 5: Install Windows
1. Open each VM in VirtualBox GUI
2. Boot from Windows Server 2022 ISO
3. Complete Windows installation
4. Install VirtualBox Guest Additions

### Step 6: Configure Domain
Inside each VM, run the generated `setup.ps1` PowerShell script to configure:
- Static IP address
- Computer name
- Domain joining
- Role-specific features

## Configuration

### Using `machines_config.json`
```bash
# View configuration
cat machines_config.json

# Modify configuration (backup first!)
cp machines_config.json machines_config.json.bak

# Edit with your editor
nano machines_config.json
# or
vim machines_config.json
```

### Environment Variables
```bash
# Set VM base path
export VM_BASE_PATH="/mnt/fast-ssd/vms"

# Set domain name
export DOMAIN_NAME="corp.internal"

# Set admin password
export DOMAIN_PASSWORD="YourSecurePassword123!"

# Use variables in scripts
bash manage_ad_machines.sh status
```

## Troubleshooting

### VBoxManage command not found
```bash
# On Linux/macOS
which VBoxManage

# On Windows (WSL)
ls "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"

# Add to PATH
export PATH="/mnt/c/Program Files/Oracle/VirtualBox:$PATH"
```

### Permission denied when creating VMs
```bash
# On Linux: Add user to vboxusers group
sudo usermod -aG vboxusers $USER
newgrp vboxusers

# Then logout and login again
```

### jq not found (optional but recommended)
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Scripts will still work without jq but with reduced functionality
```

### VMs won't start
```bash
# Check VirtualBox status
VBoxManage list vms

# Verify network settings
VBoxManage modifyvm AD-DC01 --nic1 bridged

# Check host adapter
VBoxManage list hostonlyifs
```

### Disk space issues
```bash
# Check available space
df -h /mnt/vms

# Compact VM disks (optional)
VBoxManage modifymedium /path/to/disk.vdi --compact

# Delete unused VMs
bash manage_ad_machines.sh delete AD-WS01
```

## Advanced Usage

### Batch Operations
```bash
# Create, configure, and start all VMs
bash ad_machines_setup.sh && \
sleep 5 && \
bash manage_ad_machines.sh status && \
bash manage_ad_machines.sh start-all
```

### Monitor VM Status
```bash
# Watch status in real-time
while true; do
    clear
    bash manage_ad_machines.sh status
    sleep 5
done
```

### Export VM Configurations
```bash
# Export all VM configurations to JSON
for vm in $(bash manage_ad_machines.sh status | grep AD- | awk '{print $1}'); do
    echo "Exporting $vm..."
    VBoxManage showvminfo "$vm" --machinereadable > "${vm}_config.txt"
done
```

### Create Snapshots Before Domain Join
```bash
# Create snapshot for each VM before joining domain
for vm in AD-WS01 AD-WS02 AD-WS03 AD-WS04; do
    echo "Creating snapshot for $vm..."
    VBoxManage snapshot "$vm" take "before-domain-join"
done
```

## Performance Optimization

### Increase Allocated Resources
Edit `machines_config.json`:
```json
{
  "resources": {
    "memory_mb": 4096,
    "cpus": 4,
    "disk_mb": 102400
  }
}
```

### Use SSD for VM Storage
```bash
# Create VMs on fast SSD
VM_BASE_PATH=/mnt/nvme-ssd bash manage_ad_machines.sh create-all
```

### Enable 3D Acceleration (carefully)
```bash
# Enable for specific VM
VBoxManage modifyvm AD-DC01 --accelerate3d on
```

## Networking

### Bridge to Specific Network Adapter
```bash
# List available adapters
VBoxManage list hostonlyifs

# Use specific adapter
VBoxManage modifyvm AD-DC01 --bridgeadapter1 "eth0"
```

### Change Network from Bridged to NAT
```bash
for vm in AD-DC01 AD-WS01 AD-WS02; do
    VBoxManage modifyvm "$vm" --nic1 nat
done
```

## Backup and Recovery

### Backup VM Configurations
```bash
# Backup all VMs
VBoxManage export AD-DC01 -o AD-DC01-backup.ova
VBoxManage export AD-WS01 -o AD-WS01-backup.ova

# Backup to external drive
VBoxManage export AD-DC01 -o /mnt/backup/AD-DC01-backup.ova
```

### Restore from Backup
```bash
# Import OVA backup
VBoxManage import AD-DC01-backup.ova
```

## Resources

- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [VBoxManage Reference](https://www.virtualbox.org/manual/ch08.html)
- [Active Directory Documentation](https://docs.microsoft.com/en-us/windows-server/identity/identity-and-access)
- [Bash Manual](https://www.gnu.org/software/bash/manual/)

## Compatibility Matrix

| OS | Bash | VirtualBox | Status |
|-------|------|--------------|--------|
| Linux (Ubuntu 20.04+) | ✓ | ✓ | Fully supported |
| Linux (Debian 11+) | ✓ | ✓ | Fully supported |
| macOS (Intel) | ✓ | ✓ | Fully supported |
| macOS (Apple Silicon) | ✓ | ⚠️ | Beta (use UTM/Parallels) |
| Windows WSL2 | ✓ | ✓ | Fully supported |
| Windows Git Bash | ✓ | ✓ | Fully supported |
| Windows Cygwin | ✓ | ⚠️ | Partial support |

## Support

For issues:
1. Check the troubleshooting section
2. Verify all prerequisites are installed
3. Check VirtualBox logs: `~/.config/VirtualBox/VBoxSVC.log`
4. Run scripts with bash -x for debugging:
   ```bash
   bash -x manage_ad_machines.sh status
   ```

## License

These scripts are provided as-is for educational purposes.

---

**Version**: 1.0
**Last Updated**: August 2024
**Tested On**: Ubuntu 22.04 LTS, macOS 12.x, Windows 11 WSL2
