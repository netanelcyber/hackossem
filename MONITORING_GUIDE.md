# Active Directory Deployment - Monitoring Guide

Complete guide to monitoring the automated deployment of 10 AD training VMs.

## Real-Time Monitoring

### Method 1: Built-in Monitor Script (Recommended)

```bash
# Start real-time monitoring dashboard
chmod +x monitor_deployment.sh
./monitor_deployment.sh
```

**Dashboard shows:**
- Total VMs created
- Running vs Stopped VMs
- Each VM status (online/booting/offline)
- Live log entries
- Installation progress statistics

**Custom refresh rate:**
```bash
# Update every 10 seconds instead of default 5
REFRESH_INTERVAL=10 ./monitor_deployment.sh
```

### Method 2: Manual Status Checking

```bash
# Terminal 1: Start orchestration
./orchestrate_deployment.sh

# Terminal 2: Monitor status
while true; do
    clear
    ./manage_ad_machines.sh status
    sleep 10
done
```

### Method 3: VirtualBox GUI

```bash
# Open VirtualBox GUI to see VMs visually
VirtualBox &
```

**What to look for:**
- VM boot progress
- Windows Setup loading
- Installation file copying
- First boot completion

## Installation Timeline

### 0-5 Minutes: VM Boot
```
[✓] VM started
[✓] BIOS/UEFI POST
[✓] Boot from ISO
```

### 5-15 Minutes: Setup Loading
```
[✓] Windows Setup initializing
[✓] Loading drivers
[✓] Scanning disk
[✓] Unattend.xml applied
```

### 15-45 Minutes: Windows Installation
```
[✓] Copying Windows files
[✓] Installing Windows
[✓] Installing drivers
[✓] Configuring system
```

### 45-60 Minutes: First Boot
```
[✓] Windows booting
[✓] Drivers initializing
[✓] Services starting
[✓] setup.ps1 running (PowerShell automation)
```

### 60+ Minutes: Automation & Configuration
```
[✓] Hostname configuration
[✓] Network configuration
[✓] Domain joining
[✓] Feature installation
[✓] Restart for domain join
```

## Monitoring Commands

### Check VM Status
```bash
# Quick status
./manage_ad_machines.sh status

# Detailed VirtualBox info
VBoxManage showvminfo AD-DC01 --machinereadable

# Network connectivity test
ping 192.168.100.10
nslookup training.lab 192.168.100.10
```

### View Logs

```bash
# Latest deployment log
tail -f /mnt/vms/logs/deployment_*.log

# Grep for errors
grep ERROR /mnt/vms/logs/deployment_*.log

# Follow all new entries
tail -F /mnt/vms/logs/deployment_*.log | head -20

# Count events by type
grep SUCCESS /mnt/vms/logs/deployment_*.log | wc -l
grep ERROR /mnt/vms/logs/deployment_*.log | wc -l
grep WARN /mnt/vms/logs/deployment_*.log | wc -l
```

### Check Individual VM Status

```bash
# Check if running
VBoxManage showvminfo AD-DC01 | grep "State:"

# Get IP address (once booted)
VBoxManage guestproperty enumerate AD-DC01

# Check CPU usage
VBoxManage metrics collect

# View VM console output
VBoxManage controlvm AD-DC01 screenshot screenshot.png
```

## What to Expect

### Expected Log Output During Installation

**Stage 1: Creation (5-10 min)**
```
[STAGE] Creating Virtual Machines
[INFO] Creating VM: AD-DC01...
[✓] AD-DC01 created
[INFO] Creating VM: AD-WS01...
[✓] AD-WS01 created
...
[SUCCESS] 10 created, 0 failed
```

**Stage 2: Installation Start (1-2 min)**
```
[STAGE] Starting VMs for OS Installation
[INFO] Starting AD-DC01...
[✓] AD-DC01 started
[INFO] Starting AD-WS01...
[✓] AD-WS01 started
...
[SUCCESS] All VMs started (10/10)
```

**Stage 3: Boot Waiting (15-45 min)**
```
[STAGE] Configuring VMs - Waiting for Installation
[INFO] Waiting for AD-DC01 (DomainController) at 192.168.100.10...
  Waiting for boot...  15% (2/30min)
  Waiting for boot...  45% (13/30min)
[✓] AD-DC01 is reachable at 192.168.100.10
[INFO] Waiting for AD-WS01 (Workstation) at 192.168.100.20...
...
```

### Expected Timeframes Per VM

| VM | Role | Boot Time | Install Time | Total |
|-------|------|-----------|--------------|-------|
| AD-DC01 | DC | 2-3 min | 20-30 min | 25-35 min |
| AD-WS01-04 | Workstation | 2-3 min | 15-25 min | 20-30 min |
| AD-SRV01-02 | File Server | 2-3 min | 15-25 min | 20-30 min |
| AD-SQL01 | SQL Server | 2-3 min | 20-30 min | 25-35 min |
| AD-MAIL01 | Mail Server | 2-3 min | 20-30 min | 25-35 min |
| AD-WEB01 | Web Server | 2-3 min | 15-25 min | 20-30 min |

**Staggered approach:** VMs start at different times, so total time is less than sum

## Troubleshooting During Deployment

### VM Not Booting

```bash
# Check VM status
VBoxManage showvminfo AD-DC01 | grep State

# Check if ISO is attached
VBoxManage showvminfo AD-DC01 | grep "IDE"

# Power off and retry
VBoxManage controlvm AD-DC01 poweroff
sleep 5
VBoxManage startvm AD-DC01 --type headless
```

### Stuck on Installation Screen

