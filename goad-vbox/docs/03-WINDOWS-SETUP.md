# Manual Windows Server Installation Guide

After creating VMs with VBoxManage, you must install Windows Server on each one. This guide covers the manual GUI process.

## Pre-Installation Checklist

- ✅ VM created and ISO attached
- ✅ Network configured (internal network)
- ✅ Disk allocated and attached
- ✅ Boot order set (CD first)

## Installation Steps (Per VM)

### 1. Start VM with GUI

```bash
VBoxManage startvm dc01 --type gui
```

A VirtualBox window opens showing the VM screen.

### 2. Follow Windows Installer

**Language & Locale**
- Language to install: **English**
- Time and currency format: Your preference
- Keyboard or input method: Your preference
- Click **Next**

**Windows Setup**
- Press any key to boot from CD (if prompted)
- Installer loads (takes ~30 seconds)

**Install Now**
- Click **Install Now**
- Do NOT click "Repair your computer"

**License Terms**
- Check "I accept the license terms"
- Click **Next**

**Which type of installation do you want?**
- Click **Custom: Install Windows only (advanced)**

**Where do you want to install Windows?**
- Select the disk (should be only one option)
- Click **Next**
- Installation begins (~15 minutes)

### 3. Post-Installation Configuration

After installer reboots and completes:

**Administrator Password**
- Set a strong password (you'll use this for Ansible)
- Example: `P@ssw0rd1`
- Confirm password
- **Write it down!**

**Server Configuration Screen**
- Wait for initial setup (takes ~2 minutes)
- Desktop loads

### 4. Configure Network (Critical!)

**Find Current IP:**
- Open PowerShell (Win+X → Windows PowerShell Admin)
- Run: `ipconfig /all`
- Note the network adapter name (usually "Ethernet")

**Set Static IP:**
```powershell
# Get adapter name
Get-NetAdapter

# Set static IP (replace "Ethernet" with actual name)
$adapter = "Ethernet"
$ip = "192.168.1.11"         # Change per VM
$mask = "255.255.255.0"
$gateway = "192.168.1.1"

New-NetIPAddress -InterfaceAlias $adapter -IPAddress $ip -PrefixLength 24 -DefaultGateway $gateway
```

**Verify:**
```powershell
ipconfig /all
# Should show: 192.168.1.11 (or your assigned IP)
```

### 5. Set Hostname

```powershell
# Rename computer (requires restart)
Rename-Computer -NewName "dc01" -Restart
```

**Repeat after restart:**
- VM reboots
- Log back in as Administrator
- Verify hostname: `hostname`

### 6. Disable Unnecessary Services (Optional)

```powershell
# Disable Windows Defender (speeds up provisioning)
Set-MpPreference -DisableRealtimeMonitoring $true

# Disable Windows Update (optional)
Stop-Service wuauserv
Set-Service wuauserv -StartupType Disabled
```

### 7. Shutdown VM

```powershell
Stop-Computer -Force
```

Or from host:
```bash
VBoxManage controlvm dc01 acpipowerbutton
```

## Network Configuration Summary

| VM | Hostname | IP | Gateway | Netmask |
|----|----------|----|---------|----|
| dc01 | dc01 | 192.168.1.11 | 192.168.1.1 | 255.255.255.0 |
| dc02 | dc02 | 192.168.1.12 | 192.168.1.1 | 255.255.255.0 |
| srv02 | srv02 | 192.168.1.22 | 192.168.1.1 | 255.255.255.0 |
| srv03 | srv03 | 192.168.1.23 | 192.168.1.1 | 255.255.255.0 |
| ws01 | ws01 | 192.168.1.30 | 192.168.1.1 | 255.255.255.0 |

## PowerShell Configuration Script

To speed up Windows setup, copy this entire script into PowerShell (as Administrator) on each VM:

```powershell
# Configure VM for GOAD provisioning

# Accept Admin password as parameter
$AdminPassword = Read-Host "Enter Administrator password"

# Set hostname (replace with actual hostname)
$Hostname = Read-Host "Enter hostname (dc01, dc02, etc.)"
Rename-Computer -NewName $Hostname -Restart -Force
```

**After restart:**

```powershell
# Network config
$IP = "192.168.1.11"        # Change per VM
$adapter = (Get-NetAdapter).InterfaceAlias[0]

New-NetIPAddress -InterfaceAlias $adapter `
  -IPAddress $IP `
  -PrefixLength 24 `
  -DefaultGateway "192.168.1.1" `
  -ErrorAction SilentlyContinue

# Disable Defender
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# Disable Windows Update
Stop-Service wuauserv -ErrorAction SilentlyContinue
Set-Service wuauserv -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "Windows configuration complete. Ready for WinRM setup."
```

## What NOT to Do

❌ **Don't join domain yet** — Ansible playbooks do this  
❌ **Don't configure DNS** — Set after DC is created  
❌ **Don't install extra software** — GOAD playbooks handle this  
❌ **Don't use DHCP** — Use static IPs for predictability  

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Network adapter not visible | Might be disabled; check Device Manager (Win+X → Device Manager) |
| Cannot connect to network | Verify VirtualBox network exists; check adapter binding |
| Installer hangs | Increase VM RAM temporarily; check ISO integrity |
| Cannot set IP (access denied) | Run PowerShell as Administrator |

---

**Next:** [`docs/04-WINRM-SETUP.md`](04-WINRM-SETUP.md) to enable remote management.
