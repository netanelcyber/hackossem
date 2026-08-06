# 🪟 VirtualBox OVA Import Guide for Windows Server 2022

## Overview

Complete guide for importing and managing VulnLab AD lab OVA files on Windows Server 2022 using VirtualBox.

---

## Prerequisites

### System Requirements
- **Windows Server 2022** (Standard or Datacenter edition)
- **VirtualBox 7.0+** - Download: https://www.virtualbox.org/wiki/Downloads
- **50GB+ free disk space** (for 5 OVA files ~45GB)
- **16GB+ RAM** (2GB per VM × 5 minimum)
- **4+ CPU cores** (2 per VM × 5 minimum)
- **Network connectivity** (for downloading OVA files)

### PowerShell Requirements
- **PowerShell 5.0+** (built-in on Windows Server 2022)
- **Administrator privileges** (for script execution)

---

## Step 1: Install VirtualBox on Windows Server 2022

### Option A: Using Installer (GUI)

1. **Download VirtualBox**
   - Visit: https://www.virtualbox.org/wiki/Downloads
   - Download: "VirtualBox for Windows"

2. **Run Installer**
   - Right-click installer → "Run as administrator"
   - Follow wizard
   - Accept default installation path

3. **Verify Installation**
   ```powershell
   VBoxManage --version
   # Output: X.X.Xrx (e.g., 7.0.12r159484)
   ```

### Option B: Using Windows Package Manager

```powershell
# Open PowerShell as Administrator
winget install Oracle.VirtualBox

# Verify
VBoxManage --version
```

### Option C: Using Chocolatey

```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install VirtualBox
choco install virtualbox -y

# Verify
VBoxManage --version
```

---

## Step 2: Download OVA Files

### Option A: From Git LFS (Recommended)

```powershell
# Clone repository
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem

# Install Git LFS (if not already)
# Download from: https://git-lfs.github.com/

# Pull OVA files (~45 GB - takes 20-30 minutes)
git lfs pull

# Verify downloads
ls lab-vms/lab-*.ova

# Verify checksums
cd lab-vms
certutil -hashfile lab-ad-lab-1.ova SHA256
# Compare with: lab-ad-lab-1.ova.sha256 content
```

### Option B: Download Individual Files

```powershell
# Create download directory
mkdir C:\VMs\OVA-Imports
cd C:\VMs\OVA-Imports

# Download OVA files (example using wget or PowerShell)
# Replace URLs with actual GitHub/cloud storage URLs

# Lab 1
Invoke-WebRequest -Uri "https://your-storage/lab-ad-lab-1.ova" -OutFile "lab-ad-lab-1.ova"

# Lab 2
Invoke-WebRequest -Uri "https://your-storage/lab-ad-lab-2.ova" -OutFile "lab-ad-lab-2.ova"

# ... repeat for labs 3-5
```

---

## Step 3: Import OVA Files into VirtualBox

### Using PowerShell Script (Recommended)

Create file: `Import-OVA-Labs.ps1`

```powershell
# Run as Administrator
# cd C:\VMs\OVA-Imports
# .\Import-OVA-Labs.ps1

param(
    [string]$OVADirectory = "C:\VMs\OVA-Imports",
    [string]$VMStoragePath = "C:\VirtualBox VMs"
)

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🪟 VirtualBox OVA Import for Windows Server 2022" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check administrator privileges
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script must run as Administrator" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Check VirtualBox installation
Write-Host "Checking VirtualBox installation..."
try {
    $version = VBoxManage --version
    Write-Host "✅ VirtualBox found: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ VirtualBox not found. Install it first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Define labs
$labs = @(
    @{ID = "ad-lab-1"; Name = "Active Directory Basics"},
    @{ID = "ad-lab-2"; Name = "LDAP Enumeration & Exploitation"},
    @{ID = "ad-lab-3"; Name = "Kerberos & ASREProast"},
    @{ID = "ad-lab-4"; Name = "Privilege Escalation in AD"},
    @{ID = "ad-lab-5"; Name = "Golden Ticket & Domain Takeover"}
)

Write-Host "📋 Labs to Import:" -ForegroundColor Cyan
Write-Host ""
foreach ($lab in $labs) {
    Write-Host "  ✓ $($lab.ID): $($lab.Name)"
}
Write-Host ""

# Check OVA files exist
Write-Host "Checking OVA files..." -ForegroundColor Cyan
Write-Host ""

foreach ($lab in $labs) {
    $ovaFile = Join-Path $OVADirectory "lab-$($lab.ID).ova"
    if (Test-Path $ovaFile) {
        $size = (Get-Item $ovaFile).Length / 1GB
        Write-Host "✅ Found: lab-$($lab.ID).ova ($size.2 GB)" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing: $ovaFile" -ForegroundColor Red
    }
}

Write-Host ""
$confirmation = Read-Host "Continue with import? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Cancelled"
    exit 0
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📦 Importing OVA Files..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$counter = 1
foreach ($lab in $labs) {
    $ovaFile = Join-Path $OVADirectory "lab-$($lab.ID).ova"
    $vmName = "VulnLab-$($lab.ID)"

    if (-not (Test-Path $ovaFile)) {
        Write-Host "[$counter/5] ⚠️  Skipping (file not found): $ovaFile" -ForegroundColor Yellow
        $counter++
        continue
    }

    Write-Host "[$counter/5] 📤 Importing: $($lab.Name)" -ForegroundColor Cyan
    Write-Host "    File: lab-$($lab.ID).ova" -ForegroundColor Gray
    Write-Host "    VM Name: $vmName" -ForegroundColor Gray
    Write-Host ""

    # Import OVA
    try {
        Write-Host "    Starting import..." -ForegroundColor Gray
        VBoxManage import $ovaFile `
            --vsys 0 `
            --vmname $vmName `
            --basefolder $VMStoragePath `
            --group "/VulnLab"

        Write-Host "    ✅ Import successful!" -ForegroundColor Green
    } catch {
        Write-Host "    ❌ Import failed: $_" -ForegroundColor Red
    }

    Write-Host ""
    $counter++
}

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Import Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# List imported VMs
Write-Host "Imported VMs:" -ForegroundColor Cyan
Write-Host ""
VBoxManage list vms | Select-String "VulnLab"

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Modify VM settings (if needed):"
Write-Host "    VBoxManage modifyvm 'VulnLab-ad-lab-1' --memory 4096 --cpus 4"
Write-Host ""
Write-Host "2️⃣  Start VMs:"
Write-Host "    VBoxManage startvm 'VulnLab-ad-lab-1' --type headless"
Write-Host ""
Write-Host "3️⃣  Use GUI (VirtualBox Manager):"
Write-Host "    VirtualBox"
Write-Host ""
```

### Using Command Line (Manual Import)

```powershell
# Run as Administrator

# Lab 1
VBoxManage import "C:\VMs\OVA-Imports\lab-ad-lab-1.ova" `
    --vsys 0 `
    --vmname "VulnLab-ad-lab-1" `
    --basefolder "C:\VirtualBox VMs" `
    --group "/VulnLab"

# Lab 2
VBoxManage import "C:\VMs\OVA-Imports\lab-ad-lab-2.ova" `
    --vsys 0 `
    --vmname "VulnLab-ad-lab-2" `
    --basefolder "C:\VirtualBox VMs" `
    --group "/VulnLab"

# ... repeat for labs 3-5

# Verify imports
VBoxManage list vms
```

---

## Step 4: Start and Manage VMs

### PowerShell Management Script

Create file: `Manage-VMs.ps1`

```powershell
# VM Management Script for Windows

param(
    [string]$Action = "menu",
    [string]$VMName = "VulnLab-ad-lab-1"
)

function Show-Menu {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🖥️  VirtualBox VM Management (Windows Server 2022)" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Start Lab 1 (AD Basics)"
    Write-Host "2. Start Lab 2 (LDAP Enumeration)"
    Write-Host "3. Start Lab 3 (Kerberos)"
    Write-Host "4. Start Lab 4 (Privilege Escalation)"
    Write-Host "5. Start Lab 5 (Golden Ticket)"
    Write-Host ""
    Write-Host "A. Start ALL Labs"
    Write-Host "H. Halt ALL Labs"
    Write-Host "L. List All VMs"
    Write-Host "I. VM Info"
    Write-Host "G. Open VirtualBox GUI"
    Write-Host ""
    Write-Host "0. Exit"
    Write-Host ""
}

function Start-VM {
    param([string]$Name)
    Write-Host "Starting $Name..." -ForegroundColor Green
    VBoxManage startvm $Name --type headless
    Start-Sleep -Seconds 3
    Write-Host "✅ $Name started" -ForegroundColor Green
}

function Stop-VM {
    param([string]$Name)
    Write-Host "Stopping $Name..." -ForegroundColor Yellow
    VBoxManage controlvm $Name poweroff
    Write-Host "✅ $Name stopped" -ForegroundColor Green
}

function List-VMs {
    Write-Host ""
    Write-Host "Registered VMs:" -ForegroundColor Cyan
    VBoxManage list vms | Select-String "VulnLab"
    Write-Host ""
}

function VM-Info {
    param([string]$Name)
    Write-Host ""
    Write-Host "VM Info: $Name" -ForegroundColor Cyan
    VBoxManage showvminfo $Name --compact
    Write-Host ""
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option"

    switch ($choice) {
        "1" { Start-VM "VulnLab-ad-lab-1" }
        "2" { Start-VM "VulnLab-ad-lab-2" }
        "3" { Start-VM "VulnLab-ad-lab-3" }
        "4" { Start-VM "VulnLab-ad-lab-4" }
        "5" { Start-VM "VulnLab-ad-lab-5" }
        "A" {
            Write-Host "Starting all labs..." -ForegroundColor Green
            1..5 | ForEach-Object {
                Start-VM "VulnLab-ad-lab-$_"
                Start-Sleep -Seconds 2
            }
        }
        "H" {
            Write-Host "Halting all labs..." -ForegroundColor Yellow
            1..5 | ForEach-Object {
                Stop-VM "VulnLab-ad-lab-$_"
            }
        }
        "L" { List-VMs }
        "I" {
            $vm = Read-Host "Enter VM name (e.g., VulnLab-ad-lab-1)"
            VM-Info $vm
        }
        "G" {
            Write-Host "Opening VirtualBox GUI..." -ForegroundColor Cyan
            Start-Process "VirtualBox"
        }
        "0" { 
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit 0 
        }
        default { Write-Host "Invalid option" -ForegroundColor Red }
    }

    Read-Host "Press Enter to continue"
} while ($true)
```