```bash
# Check if process is actually running
ps aux | grep VBox

# View VM console (in VirtualBox GUI)
# Select VM → Show → Watch installation progress

# If truly stuck, power off:
VBoxManage controlvm AD-DC01 poweroff
```

### Not Reachable After 30+ Minutes

```bash
# Check if VM is running
VBoxManage list runningvms | grep AD-DC01

# Try pinging again with higher timeout
ping -c 1 -W 5 192.168.100.10

# Check network configuration in VirtualBox
VBoxManage showvminfo AD-DC01 | grep -i network

# View VM console to see if stuck at login
VirtualBox &  # Open GUI and check
```

### High CPU/Disk Usage (Expected)

```bash
# During installation, CPU should be high
top -b -n 1 | head -15

# Monitor disk I/O
iostat -x 1 5

# This is normal during Windows installation - files are being written
```

## Monitoring Checklist

### Before Deployment
- [ ] VirtualBox installed and running
- [ ] ISO file available
- [ ] Disk space available (800GB+)
- [ ] RAM available (32GB+)
- [ ] Network configured (bridged)
- [ ] Configuration file valid (jq . machines_config.json)

### During Deployment
- [ ] Monitor script running (./monitor_deployment.sh)
- [ ] Log file being created (/mnt/vms/logs/deployment_*.log)
- [ ] VMs appearing in VirtualBox list
- [ ] VMs starting (status: running)
- [ ] Network traffic visible
- [ ] CPU usage elevated (installation in progress)

### Completion Indicators
- [ ] All 10 VMs "running" in status
- [ ] All VMs responding to ping
- [ ] Log file shows completion stages
- [ ] No ERROR entries in log
- [ ] orchestrate_deployment.sh exits normally

## Post-Deployment Verification

```bash
# 1. All VMs created?
VBoxManage list vms | wc -l
# Should show: 10

# 2. All VMs running?
VBoxManage list runningvms | wc -l
# Should show: 10

# 3. DC reachable?
ping -c 1 192.168.100.10

# 4. DNS working?
nslookup AD-DC01.training.lab 192.168.100.10

# 5. Domain exists?
nslookup training.lab 192.168.100.10

# 6. All IPs responding?
for ip in 192.168.100.{10..60}; do
    ping -c 1 -W 2 $ip &>/dev/null && echo "$ip - OK" || echo "$ip - NO"
done
```

## Performance Optimization Tips

### Speed Up Installation

```bash
# Use faster disk
VM_BASE_PATH=/mnt/nvme-ssd/vms ./orchestrate_deployment.sh

# Allocate more resources
# Edit machines_config.json to increase memory/CPUs

# Start only critical VMs first
# Edit machines_config.json to change order
```

### Monitor Performance

```bash
# CPU usage
watch -n 1 'grep "^cpu " /proc/stat'

# Memory usage
free -h

# Disk I/O
iostat -x 2

# Network traffic
nethogs
```

## Recovery from Interruption

### Resume Deployment

```bash
# If Ctrl+C during orchestration:
./orchestrate_deployment.sh

# It will ask:
# Resume from last stage? (yes/no): yes

# Continues from:
# Stage 0: Check Prerequisites
# Stage 1: Create VMs (skipped if done)
# Stage 2: Start VMs (skipped if running)
# Stage 3: Configuration (waits for boot)
# etc.
```

### Manual Recovery

```bash
# If state file lost but VMs exist:
rm /mnt/vms/logs/state.log

# Check existing VMs:
VBoxManage list vms

# Continue manually:
./orchestrate_deployment.sh  # Will start from Stage 0
```

## Advanced Monitoring

### VirtualBox Event Monitoring

```bash
# Monitor VirtualBox events in real-time
VBoxManage list vms --verbose | grep -i state

# Watch for state changes
while true; do
    VBoxManage list runningvms
    sleep 5
done
```

### Resource Usage Tracking

```bash
# Create monitoring script
#!/bin/bash
while true; do
    echo "=== $(date) ==="
    echo "VMs Running: $(VBoxManage list runningvms | wc -l)"
    free -h | grep Mem
    df -h | grep vms
    sleep 60
done | tee monitoring.log
```

### Network Monitoring

```bash
# Monitor network activity
tcpdump -i eth0 -n host 192.168.100.0/24

# Monitor DNS queries
tcpdump -i eth0 -n udp port 53

# Watch DHCP traffic (initial network setup)
tcpdump -i eth0 -n udp port 67-68
```

## Expected Log File Size

```bash
# Monitor log file growth
watch -n 5 'ls -lh /mnt/vms/logs/deployment_*.log'

# Expected growth:
# 0-10 min:  ~50KB
# 10-30 min: ~100KB
# 30-60 min: ~200-300KB
# Total:     ~500KB-1MB (typical)
```

## Completion Success Criteria

Deployment is successful when:

✅ All stages complete without ERROR entries
✅ All 10 VMs are "running"
✅ All VMs respond to ping
✅ orchestrate_deployment.sh exits cleanly
✅ Log shows completion messages
✅ DC reachable at 192.168.100.10
✅ Domain "training.lab" exists
✅ All machines joined to domain

## Quick Reference

```bash
# Start monitoring
./monitor_deployment.sh

# Check status
./manage_ad_machines.sh status

# View logs
tail -f /mnt/vms/logs/deployment_*.log

# DC access
ssh Administrator@192.168.100.10

# Stop everything
./manage_ad_machines.sh stop-all

# Delete everything and start over
./manage_ad_machines.sh delete-all
```

---

**Next Step**: Once all VMs are booted and domain-joined, proceed to verify AD connectivity and test training scenarios.

