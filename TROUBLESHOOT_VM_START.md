# 🔧 Troubleshooting: "Failed to start VulnLab-ad-lab-1"

## Quick Diagnosis

Run the diagnostic tool first:

```bash
chmod +x diagnose-vbox.sh
./diagnose-vbox.sh
```

This will show you the exact cause of the startup failure.

---

## Common Causes & Solutions

### 1️⃣ VM Doesn't Exist

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
VBoxManage: error: Could not find a registered machine named 'VulnLab-ad-lab-1'
```

**Diagnosis:**
```bash
VBoxManage list vms
# If 'VulnLab-ad-lab-1' not in list → VM not created
```

**Solution:**
```bash
# Create VMs first
./create-vms-vboxmanage.sh

# Or import from OVA file
VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname "VulnLab-ad-lab-1"
```

---

### 2️⃣ VirtualBox Service Not Running

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
VBoxManage: error: The IPC socket for the VirtualBox user session is not accessible
```

**Diagnosis:**
```bash
ps aux | grep VBox
# Should show VBoxSVC and/or VirtualBoxVM
```

**Solution:**
```bash
# Restart VirtualBox service
sudo systemctl restart virtualbox

# Or manually restart kernel module
sudo modprobe -r vboxdrv
sudo modprobe vboxdrv

# Try again
VBoxManage startvm "VulnLab-ad-lab-1" --type headless
```

---

### 3️⃣ Hardware Virtualization Not Enabled

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
VBoxManage: error: This kernel does not support VT-x/AMD-V hardware virtualization
```

**Diagnosis:**
```bash
# Check CPU virtualization support
grep -E "vmx|svm" /proc/cpuinfo

# If empty → virtualization not enabled
```

**Solution:**
1. **Restart computer**
2. **Enter BIOS** (usually Delete, F2, or F10 during startup)
3. **Find virtualization setting:**
   - Intel CPU: "VT-x", "Intel VT", or "Virtualization Technology"
   - AMD CPU: "AMD-V", "Virtualization", or "SVM"
4. **Enable it**
5. **Save and reboot**
6. **Try again:**
   ```bash
   VBoxManage startvm "VulnLab-ad-lab-1" --type headless
   ```

---

### 4️⃣ Insufficient Memory

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
VBoxManage: error: Not enough VRAM on the host machine
```

**Diagnosis:**
```bash
# Check available memory
free -h

# Check VM memory allocation
VBoxManage showvminfo "VulnLab-ad-lab-1" | grep "Memory size"
```

**Solution:**
```bash
# Reduce VM memory (if necessary)
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 1024
# Or increase host RAM

# Or stop other VMs/applications
killall firefox
killall chrome

# Try again
VBoxManage startvm "VulnLab-ad-lab-1" --type headless
```

---

### 5️⃣ VM Corrupted or Misconfigured

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
VBoxManage: error: Invalid machine UUID
```

**Diagnosis:**
```bash
# Get VM details
VBoxManage showvminfo "VulnLab-ad-lab-1" --compact

# Check for errors in output
```

**Solution:**
```bash
# Option A: Recreate VM
VBoxManage unregistervm "VulnLab-ad-lab-1" --delete
./create-vms-vboxmanage.sh

# Option B: Repair VM
VBoxManage list vms    # Note exact UUID
VBoxManage modifyvm "VulnLab-ad-lab-1" --uuid "NEW-UUID"

# Then try to start
VBoxManage startvm "VulnLab-ad-lab-1" --type headless
```

---

### 6️⃣ Cloud Environment (No VirtualBox Available)

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
(or VBoxManage command not found)
```

**Why It Fails:**
- Cloud environments don't have VirtualBox
- No hardware virtualization access
- No local machine resources

**Solution - Use Docker Instead:**
```bash
# This works in cloud environments
docker-compose up

# Access via http://localhost:5000
curl http://localhost:5000
```

**Or Use Vagrant Locally:**
```bash
# On your LOCAL machine (not cloud)
cd lab-vms-vagrant
vagrant up
vagrant ssh ad-lab-1
```

