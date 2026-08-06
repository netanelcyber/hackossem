# Windows Server 2022 Vulnerability Lab Setup Guide

Complete guide for deploying and managing 20 Windows Server 2022 penetration testing training labs with Active Directory and intentional security vulnerabilities.

## Overview

This lab platform provides **20 distinct penetration testing scenarios** organized by difficulty:
- **Easy Tier (6 labs)**: Straightforward vulnerabilities for beginners
- **Medium Tier (7 labs)**: Chained attacks requiring multiple exploitation steps  
- **Hard Tier (7 labs)**: Advanced multi-stage exploitation and persistence

**Total Resource Requirements:**
- Disk Space: ~1.2 TB (60GB per VM × 20)
- RAM: 80GB (4GB per VM × 20)
- vCPUs: 40 (2 per VM × 20)
- Network: Internal + NAT access

## Prerequisites

### Required Software
- **VirtualBox 7.0+** - Hypervisor
- **Windows Server 2022 ISO** - Installation media
- **PowerShell 5.1+** - Automation scripts
- **Administrator Access** - Required for most operations

### System Requirements
Minimum for partial deployment (5 labs):
- 32GB RAM
- 300GB disk space
- 4-core processor

Recommended for full deployment (all 20 labs):
- 96GB+ RAM
- 1.2TB+ disk space
- 8+ core processor

### Network Setup
The labs use:
- **Network**: `192.168.56.0/24` (host-only for interconnection)
- **IPs**: `192.168.56.100-119` (for 20 VMs)
- **Domain**: `hackossem.local`
- **NAT Network**: For internet access during setup

## Installation Steps

### Step 1: Prepare Environment

```powershell
# Run as Administrator
# Verify VirtualBox installation
VBoxManage --version

# Create storage directory
mkdir "C:\VirtualBox VMs\hackossem-ad"

# Download Windows Server 2022 ISO
# Place at: C:\ISO\Windows2022.iso
```

### Step 2: Create VMs

```powershell
cd .\windows-vulnlabs\automation\

# Create all 20 VMs (requires ~15-30 minutes)
.\create-windows-vulnlabs.ps1 -Win2022ISO "C:\ISO\Windows2022.iso"

# Or create specific range (e.g., labs 1-5)
.\create-windows-vulnlabs.ps1 -Win2022ISO "C:\ISO\Windows2022.iso" -StartLab 1 -EndLab 5

# Dry run to see what will be created
.\create-windows-vulnlabs.ps1 -DryRun
```

**What this does:**
- Creates VBox VMs with Windows Server 2022 configuration
- Allocates 4GB RAM, 2 CPUs, 60GB disk per VM
- Configures port forwarding for RDP and WinRM
- Sets up internal network for VM-to-VM communication

### Step 3: Install Windows Server 2022

**For each VM:**

1. **Start VM from ISO**
   ```powershell
   VBoxManage startvm "AD-WS-Easy-1" --type gui
   ```

2. **Follow Windows installation wizard**
   - Select "Windows Server 2022 Standard/Datacenter"
   - Install to virtual disk
   - Complete initial setup

3. **Login and enable Remote PowerShell**
   ```powershell
   Enable-PSRemoting -Force
   ```

**Bulk boot all VMs** (after creation):
```powershell
Get-VM | ForEach-Object { VBoxManage startvm $_.Name --type headless }
```

### Step 4: Setup Active Directory Domain

After all VMs have Windows installed:

```powershell
# Run on one VM (preferably Easy-1 as DC)
.\setup-ad-domain.ps1

# This creates:
# - AD forest: hackossem.local
# - OUs: Easy, Medium, Hard
# - User accounts with intentional vulnerabilities
# - Service accounts with misconfigurations
# - Weak password policy (Easy tier)
```

### Step 5: Inject Vulnerabilities

```powershell
# Inject vulnerabilities into all labs
.\inject-vulnerabilities.ps1

# Or specific lab
.\inject-vulnerabilities.ps1 -LabID 3

# Injections by tier:
# Easy: Weak passwords, default accounts, unpatched systems
# Medium: Web app flaws, AD delegation issues, Kerberos weaknesses
# Hard: Multi-stage PrivEsc, NTLM relay, ACL abuse
```

### Step 6: Deploy IIS Applications

```powershell
# Setup IIS and vulnerable web apps
.\setup-iis-apps.ps1

# Creates:
# - SQLi vulnerable login form
# - Directory traversal vulnerable file viewer
# - Unsafe file upload functionality
# - LDAP injection in search
# - WebDAV with RCE surface
```

### Step 7: Validate All Labs

```powershell
# Comprehensive validation
.\validate-vulnerabilities.ps1

# Validate specific lab
.\validate-vulnerabilities.ps1 -LabID 5

# Output: Network connectivity, vulnerability presence, exploitation readiness
```

## Lab Organization

### Easy Tier (Labs 1-6)
Designed for penetration testing beginners - single-step exploitations.

| Lab | Vulnerability | Exploitation |
|-----|---|---|
| 1 | Weak password policy | Credential brute force, password spray |
| 2 | Default service accounts | Capture credentials, spawn shell |
| 3 | Unpatched system (CVE) | Public exploit, SYSTEM access |
| 4 | IIS basic auth over HTTP | Traffic capture, decode credentials |
| 5 | Overshared SMB folders | Enumerate shares, extract files |
| 6 | UAC bypass + credential storage | Extract from registry, UAC bypass |

### Medium Tier (Labs 7-13)
Requires chaining multiple exploitation techniques.

| Lab | Vulnerability | Exploitation |
|-----|---|---|
| 7 | ASP.NET SQL injection | SQLi to extract users, second-order RCE |
| 8 | AD constrained delegation | Capture ticket, S4U2Self + S4U2Proxy |
| 9 | Kerberoasting | Request SPN tickets, crack offline |
| 10 | Directory traversal + upload | Path traversal read + shell upload |
| 11 | GPO misconfiguration | Modify scheduled task for PrivEsc |
| 12 | LDAP injection | Query manipulation, credential extraction |
| 13 | Token impersonation | Steal elevated token, execute code |

### Hard Tier (Labs 14-20)
Advanced exploitation chains and persistence mechanisms.

| Lab | Vulnerability | Exploitation |
|-----|---|---|
| 14 | Multi-stage PrivEsc | Kernel exploit + service abuse |
| 15 | NTLM relay | HTTP→LDAP/SMB relay, modify AD |
| 16 | AD ACL misconfig | BloodHound analysis, WriteProperty exploit |
| 17 | WebDAV + RCE | PUT upload malicious ASPX, code execution |
| 18 | DLL injection | Plant DLL in LoadPath, trigger execution |
| 19 | Service account S4U | Forge impersonation tickets, domain admin |
| 20 | Multi-stage + persistence | Staged payload, WMI/scheduled task persistence |

## Access Information

### Remote Access Methods

**PowerShell Remoting (WinRM)**
```powershell
# Connect to specific lab
Enter-PSSession -ComputerName "AD-WS-Easy-1" -Credential $cred

# Execute commands remotely
Invoke-Command -ComputerName "AD-WS-Easy-1" -ScriptBlock { whoami }
```

**RDP Access**
```powershell
# Via port forwarding
mstsc /v:localhost:5100  # For lab 1 (port 5100-5119 for labs 1-20)
```

**SSH-like via RDP**
```powershell
# Connect using SSH client with RDP tunneling
ssh -L 3389:AD-WS-Easy-1:3389 user@jumphost
```

### Default Credentials

**Domain Admin** (for initial access):
```
Domain: hackossem.local
Admin: Administrator
Password: (set during installation)
```

**Lab-specific accounts** (see WINDOWS_VULNLAB_CREDENTIALS.md):
```
easy_admin / Admin123
svc_high_priv / Admin123
kerberoast_target / VulnPass2022
(etc.)
```

**NOTE:** Credentials file is git-ignored for security. Keep separate from repo.

## Usage Workflows

### Penetration Testing Training

1. **Choose difficulty level** (Easy, Medium, or Hard)
2. **Connect to VM** via RDP or WinRM
3. **Follow exploitation guide** (see WINDOWS_VULNLAB_PENETESTING_GUIDE.md)
4. **Capture proof** of exploitation
5. **Snapshot VM** before moving to next

### Team Exercises

```powershell
# Clone specific lab for team member
VBoxManage clonevm "AD-WS-Easy-1" --name "AD-WS-Easy-1-Team-B" --register

# Customize for team use
.\inject-vulnerabilities.ps1 -LabID 1  # Re-inject if needed
```

### Classroom Deployment

```powershell
# Deploy subset of labs
.\create-windows-vulnlabs.ps1 -StartLab 1 -EndLab 6

# All Easy tier for introduction
# Follow with Medium tier for intermediate
# Advanced labs for capstone project
```

## Management Commands

### VM Lifecycle

