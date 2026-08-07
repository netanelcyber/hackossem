# Active Directory Training Environment - Full Automation Guide

Complete automation of 10 AD training machines in VirtualBox using Bash scripts.

## Overview

This guide covers **fully automated deployment** of all 10 VMs with:
- ✅ Automatic VM creation
- ✅ Unattended Windows Server installation
- ✅ Automatic network configuration
- ✅ Automatic domain joining
- ✅ Automatic feature installation
- ✅ Comprehensive logging and monitoring

## Automation Scripts

### 1. `automate_ad_setup.sh` - Basic Automation
Automated setup with unattend.xml for Windows Server.

**Usage:**
```bash
# Basic automated setup
chmod +x automate_ad_setup.sh
./automate_ad_setup.sh

# With custom parameters
ISO_PATH="/path/to/windows-server.iso" \
VM_BASE_PATH="/mnt/fast-ssd/vms" \
DOMAIN_NAME="corp.internal" \
./automate_ad_setup.sh
```

**What it does:**
1. ✓ Verifies prerequisites
2. ✓ Creates all 10 VMs
3. ✓ Generates unattend.xml for each VM
4. ✓ Injects ISO and starts installation
5. ✓ Waits for VMs to boot
6. ✓ Provides completion report

**Features:**
- XML-based unattended installation
- Automatic hostname and network setup
- Admin password configuration
- Role-specific feature injection
- Comprehensive logging
- Color-coded output

**Output:**
```
[INFO] Domain: training.lab
[INFO] Configuration loaded: machines_config.json
[✓] VirtualBox found: 7.0.10r158379
[✓] All prerequisites satisfied

[STEP] Creating VMs
[INFO] Creating VM: AD-DC01
[✓] Created unattend.xml for AD-DC01
[✓] AD-DC01 configured
...
[✓] Automation complete!
```

### 2. `orchestrate_deployment.sh` - Full Orchestration
End-to-end deployment with state management and recovery.

**Usage:**
```bash
# Full orchestration
chmod +x orchestrate_deployment.sh
./orchestrate_deployment.sh

# Resume interrupted deployment
./orchestrate_deployment.sh
# Will ask to resume from last stage
```

**Deployment Stages:**
```
Stage 0: Check Prerequisites
├─ Verify VirtualBox, jq, config file
├─ Display configuration
└─ Initialize logging

Stage 1: Create Virtual Machines
├─ Create 10 VMs with specifications
├─ Configure network and storage
└─ Setup IDE/SATA controllers

Stage 2: Start OS Installation
├─ Start all VMs in headless mode
├─ Boot from Windows Server ISO
└─ Begin unattended installation

Stage 3: Configure VMs
├─ Wait for OS installation (15-30 min)
├─ Verify network reachability
└─ Monitor boot completion

Stage 4: Monitor Domain Join
├─ Trigger automated domain join
├─ Wait for PowerShell scripts
└─ Monitor configuration progress

Stage 5: Monitoring Dashboard
├─ Display VM status
├─ Check network connectivity
└─ Generate status report

Stage 6: Complete
├─ Verify all VMs
├─ Display next steps
└─ Generate final report
```

**Features:**
- State management (resume from interruption)
- Detailed logging to file
- Stage-by-stage progress
- Automatic prerequisite checking
- Network reachability verification
- Error recovery

**Resume Capability:**
```bash
# If deployment is interrupted (Ctrl+C), run again:
./orchestrate_deployment.sh
# It will detect the last completed stage and resume from there
```

## Automated Installation Details

### Unattend.xml Generation

Automatically generated Windows Server answer file includes:
- ✅ Disk partitioning (500MB EFI + remainder data)
- ✅ NTFS formatting
- ✅ Windows Server 2022 installation
- ✅ Automatic Administrator setup
- ✅ Network configuration (DHCP → static via PowerShell)
- ✅ Computer name assignment
- ✅ PowerShell execution on first logon

### First Logon Automation

The `setup.ps1` script runs automatically with:
```powershell
# Network Configuration
- Set static IP based on config
- Configure default gateway
- Set DNS servers
- Rename computer

# Role-Based Configuration
For Domain Controllers:
  - Install AD-Domain-Services
  - Install DNS
  - Create forest
  - Setup DHCP (optional)

For Workstations:
  - Join domain
  - Configure network
  - Update policies

For Servers (File/SQL/Mail/Web):
  - Install role-specific features
  - Join domain
  - Configure services
```

## Quick Start: Full Automation

### Step 1: Prepare Environment
```bash
# Ensure VirtualBox and dependencies installed
sudo apt-get update
sudo apt-get install -y virtualbox virtualbox-dkms jq

# Download Windows Server ISO (if not already)
# Place at: /mnt/iso/windows-server-2022.iso
```

### Step 2: Configure Settings
```bash
# Optional: Edit machines_config.json
# Default settings are usually fine
nano machines_config.json
```

### Step 3: Run Full Automation
```bash
# Make scripts executable
chmod +x *.sh

# Start orchestration
./orchestrate_deployment.sh

# At prompt, answer "yes" to begin
```

### Step 4: Monitor Progress
```bash
# In another terminal, monitor status
while true; do
    clear
    ./manage_ad_machines.sh status
    sleep 30
done
```

### Step 5: Verify Completion
```bash
# Check log file
tail -f /mnt/vms/logs/deployment_*.log

# Verify all VMs running
./manage_ad_machines.sh status

# Check domain controller
ssh Administrator@192.168.100.10
# Then run: dcdiag /v
```

## Timing Expectations

### Full Deployment Timeline:

| Stage | Time | Activity |
|-------|------|----------|
| Prerequisites Check | 1-2 min | Verify tools and config |
| VM Creation | 5-10 min | Create 10 VMs with storage |
| Installation Start | 2 min | Start VMs and boot |
| Windows Installation | 15-30 min | Unattended OS setup (per VM) |
| Configuration | 10-20 min | Features and domain join |
| Domain Stabilization | 5-10 min | Replication and policies |
| **Total** | **40-70 min** | Complete deployment |

## Logging and Diagnostics

### Log Files

```bash
# Main deployment log
/mnt/vms/logs/deployment_YYYYMMDD_HHMMSS.log

# State tracking
/mnt/vms/logs/state.log

# View logs
tail -f /mnt/vms/logs/deployment_*.log

# Full log (all output)
cat /mnt/vms/logs/deployment_*.log | less
```

### Log Format

```
[2024-08-07 12:30:45] [INFO] Domain: training.lab
[2024-08-07 12:30:45] [SUCCESS] VirtualBox: 7.0.10
[2024-08-07 12:31:00] [STAGE] Creating VMs
[2024-08-07 12:31:15] [INFO] Creating VM: AD-DC01
[2024-08-07 12:31:30] [SUCCESS] AD-DC01 created
[2024-08-07 12:35:00] [ERROR] Failed to attach ISO
[2024-08-07 12:35:01] [WARN] Continuing without ISO
```

## Troubleshooting Automated Deployment

### Issue: VBoxManage command not found
```bash
# Add VirtualBox to PATH
export PATH="/opt/VirtualBox:$PATH"

# Or use full path in script
/opt/VirtualBox/VBoxManage showvminfo AD-DC01
```

### Issue: jq not found
```bash
# Install jq (required for JSON parsing)
sudo apt-get install jq

# Or: brew install jq (on macOS)
```

### Issue: Permission denied creating VMs
```bash
# Add current user to vboxusers group
sudo usermod -aG vboxusers $USER

# Apply changes
newgrp vboxusers

# Verify
groups
# Should show: vboxusers
```

### Issue: VM creation fails
```bash
# Check disk space
df -h /mnt/vms
# Need ~100GB free

# Check VirtualBox service
sudo systemctl status virtualbox

# Check VirtualBox logs
cat ~/.config/VirtualBox/VBoxSVC.log
```

### Issue: Windows installation hangs
```bash
# Check VM console
VBoxManage controlvm AD-DC01 keyboardputscancode ...

# Or via GUI
VirtualBox &
# Select VM and click "Show"

# If stuck, power off and retry
VBoxManage controlvm AD-DC01 poweroff
```

### Issue: Domain join fails
```bash
# Verify DC is running
./manage_ad_machines.sh status | grep AD-DC01

# Verify network
ping 192.168.100.10

# Check DNS resolution
nslookup training.lab 192.168.100.10

# Manual fix in VM
# 1. SSH to the VM
# 2. Run: Add-Computer -DomainName training.lab -Credential $creds -Force
```

### Issue: Resuming deployment asks for confirmation
```bash
# This is normal - choose "yes" to resume from last stage
# Or delete state file to start fresh:
rm /mnt/vms/logs/state.log
./orchestrate_deployment.sh
```

## Advanced Automation

### Customize Installation

Edit `machines_config.json` to change:
```json
{
  "machines": [
    {
      "name": "AD-DC01",
      "resources": {
        "memory_mb": 2048,      // Change RAM
        "cpus": 2,              // Change CPUs
        "disk_mb": 51200        // Change disk size
      }
    }
  ]
}
```

### Automate with Cron

Schedule repeated deployments:
```bash
# Edit crontab
crontab -e

# Add entry (deploy every Sunday at 2 AM)
0 2 * * 0 cd /home/user/hackossem && ./orchestrate_deployment.sh >> /tmp/ad_deploy.log 2>&1
```

### Parallel VM Creation

Increase parallel VM creation:
```bash
# Create 4 VMs in parallel
PARALLEL_JOBS=4 ./orchestrate_deployment.sh
```