### Basic Commands

```powershell
# Start VM (headless)
VBoxManage startvm "VulnLab-ad-lab-1" --type headless

# Start VM with GUI
VBoxManage startvm "VulnLab-ad-lab-1"

# Stop VM
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff

# Pause VM
VBoxManage controlvm "VulnLab-ad-lab-1" pause

# List running VMs
VBoxManage list runningvms

# Get VM details
VBoxManage showvminfo "VulnLab-ad-lab-1" --compact

# Modify VM settings (must be powered off)
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096 --cpus 4
```

---

## Step 5: Network Configuration (Optional)

### Configure Port Forwarding

```powershell
# Add SSH port forwarding (Lab 1)
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 "SSH,tcp,,2049,,22"

# Add HTTP port forwarding (Lab 1)
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 "HTTP,tcp,,5001,,5000"

# Remove port forwarding
VBoxManage modifyvm "VulnLab-ad-lab-1" --natpf1 delete "SSH"

# View current rules
VBoxManage showvminfo "VulnLab-ad-lab-1" | Select-String "NIC"
```

### Access Labs

```powershell
# SSH access (requires PuTTY or Windows 10+ OpenSSH)
# From PowerShell:
ssh -p 2049 ubuntu@localhost

# Web access
Start-Process "http://localhost:5001"
```

---

## Step 6: Backup and Export

### Create Snapshots

```powershell
# Create snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" take "initial-state" `
    --description "Clean snapshot before testing"

# List snapshots
VBoxManage snapshot "VulnLab-ad-lab-1" list

# Restore snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" restore "initial-state"

# Delete snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" delete "initial-state"
```

### Export Modified VM

```powershell
# Export VM back to OVA (for backup/sharing)
VBoxManage export "VulnLab-ad-lab-1" `
    -o "C:\VMs\Backups\lab-ad-lab-1-modified.ova" `
    --vsys 0 `
    --product "VulnLab AD Lab 1" `
    --vendor "VulnLab"
```

---

## Troubleshooting on Windows Server 2022

### VM Won't Start

```powershell
# Check if VM exists
VBoxManage list vms

# Detailed error output
VBoxManage startvm "VulnLab-ad-lab-1" 2>&1

# Verify installation
VBoxManage --version

# Restart VirtualBox service
Stop-Service VirtualBox
Start-Service VirtualBox

# Full system restart
Restart-Computer
```

### Not Enough Resources

```powershell
# Check available RAM
Get-ComputerInfo -Property "TotalPhysicalMemory"

# Check disk space
Get-PSDrive C | Select-Object Used,Free

# Reduce VM memory
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 1024
```

### Network Issues

```powershell
# Check network adapter
ipconfig

# Verify port forwarding
VBoxManage showvminfo "VulnLab-ad-lab-1" | Select-String "natpf"

# Check port availability
netstat -ano | Select-String "2049"

# Reset network adapter
VBoxManage modifyvm "VulnLab-ad-lab-1" --nic1 nat
```

---

## Performance Optimization

```powershell
# Increase VM resources
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096 --cpus 4 --vram 32

# Enable 3D acceleration
VBoxManage modifyvm "VulnLab-ad-lab-1" --accelerate3d on

# Use faster storage
VBoxManage modifyvm "VulnLab-ad-lab-1" --storagectl "SATA Controller"

# Enable nested paging
VBoxManage modifyvm "VulnLab-ad-lab-1" --nested-hw-virt on
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Import OVA | `VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname "VulnLab-ad-lab-1"` |
| Start VM | `VBoxManage startvm "VulnLab-ad-lab-1" --type headless` |
| Stop VM | `VBoxManage controlvm "VulnLab-ad-lab-1" poweroff` |
| List VMs | `VBoxManage list vms` |
| Modify VM | `VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096` |
| SSH | `ssh -p 2049 ubuntu@localhost` |
| Open GUI | `VirtualBox` |

---

## Support & Resources

- **VirtualBox Docs**: https://www.virtualbox.org/manual/
- **VBoxManage CLI**: https://www.virtualbox.org/manual/ch08.html
- **Windows Server**: https://learn.microsoft.com/en-us/windows-server/

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready for Windows Server 2022