```powershell
# Start VM
VBoxManage startvm "AD-WS-Easy-1" --type headless

# Stop VM gracefully
VBoxManage controlvm "AD-WS-Easy-1" acpipowerbutton

# Pause/Resume
VBoxManage controlvm "AD-WS-Easy-1" pause
VBoxManage controlvm "AD-WS-Easy-1" resume

# Snapshot before testing
VBoxManage snapshot "AD-WS-Easy-1" take "pre-exploit"

# Restore after testing
VBoxManage snapshot "AD-WS-Easy-1" restore "pre-exploit"

# Delete VM
VBoxManage unregistervm "AD-WS-Easy-1" --delete
```

### Network Management

```powershell
# List all VMs on network
VBoxManage list vms | Select-String "AD-WS"

# Check VM network config
VBoxManage showvminfo "AD-WS-Easy-1" | Select-String "Name|IP|Port"

# Change port forwarding
VBoxManage modifyvm "AD-WS-Easy-1" --natpf1 "SSH,tcp,,2100,,22"
```

### Cleanup

```powershell
# Destroy all Windows vulnerability labs
.\cleanup-windows-vulnlabs.ps1

# Or remove individually
VBoxManage unregistervm "AD-WS-Easy-1" --delete
VBoxManage unregistervm "AD-WS-Easy-2" --delete
# (repeat for all 20)
```

## Troubleshooting

### VMs Won't Boot from ISO

**Solution:**
```powershell
# Check boot order
VBoxManage showvminfo "AD-WS-Easy-1" | Select-String "Boot"

# Set DVD as first boot device
VBoxManage modifyvm "AD-WS-Easy-1" --boot1 dvd --boot2 disk
```

### WinRM Not Accessible

**Solution:**
```powershell
# Enable remoting on VM
# (via console or RDP)
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
```

### Vulnerability Not Present

**Solution:**
```powershell
# Re-inject for specific lab
.\inject-vulnerabilities.ps1 -LabID 3

# Check log for errors
# (Logs stored in script output)
```

### Port Conflicts

**Solution:**
```powershell
# Find what's using port 5100
netstat -ano | Select-String "5100"

# Change port forwarding
VBoxManage modifyvm "AD-WS-Easy-1" --natpf1 delete "RDP"
VBoxManage modifyvm "AD-WS-Easy-1" --natpf1 "RDP,tcp,,5200,,3389"
```

## Security Notes

⚠️ **IMPORTANT:** These labs contain intentional security vulnerabilities. 

- **Only run in isolated environments** (not production)
- **Never connect to internet-facing networks** without additional firewalls
- **Use host-only networking** for isolated testing
- **Snapshot before testing** to prevent unwanted changes
- **Do not reuse credentials** in production systems
- **Change default passwords** after deployment

## Next Steps

1. **Read exploitation guides**: `WINDOWS_VULNLAB_PENETESTING_GUIDE.md`
2. **Start with Easy tier**: Build foundational skills
3. **Progress to Medium**: Practice attack chaining
4. **Tackle Hard tier**: Advanced red team techniques
5. **Create snapshots**: Before and after each exploitation
6. **Document findings**: Build your security research portfolio

## Support & Resources

- **Exploitation Guides**: See `windows-vulnlab-*.md` files by difficulty
- **Active Directory Security**: `../../../docs/AD_SECURITY.md`
- **Pentesting Toolkit**: Metasploit, Mimikatz, Impacket, SharpHound
- **Learning Resources**: HackTheBox, PentesterLab, TryHackMe

## Files Reference

```
windows-vulnlabs/
├── automation/
│   ├── create-windows-vulnlabs.ps1      # VM creation orchestration
│   ├── setup-ad-domain.ps1              # AD forest + domain setup
│   ├── inject-vulnerabilities.ps1       # Vulnerability injection
│   ├── setup-iis-apps.ps1               # IIS + web app deployment
│   ├── validate-vulnerabilities.ps1     # Verification script
│   ├── cleanup-windows-vulnlabs.ps1     # Safe cleanup
│   └── windows-vulnlab-config.json      # Machine definitions
├── iis-apps/
│   ├── vulnerable-webform-sqli.aspx     # SQL injection lab
│   ├── vulnerable-directory-traversal.aspx
│   ├── vulnerable-file-upload.aspx
│   ├── vulnerable-ldap-search.aspx
│   └── webdav-upload-shell.aspx
└── docs/
    ├── WINDOWS_VULNLAB_SETUP.md         # This file
    ├── WINDOWS_VULNLAB_PENETESTING_GUIDE.md
    ├── windows-vulnlab-easy.md
    ├── windows-vulnlab-medium.md
    ├── windows-vulnlab-hard.md
    ├── WINDOWS_VULNLAB_CREDENTIALS.md   # (git-ignored)
    └── INDEX.md
```

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready  
**Last Updated**: 2026-08-06