---

### 7️⃣ Port/Network Conflicts

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
(Starts briefly then stops)
```

**Diagnosis:**
```bash
# Check for port conflicts
lsof -i :2049  # SSH port
lsof -i :5001  # App port

# Check host-only network
VBoxManage list hostonlyifs
```

**Solution:**
```bash
# Kill process using port
sudo kill -9 <PID>

# Or change VM port forwarding
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 delete "SSH"
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 "SSH,tcp,,2050,,22"

# Restart VM
VBoxManage startvm "VulnLab-ad-lab-1" --type headless
```

---

### 8️⃣ Disk Space Full

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
(Or very slow startup)
```

**Diagnosis:**
```bash
# Check disk space
df -h /

# Check VirtualBox disk directory
du -sh ~/VirtualBox\ VMs/
```

**Solution:**
```bash
# Delete unused VMs
VBoxManage unregistervm "Old-VM" --delete

# Or clean up disk
rm -rf ~/.cache/*
sudo apt-get clean

# Or expand disk
# (See VirtualBox documentation)

# Try again
VBoxManage startvm "VulnLab-ad-lab-1" --type headless
```

---

### 9️⃣ VirtualBox Not Installed

**Error Symptom:**
```
❌ VBoxManage: command not found
```

**Solution:**
```bash
# Install VirtualBox
sudo apt-get update
sudo apt-get install virtualbox

# Verify installation
VBoxManage --version

# Try again
./create-vms-vboxmanage.sh
```

---

### 🔟 Nested Virtualization (VM in VM)

**Error Symptom:**
```
❌ Failed to start VulnLab-ad-lab-1
(Running VirtualBox inside another VM)
```

**Why It Fails:**
- VirtualBox cannot run inside another VM by default
- Nested virtualization requires special configuration

**Solution:**
```bash
# Run on actual hardware instead
# Not on VMware, Hyper-V, or cloud VMs

# Or use Docker (works in nested VMs)
docker-compose up
```

---

## Debug Mode: Detailed Error Output

```bash
# Start VM with verbose output
VBoxManage startvm "VulnLab-ad-lab-1" --type headless 2>&1 | tee vm-start.log

# This creates vm-start.log with detailed error messages
cat vm-start.log
```

---

## Check VM Logs

```bash
# Find VirtualBox logs
ls -la ~/.config/VirtualBox/

# View main VirtualBox log
cat ~/.config/VirtualBox/VBoxSVC.log | tail -50

# View specific VM log
cat ~/.config/VirtualBox/Machines/VulnLab-ad-lab-1/Logs/VBox.log | tail -50
```

---

## Escalation: Getting Help

If none of these solutions work:

1. **Collect diagnostic info:**
   ```bash
   ./diagnose-vbox.sh > diagnosis.txt
   ```

2. **Include in issue:**
   - Output of `diagnosis.txt`
   - VirtualBox version: `VBoxManage --version`
   - Host OS: `uname -a`
   - Error message from VM startup

3. **Create GitHub issue:**
   https://github.com/netanelcyber/hackossem/issues

---

## Prevention Checklist

Before starting VMs:

- [ ] VirtualBox installed (`VBoxManage --version`)
- [ ] Hardware virtualization enabled (check BIOS)
- [ ] At least 10GB free disk space
- [ ] At least 10GB free RAM (for 5 VMs)
- [ ] No conflicting processes (killall firefox, etc.)
- [ ] VirtualBox service running
- [ ] VMs created (`VBoxManage list vms`)

---

## Quick Fixes (Try These First)

```bash
# 1. Restart VirtualBox service
sudo systemctl restart virtualbox

# 2. Kill and restart VBoxSVC
sudo pkill VBoxSVC
VBoxManage startvm "VulnLab-ad-lab-1" --type headless

# 3. Modprobe reload
sudo modprobe -r vboxdrv && sudo modprobe vboxdrv

# 4. Complete system reboot
sudo reboot

# 5. Run diagnostic
./diagnose-vbox.sh
```

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready
