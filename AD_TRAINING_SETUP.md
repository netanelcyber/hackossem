# Active Directory Training Environment - 10 Machines

## Overview

This setup creates 10 Virtual Box machines configured for Active Directory training and testing. All machines are part of the same domain (`training.lab`) and span multiple roles including domain controllers, workstations, file servers, SQL servers, mail servers, and web servers.

## Machine Specifications

### 10 Training Machines:

| # | Name | Role | IP | Memory | CPUs | Disk | Purpose |
|---|------|------|----|---------|----|------|---------|
| 1 | AD-DC01 | Domain Controller | 192.168.100.10 | 2GB | 2 | 50GB | Primary DC, DNS, DHCP |
| 2 | AD-WS01 | Workstation | 192.168.100.20 | 2GB | 2 | 40GB | User training |
| 3 | AD-WS02 | Workstation | 192.168.100.21 | 2GB | 2 | 40GB | User training |
| 4 | AD-SRV01 | File Server | 192.168.100.30 | 2GB | 2 | 100GB | File sharing |
| 5 | AD-SRV02 | File Server | 192.168.100.31 | 2GB | 2 | 100GB | DFS, Replication |
| 6 | AD-WS03 | Workstation | 192.168.100.22 | 2GB | 2 | 40GB | Group policies |
| 7 | AD-WS04 | Workstation | 192.168.100.23 | 2GB | 2 | 40GB | Group policies |
| 8 | AD-SQL01 | SQL Server | 192.168.100.40 | 4GB | 4 | 100GB | Database services |
| 9 | AD-MAIL01 | Mail Server | 192.168.100.50 | 3GB | 3 | 100GB | Exchange/Mail |
| 10 | AD-WEB01 | Web Server | 192.168.100.60 | 2GB | 2 | 50GB | IIS/Web services |

## Prerequisites

### Hardware Requirements
- **CPU**: Multi-core processor (preferably 8+ cores)
- **RAM**: 32GB+ recommended (10 machines × 2-4GB each)
- **Disk**: 800GB+ SSD recommended
- **Network**: Bridged network adapter configured

### Software Requirements
- **VirtualBox**: 7.0 or newer
- **Windows Server 2022**: ISO file for installation
- **Windows 10/11**: ISO files for workstations
- **PowerShell**: 5.1 or newer
- **Administrator access**: Required for hypervisor operations

## Quick Start

### 1. Prepare VirtualBox Environment

```powershell
# Create base directory
New-Item -ItemType Directory -Path "C:\VirtualBox VMs" -Force

# Ensure VirtualBox is running
Start-Service -Name VBoxDRIVER -ErrorAction SilentlyContinue
```

### 2. Create All VMs

```powershell
# Navigate to the directory containing the scripts
cd C:\path\to\hackossem

# Create all 10 VMs
.\manage_ad_machines.ps1 -Action CreateAll
```

### 3. Install Operating Systems

1. Start each VM in VirtualBox UI or via script
2. Boot from ISO and complete Windows installation
3. Install VirtualBox Guest Additions for better performance
4. Snapshot VMs after clean OS installation (optional but recommended)

### 4. Configure Domain and Machines

```powershell
# Run configuration on first DC (AD-DC01)
.\ad_machines_setup.ps1 -DomainName "training.lab" `
                        -DomainAdmin "Administrator" `
                        -DomainPassword "P@ssw0rd123!"
```

## Detailed Setup Steps

### Step 1: Create VirtualBox Base Infrastructure

```powershell
# Create VMs
.\manage_ad_machines.ps1 -Action CreateAll

# Verify creation
.\manage_ad_machines.ps1 -Action Status
```

### Step 2: Install Windows Operating Systems

For each VM:
1. Start in VirtualBox
2. Insert ISO medium
3. Complete Windows installation
4. Set administrator password
5. Install VirtualBox Guest Additions
6. Shutdown VM

### Step 3: Configure First Domain Controller (AD-DC01)

Connect to AD-DC01 and run:

```powershell
# Set static IP
$IPAddress = "192.168.100.10"
$Gateway = "192.168.100.1"
$DNSPrimary = "127.0.0.1"

# Configure network adapter
Get-NetAdapter | New-NetIPAddress -IPAddress $IPAddress `
    -PrefixLength 24 -DefaultGateway $Gateway -ErrorAction SilentlyContinue

# Set DNS
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex `
    -ServerAddresses $DNSPrimary

# Rename computer
Rename-Computer -NewName "AD-DC01" -Force

# Install AD DS and DNS
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

# Create Active Directory Forest
$safeModePassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
Install-ADDSForest -DomainName "training.lab" `
    -SafeModeAdministratorPassword $safeModePassword `
    -Force

# Restart
Restart-Computer -Force
```

### Step 4: Configure Additional Servers

For each additional machine (AD-WS01 through AD-WEB01):

```powershell
# Set static IP (adjust for each machine per config.json)
$IPAddress = "192.168.100.20"  # Change per machine
$Gateway = "192.168.100.1"
$DNS1 = "192.168.100.10"

# Network configuration
Get-NetAdapter | New-NetIPAddress -IPAddress $IPAddress `
    -PrefixLength 24 -DefaultGateway $Gateway -ErrorAction SilentlyContinue

Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex `
    -ServerAddresses $DNS1

# Rename computer
Rename-Computer -NewName "AD-WS01" -Force  # Use appropriate hostname

# Join domain
$credential = New-Object System.Management.Automation.PSCredential(
    "training.lab\Administrator",
    (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force)
)
Add-Computer -DomainName "training.lab" -Credential $credential -Force

# Install role-specific features (see Feature Installation section)

# Restart
Restart-Computer -Force
```

## Feature Installation

### Workstations (AD-WS01-04)
- Join domain
- Update Group Policy

### File Servers (AD-SRV01, AD-SRV02)
```powershell
Install-WindowsFeature File-Services, FS-FileServer, FS-SyncShareService `
    -IncludeManagementTools
```

### SQL Server (AD-SQL01)
```powershell
Install-WindowsFeature NET-Framework-45-Core, RSAT-AD-Tools `
    -IncludeManagementTools
# Then install SQL Server 2022 from ISO
```

### Mail Server (AD-MAIL01)
```powershell
Install-WindowsFeature NET-Framework-45-Core, RSAT-AD-Tools `
    -IncludeManagementTools
# Then install Exchange Server 2019/2022 from ISO
```

### Web Server (AD-WEB01)
```powershell
Install-WindowsFeature Web-Server, Web-Asp-Net45, Web-Mgmt-Tools `
    -IncludeManagementTools
```

## Management Commands

### Start All VMs
```powershell
.\manage_ad_machines.ps1 -Action StartAll
```

### Stop All VMs
```powershell
.\manage_ad_machines.ps1 -Action StopAll
```

### Check Status
```powershell
.\manage_ad_machines.ps1 -Action Status
```

### Delete All VMs
```powershell
.\manage_ad_machines.ps1 -Action DeleteAll
```

## Network Configuration

### Network Details
- **Network**: 192.168.100.0/24
- **Gateway**: 192.168.100.1
- **DNS Primary**: 192.168.100.10 (AD-DC01)
- **DNS Secondary**: 8.8.8.8 (Google)
- **Adapter Type**: Bridged (connects to host network)

### Adapter Configuration in VirtualBox
1. VirtualBox Settings → Network
2. Name: Bridged Adapter
3. Interface: Your primary network adapter (Ethernet/Wi-Fi)

## Security Notes

⚠️ **Important**: These are training machines. The passwords and configurations are for educational purposes only.

### Default Credentials
- **Domain**: training.lab
- **Admin Username**: Administrator
- **Admin Password**: P@ssw0rd123!
- **NETBIOS Name**: TRAINING

### Security Recommendations
1. Change default passwords immediately
2. Enable Windows Firewall on all machines
3. Configure Windows Defender on all machines
4. Use Group Policy to enforce security baselines
5. Enable audit logging on domain controllers
6. Restrict domain admin account usage
7. Use strong passwords for all accounts

## Training Scenarios

### 1. User and Group Management
- Create organizational units (OUs)
- Create user accounts
- Create security groups
- Manage group memberships
- Use workstations (AD-WS01-04) to test logins

### 2. File Server Management
- Configure shares on AD-SRV01 and AD-SRV02
- Set NTFS and share permissions
- Test access from workstations
- Practice DFS configuration

### 3. Group Policy
- Create Group Policy Objects (GPOs)
- Link GPOs to OUs
- Deploy settings to workstations
- Test policy enforcement

### 4. Server Roles
- Database administration (SQL Server)
- Email services (Exchange)
- Web services (IIS)

### 5. Domain Controller Management
- Monitor replication
- Manage DNS zones
- Manage DHCP (if configured)
- User/group auditing

## Troubleshooting

### VMs won't start
- Check VirtualBox is installed correctly
- Verify VirtualBox service is running
- Check host virtualization is enabled in BIOS

### Network connectivity issues
- Verify bridged adapter configuration
- Check network cable/Wi-Fi connection
- Ping gateway from within VM
- Check DNS resolution

### Domain join fails
- Ensure DC is running and responsive
- Verify network connectivity
- Check credentials
- Verify DNS is resolving domain name

### Performance issues
- Reduce number of running VMs
- Increase host RAM
- Enable 3D acceleration (carefully)
- Use SSD instead of HDD

## Resources

- [Active Directory Documentation](https://docs.microsoft.com/en-us/windows-server/identity/identity-and-access)
- [VirtualBox Manual](https://www.virtualbox.org/manual/ch00.html)
- [Windows Server Documentation](https://docs.microsoft.com/en-us/windows-server/)
- [Group Policy Overview](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/get-started-with-active-directory-domain-services)

## File Structure

```
hackossem/
├── ad_machines_setup.ps1          # Main setup script
├── manage_ad_machines.ps1         # VM management script
├── machines_config.json           # Machine configurations
└── AD_TRAINING_SETUP.md          # This file
```

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review machine configuration in machines_config.json
3. Check Event Viewer logs on domain controller
4. Review PowerShell error messages

---

**Last Updated**: August 2024
**Version**: 1.0
**Environment**: VirtualBox 7.0+, Windows Server 2022, Windows 10/11
