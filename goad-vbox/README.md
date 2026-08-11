# GOAD VirtualBox + Ansible Setup (No Vagrant)

Complete guide for deploying **Game of Active Directory (GOAD)** directly on **VirtualBox** using **Ansible** only—no Vagrant.

## 🎯 Philosophy: 3-Stage GOAD Breakdown

GOAD consists of three independent stages:

1. **Templating** → Create ISO/base images
2. **Providing** → Create VMs (we skip Vagrant entirely; use `VBoxManage` scripts)
3. **Provisioning** → Configure with Ansible playbooks

By decoupling **providing** from **provisioning**, you can:
- Use your own VM creation method (VirtualBox directly)
- Replace Vagrant with any automation tool
- Run Ansible against ANY Windows machines (existing, cloud, hybrid)

## 📚 Documentation Structure

```
goad-vbox/
├── README.md                          # This file
├── docs/
│   ├── 01-QUICKSTART.md              # 10-minute setup
│   ├── 02-VM-CREATION.md             # Creating VMs with VBoxManage
│   ├── 03-WINDOWS-SETUP.md           # Manual Windows Server config
│   ├── 04-WINRM-SETUP.md             # Enabling WinRM (critical!)
│   ├── 05-ANSIBLE-INVENTORY.md       # Building inventory files
│   ├── 06-RUNNING-PLAYBOOKS.md       # Executing provisioning
│   ├── 07-TROUBLESHOOTING.md         # Common issues & solutions
│   └── 08-VARIANTS.md                # GOAD-full vs GOAD-light specs
├── scripts/
│   ├── check-requirements.sh          # Verify VirtualBox, Ansible, etc.
│   ├── create-vms.sh                 # VBoxManage VM creation
│   ├── network-setup.sh              # Create isolated network
│   ├── cleanup-vms.sh                # Remove all VMs & storage
│   ├── health-check.sh               # Verify VM & WinRM connectivity
│   └── apply-provisioning.sh         # Run Ansible playbooks
├── inventory/
│   ├── hosts-template.ini            # Inventory template (CUSTOMIZE!)
│   ├── group_vars/
│   │   ├── windows.yml               # Common Windows vars
│   │   ├── domain_controllers.yml    # DC-specific vars
│   │   └── member_servers.yml        # Server-specific vars
│   └── host_vars/
│       └── dc01.yml                  # Per-host overrides
├── playbooks/
│   ├── 0-preflight.yml               # DNS, firewall checks
│   ├── 1-domain-setup.yml            # Create AD forest/domain
│   ├── 2-users-groups.yml            # Create AD users & groups
│   ├── 3-gpo-policies.yml            # Deploy GPOs
│   ├── 4-services.yml                # Install ADCS, etc.
│   └── 5-misconfigs.yml              # Create vulnerable configs
├── templates/
│   ├── Vagrantfile-reference         # Vagrant spec reference (VM sizes)
│   ├── ConfigureRemotingForAnsible.ps1 # WinRM setup script
│   └── unattend.xml-sample           # Windows answer file (optional)
└── logs/
    └── (created at runtime)
```

## 🚀 Quick Start (10 Minutes)

### 1. Check Prerequisites
```bash
cd goad-vbox
bash scripts/check-requirements.sh
```

### 2. Create VirtualBox Network
```bash
bash scripts/network-setup.sh --variant full
# Creates isolated network for GOAD VMs
```

### 3. Create VMs
```bash
bash scripts/create-vms.sh --variant full --iso /path/to/WinServer2016.iso
# Creates 5 VMs for GOAD-full
```

### 4. Install Windows on Each VM (Manual GUI)
For each VM:
```bash
VBoxManage startvm dc01 --type gui
# Follow Windows Server installation wizard
```

### 5. Configure WinRM on Each VM
Copy and run on each Windows machine (run as Administrator in PowerShell):
```powershell
# On Windows machine:
# Copy ConfigureRemotingForAnsible.ps1 to C:\
cd C:\
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
C:\ConfigureRemotingForAnsible.ps1
```

### 6. Build Inventory
```bash
# Edit inventory/hosts-template.ini with your IP addresses
cp inventory/hosts-template.ini inventory/hosts.ini
# Update IP addresses, credentials, hostnames
```

### 7. Run Ansible Provisioning
```bash
bash scripts/apply-provisioning.sh --variant full --inventory inventory/hosts.ini
# Configures all VMs: domain setup, users, groups, policies, etc.
```

## 🏗️ Architecture: What Gets Created

### GOAD Full (5 VMs)
| VM | OS | vCPU | RAM | Disk | Role |
|----|----|----|-----|------|------|
| **dc01** | Windows Server 2016 | 2 | 2GB | 60GB | Primary DC |
| **dc02** | Windows Server 2016 | 2 | 2GB | 60GB | Secondary DC |
| **srv02** | Windows Server 2019 | 2 | 2GB | 60GB | Member Server |
| **srv03** | Windows Server 2019 | 2 | 2GB | 60GB | Member Server |
| **ws01** | Windows 10 | 2 | 2GB | 40GB | Workstation |

**Total**: 10 vCPU, 10GB RAM, 280GB disk  
**Network**: Isolated internal network (192.168.1.0/24)

### GOAD Light (3 VMs)
| VM | OS | vCPU | RAM | Disk | Role |
|----|----|----|-----|------|------|
| **dc01** | Windows Server 2016 | 2 | 2GB | 60GB | Primary DC |
| **srv02** | Windows Server 2019 | 2 | 2GB | 60GB | Member Server |
| **ws01** | Windows 10 | 2 | 2GB | 40GB | Workstation |

**Total**: 6 vCPU, 6GB RAM, 160GB disk

## 🔑 Key Differences from Vagrant Setup

| Aspect | Vagrant | VirtualBox Direct |
|--------|---------|-------------------|
| **VM Creation** | Vagrantfile + Vagrant CLI | VBoxManage scripts |
| **Network** | Managed by Vagrant provider plugin | Manual `VBoxManage network` |
| **Provisioning** | Vagrant + Ansible | Ansible only |
| **Complexity** | Higher abstraction, less control | Lower, direct VirtualBox API |
| **Flexibility** | Locked into Vagrant box versioning | Full control over Windows ISO |
| **Scaling** | Can use plugins (Proxmox, etc.) | Limited to VirtualBox |

## 📋 Workflow Summary

```
┌─────────────────────────────────────────┐
│ 1. Check Prerequisites                  │
│    (VirtualBox, VBoxManage, Ansible)    │
└──────────────┬──────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ 2. Setup VirtualBox Network              │
│    (Isolated internal network)           │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ 3. Create VMs with VBoxManage            │
│    (Disk, vCPU, RAM, NICs)               │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ 4. Install Windows Server (Manual GUI)   │
│    - Static IP (192.168.1.x)             │
│    - Admin password set                  │
│    - NOT joined to domain yet            │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ 5. Enable WinRM (Remote Management)      │
│    - Run ConfigureRemotingForAnsible.ps1 │
│    - Test connectivity: ansible -i hosts │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ 6. Create Ansible Inventory              │
│    (hosts.ini with IPs & credentials)    │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ 7. Run Ansible Provisioning              │
│    - Domain creation                     │
│    - User/group creation                 │
│    - GPO policies                        │
│    - Services (ADCS, etc.)               │
│    - Misconfigs (for testing)            │
└──────────────┴───────────────────────────┘
```

## 💾 Prerequisites & Installation

### Linux (Debian/Ubuntu)
```bash
# VirtualBox
sudo apt-get install virtualbox virtualbox-dkms linux-headers-$(uname -r)
sudo usermod -aG vboxusers $(whoami)

# Ansible
sudo apt-get install ansible

# VBoxManage should be in PATH automatically
which VBoxManage
```

### macOS
```bash
# VirtualBox (via Homebrew)
brew install virtualbox

# Ansible
brew install ansible

# Verify
VBoxManage --version
ansible --version
```

### Windows (WSL2)
```bash
# Inside WSL2:
sudo apt-get install virtualbox-guest-additions-iso  # Optional
sudo apt-get install ansible

# VirtualBox on Windows host + WSL2 Ansible
# (VirtualBox must be installed on Windows, not in WSL)
```

## 📖 Next Steps

1. **First time?** → [`docs/01-QUICKSTART.md`](docs/01-QUICKSTART.md)
2. **Creating VMs?** → [`docs/02-VM-CREATION.md`](docs/02-VM-CREATION.md)
3. **Windows setup?** → [`docs/03-WINDOWS-SETUP.md`](docs/03-WINDOWS-SETUP.md)
4. **WinRM issues?** → [`docs/04-WINRM-SETUP.md`](docs/04-WINRM-SETUP.md)
5. **Ansible inventory?** → [`docs/05-ANSIBLE-INVENTORY.md`](docs/05-ANSIBLE-INVENTORY.md)
6. **Running playbooks?** → [`docs/06-RUNNING-PLAYBOOKS.md`](docs/06-RUNNING-PLAYBOOKS.md)
7. **Troubleshooting?** → [`docs/07-TROUBLESHOOTING.md`](docs/07-TROUBLESHOOTING.md)

## 🎓 Learning Path

```
Beginner:
  1. Read README (you are here)
  2. Run docs/01-QUICKSTART.md
  3. Use scripts/create-vms.sh

Intermediate:
  1. Understand VBoxManage (docs/02-VM-CREATION.md)
  2. Configure WinRM manually (docs/04-WINRM-SETUP.md)
  3. Build custom inventory (docs/05-ANSIBLE-INVENTORY.md)

Advanced:
  1. Modify Ansible playbooks
  2. Add custom misconfigurations
  3. Integrate with pen-testing framework
```

## 🐛 Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| VirtualBox kernel module not loaded | `sudo modprobe vboxdrv` |
| VMs get no IP | Check network settings, enable DHCP |
| Ansible connection timeout | Verify WinRM, check firewall |
| Domain join fails | Verify DNS points to DC |
| PowerShell execution policy blocks script | `Set-ExecutionPolicy RemoteSigned -Scope Process` |

Full troubleshooting: [`docs/07-TROUBLESHOOTING.md`](docs/07-TROUBLESHOOTING.md)

## 📞 Resources

- **GOAD Official**: https://github.com/Orange-Cyberdefense/GOAD
- **VirtualBox Manual**: https://www.virtualbox.org/manual/
- **Ansible Windows**: https://docs.ansible.com/ansible/latest/os_guide/windows.html
- **WinRM Guide**: https://docs.microsoft.com/en-us/windows/win32/winrm/about-windows-remote-management

---

**Ready to build your AD lab?** Start with `bash scripts/check-requirements.sh`!
