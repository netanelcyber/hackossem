# VirtualBox Setup Guide for VulnLabWizard

## 📋 Prerequisites

### System Requirements
```
OS: Windows 10/11 or Windows Server 2019+
RAM: 10GB minimum (40GB recommended for all 20 labs simultaneous)
Disk: 150GB+ free space
CPU: Intel/AMD with virtualization enabled (VT-x/AMD-V)
```

### Software Installation

#### 1. Install VirtualBox 7.0+
```powershell
# Using Chocolatey (recommended)
choco install virtualbox -y

# Or download from: https://www.virtualbox.org/wiki/Downloads
# Then run installer as Administrator
```

#### 2. Verify VirtualBox Installation
```powershell
# Check VirtualBox is installed and in PATH
VBoxManage --version

# Expected output: 7.0.x or higher
```

#### 3. Create Host-Only Network (Important!)
```powershell
# Open VirtualBox Manager
VirtualBox.exe

# Menu: File → Host Network Manager

# Create new network with these settings:
# - Name: vboxnet0
# - IPv4 Address: 192.168.56.1
# - IPv4 Mask: 255.255.255.0
# - DHCP Server: Disabled (we use static IPs)
```

Or via command line:
```powershell
# Create host-only network
VBoxManage hostonlyif create

# Configure network
VBoxManage hostonlyif ipconfig vboxnet0 --ipv4 192.168.56.1 --netmask 255.255.255.0
```

---

## 🚀 Quick Start

### Method 1: Using VulnLabWizard (Automated)

#### Step 1: Download Windows Server 2022 ISO
```
Download from: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
File: windows-server-2022.iso (~5GB)
Location: Save to D:\ISO\ or similar
```

#### Step 2: Run VulnLabWizard.exe
```powershell
# Right-click → Run as Administrator
.\VulnLabWizard.exe

# Or from command line
powershell -Command "Start-Process .\VulnLabWizard.exe -Verb RunAs"
```

#### Step 3: Follow Wizard Steps
```
1. Select Mode: "Instructor Mode"
2. Validate Environment: ✓ VirtualBox installed
3. Deployment Method: "Create from ISO"
4. Select ISO: Browse to windows-server-2022.iso
5. Configuration:
   ├─ Lab Prefix: VulnLab
   ├─ Lab Count: [5/10/15/20]
   ├─ RAM Per VM: [1-4 GB slider]
   ├─ Strategy: [Sequential/Simultaneous]
   ├─ Network IP Start: 192.168.56.100
   ├─ Port Start: 5100
   ├─ Domain: hackossem.local
   └─ Admin Password: P@ssw0rd!2024
6. Deploy: Sit back, wait ~90 minutes
7. Completion: Summary with network details
```

---

### Method 2: Manual VirtualBox VM Creation

#### Step 1: Create First VM
```powershell
$VmName = "VulnLab-ad-lab-1"
$MemoryMB = 2048
$CpuCount = 2
$DiskGB = 60

# Create VM
VBoxManage createvm `
  --name $VmName `
  --ostype "Windows2022_64" `
  --register `
  --basefolder "$env:USERPROFILE\VirtualBox VMs"

# Create disk
VBoxManage createhd `
  --filename "$env:USERPROFILE\VirtualBox VMs\$VmName\$VmName.vdi" `
  --size ($DiskGB * 1024) `
  --format VDI

# Attach disk
VBoxManage storagectl $VmName --name "SATA" --add sata --controller PIIX4
VBoxManage storageattach $VmName --storagectl "SATA" --port 0 --device 0 `
  --type hdd --medium "$env:USERPROFILE\VirtualBox VMs\$VmName\$VmName.vdi"

# Configure hardware
VBoxManage modifyvm $VmName --memory $MemoryMB --cpus $CpuCount

# Attach ISO for installation
$IsoPath = "D:\ISO\windows-server-2022.iso"
VBoxManage storagectl $VmName --name "IDE" --add ide --controller PIIX4
VBoxManage storageattach $VmName --storagectl "IDE" --port 1 --device 0 `
  --type dvddrive --medium $IsoPath

# Attach network (Host-Only)
VBoxManage modifyvm $VmName --nic1 hostonly --hostonlyadapter1 vboxnet0

# Set RDP port for remote connection
VBoxManage modifyvm $VmName --vrde on --vrdeport 5100
```

#### Step 2: Start VM and Install Windows
```powershell
# Start VM
VBoxManage startvm $VmName --type headless

# Or with GUI
VBoxManage startvm $VmName

# Wait for Windows installation to complete (~10 minutes)
# Follow Windows Server 2022 installation wizard
```

#### Step 3: Configure VM After Installation
```powershell
# Once Windows boots, connect via RDP
mstsc /v:127.0.0.1:5100

# Inside VM, run:
# 1. Set static IP
netsh interface ip set address name="Ethernet" static 192.168.56.100 255.255.255.0 192.168.56.1
netsh interface ip set dns name="Ethernet" static 8.8.8.8

# 2. Install Active Directory
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 3. Promote to Domain Controller
$Password = ConvertTo-SecureString "P@ssw0rd!2024" -AsPlainText -Force
Install-ADDSForest -DomainName "hackossem.local" `
  -SafeModeAdministratorPassword $Password `
  -NoRebootOnCompletion:$false -Force
```

---

### Method 3: Import Pre-Built OVA File

#### Step 1: Download OVA Export
```
OVA File: hackossem-labs.ova (12GB)
Location: https://github.com/netanelcyber/hackossem/releases
Download to: D:\OVA\
```

#### Step 2: Import OVA via VirtualBox GUI
```
VirtualBox Manager
  → File → Import Appliance
  → Select hackossem-labs.ova
  → Click "Next"
  → Review settings, click "Import"
  → Wait ~5 minutes for import
```

Or via command line:
```powershell
$OvaPath = "D:\OVA\hackossem-labs.ova"

# Import all labs from OVA
VBoxManage import $OvaPath `
  --basefolder "$env:USERPROFILE\VirtualBox VMs" `
  --options keepallmacs,keepnatmacs
```

#### Step 3: Configure Network for Imported VMs
```powershell
# After import, connect each VM to host-only network
for ($i = 1; $i -le 20; $i++) {
    $VmName = "VulnLab-ad-lab-$i"
    
    # Disconnect from any network
    VBoxManage modifyvm $VmName --nic1 none
    
    # Connect to host-only network
    VBoxManage modifyvm $VmName --nic1 hostonly --hostonlyadapter1 vboxnet0
    
    # Set RDP port
    $RdpPort = 5100 + $i - 1
    VBoxManage modifyvm $VmName --vrde on --vrdeport $RdpPort
}
```

---

## 🎮 Managing VMs

### List All VMs
```powershell
VBoxManage list vms

# Output:
# "VulnLab-ad-lab-1" {uuid-1}
# "VulnLab-ad-lab-2" {uuid-2}
# ... etc
```

### Start VM
```powershell
# Headless (no GUI)
VBoxManage startvm "VulnLab-ad-lab-1" --type headless

# With GUI
VBoxManage startvm "VulnLab-ad-lab-1"
```

### Check VM Status
```powershell
VBoxManage showvminfo "VulnLab-ad-lab-1" --machinereadable | grep State
# State="running" or State="poweroff"
```

### Stop VM
```powershell
# Graceful shutdown
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff
```

### Create Snapshot
```powershell
VBoxManage snapshot "VulnLab-ad-lab-1" take "clean-state" --description "Clean state before testing"
```

### Restore Snapshot
```powershell
VBoxManage snapshot "VulnLab-ad-lab-1" restore "clean-state"
```

### Clone VM
```powershell
$SourceVm = "VulnLab-ad-lab-1"
$TargetVm = "VulnLab-ad-lab-1-Team-A"

VBoxManage clonevm $SourceVm --name $TargetVm --register --mode machine
```

### Delete VM
```powershell
VBoxManage unregistervm "VulnLab-ad-lab-1" --delete
```

---

## 🌐 Network Configuration

### Host-Only Network Details
```
VirtualBox Host-Only Network: vboxnet0
├─ Host IP: 192.168.56.1
├─ Guest IP Range: 192.168.56.100-119
├─ Subnet Mask: 255.255.255.0
├─ DHCP: Disabled (static IPs)
└─ Isolation: Internal only (no external access)
```

### Lab VM Network Configuration
```
Lab 1:  IP=192.168.56.100, RDP=5100, WinRM=2100
Lab 2:  IP=192.168.56.101, RDP=5101, WinRM=2101
...
Lab 20: IP=192.168.56.119, RDP=5119, WinRM=2119
```

### Connect to Lab via RDP
```powershell
# Option 1: Launch mstsc from Windows
mstsc /v:127.0.0.1:5100

# Option 2: Use PowerShell
Start-Process "mstsc.exe" -ArgumentList "/v:127.0.0.1:5100"

# Option 3: Use VirtualBox directly
VBoxManage startvm "VulnLab-ad-lab-1"  # Opens GUI console
```

---

## ⚙️ Performance Tuning

### VirtualBox Global Settings
```powershell
# Set max parallelization
VBoxManage setproperty maxlogsize 104857600  # 100MB logs

# Set hardware acceleration (if available)
VBoxManage setproperty hid true  # USB HID support
```

### VM-Specific Tuning
```powershell
$VmName = "VulnLab-ad-lab-1"

# Enable 3D acceleration (optional)
VBoxManage modifyvm $VmName --accelerate3d on

# Increase video memory
VBoxManage modifyvm $VmName --vram 128

# Enable nested paging (faster)
VBoxManage modifyvm $VmName --nestedpaging on

# Enable PAE/NX
VBoxManage modifyvm $VmName --pae on --nx on
```

### Sequential Deployment Strategy (Lower RAM Usage)
```powershell
# Deploy labs sequentially to reduce peak RAM usage
$labCount = 20
for ($i = 1; $i -le $labCount; $i++) {
    $VmName = "VulnLab-ad-lab-$i"
    
    Write-Host "Starting $VmName..."
    VBoxManage startvm $VmName --type headless
    
    # Wait for boot
    Start-Sleep -Seconds 30
    
    # Deploy to this VM
    # ... deployment commands ...
    
    # Stop VM before starting next
    VBoxManage controlvm $VmName poweroff
    Start-Sleep -Seconds 5
}
```

---

## 🔍 Troubleshooting

### VirtualBox Not Found
```powershell
# Add VirtualBox to PATH
$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

# Verify
VBoxManage --version
```

### Host-Only Network Not Working
```powershell
# Recreate network
VBoxManage hostonlyif remove vboxnet0
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ipv4 192.168.56.1 --netmask 255.255.255.0
```

### RDP Connection Refused
```powershell
# Check VM status
VBoxManage showvminfo "VulnLab-ad-lab-1"

# Check RDP port mapping
VBoxManage modifyvm "VulnLab-ad-lab-1" --vrde on --vrdeport 5100

# Restart VM
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff
Start-Sleep -Seconds 5
VBoxManage startvm "VulnLab-ad-lab-1" --type headless
```

### Insufficient Disk Space
```powershell
# Check available space
Get-Volume C: | Select-Object SizeRemaining

# Options:
# 1. Clean up %TEMP%: Remove-Item $env:TEMP\* -Recurse -Force
# 2. Use different drive: VBoxManage setproperty machinefolder D:\VMs
# 3. Delete old VMs: VBoxManage unregistervm <name> --delete
```

### Out of Memory
```powershell
# Reduce per-VM memory
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 1024  # 1GB instead of 2GB

# Use sequential strategy instead of simultaneous
# Only start 2-3 VMs at a time
```

---

## 📊 Monitoring VMs

### Real-Time VM Status
```powershell
# Monitor all VMs
while ($true) {
    Clear-Host
    Write-Host "=== VirtualBox VMs Status ===" -ForegroundColor Cyan
    VBoxManage list runningvms
    Start-Sleep -Seconds 5
}
```

### Monitor Resource Usage
```powershell
# CPU and Memory per VM
Get-Process | Where-Object {$_.Name -like "*VBox*"} | Select-Object Name, CPU, WorkingSet
```

### Log File Location
```powershell
# VirtualBox logs
$LogPath = "$env:USERPROFILE\.VirtualBox\VBoxSVC.log"
Get-Content $LogPath | Select-Object -Last 50
```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] All 20 VMs created in VirtualBox Manager
- [ ] VMs have host-only network (vboxnet0) attached
- [ ] RDP ports 5100-5119 configured
- [ ] All VMs have static IPs (192.168.56.100-119)
- [ ] Active Directory installed on DC (Lab 1)
- [ ] Can RDP connect to any lab: `mstsc /v:127.0.0.1:5100`
- [ ] Can ping from host: `ping 192.168.56.100`
- [ ] Can ping gateway from VM: `ping 192.168.56.1`

---

## 🎯 Quick Commands Reference

```powershell
# Start all labs (sequential, 5 second delay)
Get-ChildItem "HKCU:\Software\Oracle\VirtualBox\MachineRegistry" | ForEach-Object {
    $vmName = ($_.GetValue("SettingsFile") -split "\\")[-2]
    if ($vmName -like "VulnLab-*") {
        Write-Host "Starting $vmName..."
        VBoxManage startvm $vmName --type headless
        Start-Sleep -Seconds 5
    }
}

# Stop all labs
VBoxManage list runningvms | ForEach-Object {
    $vmName = $_.Split('"')[1]
    VBoxManage controlvm $vmName poweroff
}

# Delete all labs (careful!)
VBoxManage list vms | Where-Object {$_ -like "*VulnLab*"} | ForEach-Object {
    $vmName = $_.Split('"')[1]
    VBoxManage unregistervm $vmName --delete
}
```

---

**For automated deployment, use VulnLabWizard.exe → Instructor Mode**

**Last Updated**: August 6, 2026
