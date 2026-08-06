# HackOSSEM Windows Vulnerability Lab Automation - VulnLabWizard.exe

**Complete all-in-one wizard for deploying, managing, and accessing 20 Windows Server 2022 vulnerability labs.**

## Overview

VulnLabWizard is a single executable application that automates all operations for the Windows vulnerability lab platform:

- **Instructor Mode**: Deploy complete environment from scratch (create 20 VMs, setup AD, inject vulnerabilities, deploy IIS)
- **Student Mode**: Access and manage labs (start, stop, connect, reset, view guides)
- **Admin Mode**: Advanced operations (clone labs, create snapshots, team setup, maintenance)
- **Automated Mode**: Silent deployment for CI/CD and bulk provisioning

## Features

✅ **Single .EXE File** (~15-20MB with all embedded scripts)  
✅ **No External Dependencies** (except VirtualBox)  
✅ **Multi-Mode Interface** (wizard-based, step-by-step)  
✅ **20 Windows Server 2022 Labs** (6 Easy, 7 Medium, 7 Hard)  
✅ **Complete Automation** (VM creation, AD setup, vulnerability injection, IIS deployment)  
✅ **Real-Time Logging** (monitor deployment progress)  
✅ **Team Support** (clone labs, assign credentials, network isolation)  
✅ **Cross-Platform** (Windows 10+ and Windows Server 2019+)  

## System Requirements

- **OS**: Windows 10 (build 1809+), Windows 11, or Windows Server 2019+
- **.NET Framework**: 4.8+ (usually pre-installed)
- **VirtualBox**: 7.0+ (must be installed separately)
- **Disk Space**: 150GB+ free (20 VMs × 8GB disks)
- **RAM**: 40GB+ free (20 VMs × 2GB each)
- **Privileges**: Administrator (required to run)

## Installation

### Download

Download the latest release:
```
https://github.com/netanelcyber/hackossem/releases/download/v1.0.0-windows-labs/VulnLabWizard.exe
```

### Setup

1. **Install VirtualBox**:
   ```powershell
   choco install virtualbox -y
   ```

2. **Run VulnLabWizard.exe**:
   - Right-click → "Run as Administrator"
   - Or use command line: `VulnLabWizard.exe`

3. **Follow the wizard steps**:
   - Select mode (Instructor/Student/Admin/Auto)
   - Choose deployment method (create from ISO or import OVA)
   - Configure settings (lab name, network, passwords)
   - Wait for deployment (takes 60-90 minutes for full setup)

## Usage Modes

### 1. Instructor Mode
For initial setup and complete deployment:

```
1. Launch VulnLabWizard.exe
2. Select "Instructor Mode"
3. Validate environment (VirtualBox, disk, RAM)
4. Choose deployment method:
   - Option A: Create from Windows Server 2022 ISO
   - Option B: Import pre-built 12GB OVA file
5. Configure settings:
   - Lab prefix (default: VulnLab)
   - Network IP start (default: 192.168.56.100)
   - Port range start (default: 5100)
   - Domain name (default: hackossem.local)
   - Admin password
6. Start deployment
7. Monitor progress (6 phases over ~90 minutes)
8. Review completion summary
```

**Result**: 20 fully configured Windows vulnerability labs ready for use.

### 2. Student Mode
For accessing and learning from existing labs:

```
1. Launch VulnLabWizard.exe
2. Select "Student Mode"
3. View lab dashboard:
   - All 20 labs listed by difficulty
   - Status: Running/Stopped/Error
4. Select a lab and:
   - Start VM (boot and configure)
   - Stop VM (graceful shutdown)
   - Reset to Snapshot (restore clean state)
   - RDP Connect (auto-launch Remote Desktop)
   - View Credentials (username/password)
   - View Exploitation Guide (step-by-step walkthrough)
5. Connect to lab and begin exploitation
```

### 3. Admin Mode
For advanced management operations:

**VM Management Tab**:
- Clone Lab (copy VM for team exercises)
- Create Snapshot (save clean state)
- Restore Snapshot (revert to saved state)
- Delete VM (remove lab)
- Modify Properties (change RAM, CPU, VRAM)

**Team Setup Tab**:
- Create Team Set (clone all 20 labs with unique ports/IPs)
- Assign Credentials (team-specific usernames/passwords)

**Maintenance Tab**:
- Backup Configuration (export settings)
- Update Vulnerabilities (re-run injection)
- Database Cleanup (remove logs/cache)

### 4. Automated Mode
For CI/CD and non-interactive deployment:

```powershell
# Create configuration file
$config = @{
    deployment_method = "from-scratch"
    windows_iso = "D:\ISO\Windows Server 2022.iso"
    lab_prefix = "VulnLab"
    domain_name = "hackossem.local"
    domain_password = "P@ssw0rd!2024"
    create_snapshots = $true
    validate_after = $true
    log_file = "deployment.log"
} | ConvertTo-Json | Out-File deployment.json

# Run in automated mode
VulnLabWizard.exe --mode instructor --automate --config deployment.json
```

## Lab Organization

### 20 Labs Across 3 Difficulty Tiers

#### Easy (6 labs) - 15-30 minutes each
1. **Weak Password Policy** - Credential spray attack
2. **Default Service Accounts** - Identify high-privilege accounts
3. **Unpatched System** - Public kernel exploit
4. **IIS Basic Auth** - Credential interception
5. **Misconfigured Shares** - Unauthorized file access
6. **UAC Bypass** - Registry credential extraction

#### Medium (7 labs) - 30-60 minutes each
7. **SQL Injection** - Time-based blind SQLi exploitation
8. **AD Delegation Abuse** - S4U ticket forging
9. **Kerberoasting** - Service account password cracking
10. **Directory Traversal** - Path traversal + RCE via upload
11. **GPO Misconfiguration** - Privilege escalation via policy
12. **LDAP Injection** - User enumeration via injection
13. **Token Impersonation** - Token theft and privilege escalation

#### Hard (7 labs) - 60-120 minutes each
14. **Multi-Stage PrivEsc** - Kernel + service exploitation chain
15. **NTLM Relay** - HTTP to LDAP/SMB relay attacks
16. **AD ACL Abuse** - WriteProperty exploitation
17. **WebDAV RCE** - PUT method for code execution
18. **DLL Injection** - Malicious DLL loading
19. **Kerberos S4U** - Service-for-user-to-self attack
20. **Persistence** - Multi-stage backdoors

## Network Configuration

### Default Network Settings

| Setting | Value |
|---------|-------|
| Network | 192.168.56.0/24 (Host-only internal) |
| IP Range | 192.168.56.100 - 192.168.56.119 |
| Gateway | 192.168.56.1 |
| DNS | 8.8.8.8 (external) |
| DHCP | Disabled (static IPs) |

### Port Forwarding

| Lab | RDP Port | WinRM Port |
|-----|----------|-----------|
| Easy-1 through Easy-6 | 5100-5105 | 2100-2105 |
| Medium-1 through Medium-7 | 5106-5112 | 2106-2112 |
| Hard-1 through Hard-7 | 5113-5119 | 2113-2119 |

### Credentials

**Domain Admin**:
- Username: `hackossem\Administrator`
- Password: `P@ssw0rd!2024` (configurable during setup)

**Lab-Specific Credentials**: Provided in Student Mode dashboard per lab

## Troubleshooting

### Application Won't Start
- Ensure running as Administrator
- Check .NET Framework 4.8+ installed
- Verify not running from quarantine/restricted path

### VirtualBox Not Found
```powershell
# Install VirtualBox
choco install virtualbox

# Or download from: https://www.virtualbox.org/wiki/Downloads
# Then run: VBoxManage --version (to verify)
```

### Insufficient Disk Space
```powershell
# Check available space
Get-Volume C: | Select-Object SizeRemaining

# Need 150GB+ free
# Options:
# 1. Clean up %TEMP% folder
# 2. Remove old VMs
# 3. Use different drive with more space
```

### Insufficient RAM
```powershell
# Check available RAM
[Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

# Need 40GB+ free
# Options:
# 1. Close other applications
# 2. Increase page file
# 3. Deploy fewer labs initially (6 instead of 20)
```

### VM Won't Start
```powershell
# Check VM configuration
VBoxManage showvminfo "VulnLab-ad-lab-1"

# Check logs
Get-Content "$env:USERPROFILE\.VirtualBox\VBoxSVC.log" | Select-Object -Last 50

# Restart VirtualBox service
Get-Service | Where-Object {$_.Name -like "*VBox*"} | Restart-Service
```

## Architecture

### Project Structure
```
VulnLabWizard/
├── Forms/
│   ├── WizardForm.cs (Main wizard window)
│   ├── ModeSelectorForm.cs (Mode selection)
│   ├── StudentDashboardForm.cs (Lab management)
│   └── AdminUtilitiesForm.cs (Admin operations)
├── Services/
│   ├── ScriptExecutor.cs (PowerShell runner)
│   ├── EnvironmentValidator.cs (Environment checks)
│   ├── VirtualBoxService.cs (VBoxManage wrapper)
│   └── LogService.cs (Logging)
├── Models/
│   ├── LabDefinition.cs (Lab data)
│   ├── LabConfig.cs (Configuration loader)
│   └── DeploymentState.cs (Deployment state tracking)
├── Program.cs (Entry point, admin check)
├── VulnLabWizard.csproj (Project file)
└── Resources/
    ├── lab-config.json (20 lab definitions)
    ├── vulnerabilities.json (Vulnerability profiles)
    ├── default-settings.ini (Default configuration)
    ├── Create-VMs.ps1 (VM creation)
    ├── Deploy-AD.ps1 (AD setup)
    ├── Deploy-IIS.ps1 (IIS deployment)
    ├── Import-OVA.ps1 (OVA import)
    ├── Manage-VMs.ps1 (VM management)
    ├── Validate-Labs.ps1 (Validation)
    └── utilities.ps1 (Helper functions)
```

### Technology Stack
- **Language**: C# with .NET Framework 4.8+
- **UI**: Windows Forms (native, no external dependencies)
- **Backend**: Embedded PowerShell scripts (extracted at runtime)
- **Data Format**: JSON (lab definitions), INI (settings)

## Building from Source

### Prerequisites
- Visual Studio 2019+ or Visual Studio Community (free)
- .NET Framework 4.8 SDK
- Windows 10+ or Windows Server 2019+

### Build Steps
```powershell
# Clone repository
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem/VulnLabWizard

# Open in Visual Studio
Start-Process VulnLabWizard.csproj

# Or build from command line
msbuild VulnLabWizard.csproj /p:Configuration=Release

# Output: bin/Release/VulnLabWizard.exe
```

## Command-Line Options

```powershell
# Interactive wizard (default)
VulnLabWizard.exe

# Instructor mode with config file
VulnLabWizard.exe --mode instructor --config deployment.json --automate

# Student mode (lab dashboard)
VulnLabWizard.exe --mode student

# Admin utilities
VulnLabWizard.exe --mode admin

# Help
VulnLabWizard.exe --help
```

## Support & Documentation

- **Main Repository**: https://github.com/netanelcyber/hackossem
- **Issues**: https://github.com/netanelcyber/hackossem/issues
- **Documentation**: `/docs/` folder in repository
- **Quick Start**: See QUICKSTART.md

## License

[Specify your license here]

## Contributing

Contributions welcome! Please see CONTRIBUTING.md

## Version

**v1.0.0** - Initial release with 20 Windows vulnerability labs

**Release Date**: August 2026

---

**Built with ❤️ for security education and penetration testing training.**