### Custom ISO Path

```bash
# Use specific Windows Server ISO
ISO_PATH="/path/to/custom/windows-server-ltsc-2022.iso" \
./automate_ad_setup.sh
```

### Headless Monitoring

Run without GUI:
```bash
# Terminal 1: Start deployment
./orchestrate_deployment.sh

# Terminal 2: Monitor
watch -n5 './manage_ad_machines.sh status'

# Terminal 3: View logs
tail -f /mnt/vms/logs/deployment_*.log
```

## Automated Backup

Create backups of automated setup:
```bash
#!/bin/bash
# backup_vms.sh - Backup all VMs after deployment

for vm in AD-DC01 AD-WS01 AD-WS02; do
    echo "Backing up $vm..."
    VBoxManage export "$vm" -o "/mnt/backup/${vm}_$(date +%Y%m%d).ova"
done

echo "Backups complete in /mnt/backup/"
```

## Performance Optimization

### Speed Up Installation

```bash
# Reduce VBox overhead
# Use SSD for VMs
VM_BASE_PATH="/mnt/nvme-ssd/vms" ./orchestrate_deployment.sh

# Increase resources
# Edit machines_config.json and increase CPU/RAM

# Enable 3D acceleration (use carefully)
VBoxManage modifyvm AD-DC01 --accelerate3d on
```

### Parallel Startups

```bash
# Start multiple VMs simultaneously
for vm in AD-DC01 AD-WS01 AD-WS02 AD-SRV01 AD-SRV02; do
    VBoxManage startvm "$vm" --type headless &
done
wait
```

## Cleanup and Reset

### Delete All VMs and Start Fresh
```bash
# Delete all VMs
./manage_ad_machines.sh delete-all

# Reset deployment state
rm /mnt/vms/logs/state.log

# Clean logs
rm -f /mnt/vms/logs/*.log

# Start fresh deployment
./orchestrate_deployment.sh
```

### Archive Logs
```bash
# Backup logs before cleanup
tar -czf /backup/ad-deployment-logs-$(date +%Y%m%d).tar.gz /mnt/vms/logs/

# Clean logs
rm /mnt/vms/logs/*.log
```

## Verification Checklist

After automated deployment completes:

- [ ] All 10 VMs created in VirtualBox
- [ ] All VMs showing as "running" in status
- [ ] AD-DC01 reachable at 192.168.100.10
- [ ] Domain "training.lab" exists
- [ ] All machines joined to domain (check AD Users & Computers)
- [ ] DNS resolving correctly
- [ ] Network connectivity between all VMs
- [ ] Log file generated without errors
- [ ] Each VM has correct role configured

```bash
# Quick verification script
#!/bin/bash
echo "=== Verification Checklist ==="

echo -n "VMs created: "
VBoxManage list vms | wc -l

echo -n "VMs running: "
VBoxManage list runningvms | wc -l

echo -n "DC reachable: "
ping -c 1 192.168.100.10 && echo "YES" || echo "NO"

echo -n "Domain reachable: "
nslookup training.lab 192.168.100.10 | grep -q "training.lab" && echo "YES" || echo "NO"

echo -n "Log file exists: "
[ -f /mnt/vms/logs/deployment_*.log ] && echo "YES" || echo "NO"

echo "=== End Checklist ==="
```

## Resource Requirements

### Minimum for Automation:
- CPU: 4 cores (8+ recommended)
- RAM: 16GB (32GB recommended)
- Disk: 500GB (SSD recommended)
- Network: 1 Gbps

### Full 10-VM System:
- CPU: 8+ cores
- RAM: 32GB+
- Disk: 800GB+ SSD
- Network: 1 Gbps managed switch (or bridged)

## Support and Debugging

### Verbose Output
```bash
# Run with debug output
bash -x ./orchestrate_deployment.sh 2>&1 | tee debug.log
```

### Check State
```bash
# View deployment state history
cat /mnt/vms/logs/state.log

# Last 10 log entries
tail -10 /mnt/vms/logs/deployment_*.log
```

### Manual Intervention
```bash
# If automation fails, manually:
1. Check VM status: ./manage_ad_machines.sh status
2. Connect to VM: ssh Administrator@192.168.100.10
3. Check services: Get-Service | Where-Object {$_.Status -eq "Running"}
4. View logs: Get-EventLog System -Newest 20
```

## References

- [VirtualBox CLI Documentation](https://www.virtualbox.org/manual/ch08.html)
- [Windows Unattend.xml Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [PowerShell Remote Management](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/10-working-with-objects)
- [Active Directory Deployment](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/)

---

**Version**: 1.0
**Last Updated**: August 2024
**Tested On**: Ubuntu 22.04 LTS, VirtualBox 7.0
