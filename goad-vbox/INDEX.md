# GOAD VirtualBox Setup Package - Complete Index

This package contains everything needed to build a GOAD (Game of Active Directory) lab on VirtualBox **without Vagrant**.

## 📦 What You Get

### Documentation (8 Files)
```
docs/
├── 01-QUICKSTART.md           # 10-minute setup guide
├── 02-VM-CREATION.md          # Deep dive into VBoxManage commands
├── 03-WINDOWS-SETUP.md        # Manual Windows Server installation
├── 04-WINRM-SETUP.md          # Enable remote management (critical!)
├── 05-ANSIBLE-INVENTORY.md    # Building inventory files
├── 06-RUNNING-PLAYBOOKS.md    # Executing Ansible provisioning
├── 07-TROUBLESHOOTING.md      # Common issues & solutions
└── 08-VARIANTS.md             # GOAD-full vs GOAD-light comparison
```

### Automation Scripts (6 Files)
```
scripts/
├── check-requirements.sh       # Verify VirtualBox, Ansible, resources
├── network-setup.sh           # Create isolated VirtualBox network
├── create-vms.sh              # Create VMs with VBoxManage
├── cleanup-vms.sh             # Delete all VMs (cleanup)
├── health-check.sh            # Verify lab is properly configured
└── apply-provisioning.sh      # Run Ansible playbooks
```

### Inventory & Configuration
```
inventory/
├── hosts-template.ini         # Ansible inventory template (CUSTOMIZE)
├── group_vars/
│   ├── windows.yml           # Common Windows settings
│   ├── domain_controllers.yml # DC-specific config
│   └── member_servers.yml    # Server-specific config
└── host_vars/
    └── (per-host overrides)
```

### Templates & Helpers
```
templates/
├── ConfigureRemotingForAnsible.ps1  # WinRM setup script (run on Windows)
└── (reference files)
```

## 🚀 Quick Start Path

1. **Read first**: [`README.md`](README.md) (5 minutes)
2. **Verify setup**: `bash scripts/check-requirements.sh`
3. **Follow guide**: [`docs/01-QUICKSTART.md`](docs/01-QUICKSTART.md) (10 minutes)
4. **Create VMs**: `bash scripts/create-vms.sh --variant full`
5. **Install Windows**: Manual GUI on each VM (30-40 minutes)
6. **Enable WinRM**: Run `ConfigureRemotingForAnsible.ps1` on each VM
7. **Configure Ansible**: Edit `inventory/hosts.ini` with your IPs
8. **Provision lab**: `bash scripts/apply-provisioning.sh`

**Total time: 2-3 hours for full setup**

## 📋 File Descriptions

### Documentation

| File | Purpose | Read Time |
|------|---------|-----------|
| **01-QUICKSTART.md** | Step-by-step setup guide, assumes no prior knowledge | 10 min |
| **02-VM-CREATION.md** | Deep technical dive into VBoxManage, for reference | 15 min |
| **03-WINDOWS-SETUP.md** | Manual Windows Server installation guide | 10 min |
| **04-WINRM-SETUP.md** | **CRITICAL**: Enabling remote management for Ansible | 5 min |
| **05-ANSIBLE-INVENTORY.md** | Building and configuring inventory files | 10 min |
| **06-RUNNING-PLAYBOOKS.md** | Executing Ansible provisioning, monitoring, debugging | 15 min |
| **07-TROUBLESHOOTING.md** | Solutions to common problems | Reference |
| **08-VARIANTS.md** | GOAD-full vs GOAD-light, choosing the right variant | 10 min |

### Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **check-requirements.sh** | Verify prerequisites (VirtualBox, Ansible, disk, RAM) | Once, at start |
| **network-setup.sh** | Create isolated internal network for GOAD VMs | Once, before creating VMs |
| **create-vms.sh** | Create VirtualBox VMs with disks and network | Once |
| **cleanup-vms.sh** | Delete all GOAD VMs (careful!) | When tearing down lab |
| **health-check.sh** | Verify lab is working (domain, users, WinRM) | After provisioning |
| **apply-provisioning.sh** | Run all Ansible playbooks for configuration | After Windows is installed |

### Scripts Usage Examples

```bash
# Check prerequisites
bash scripts/check-requirements.sh

# Setup network
bash scripts/network-setup.sh --variant full

# Create VMs for GOAD Full
bash scripts/create-vms.sh \
  --variant full \
  --iso-2016 /path/to/WinServer2016.iso \
  --iso-2019 /path/to/WinServer2019.iso

# Create VMs for GOAD Light
bash scripts/create-vms.sh \
  --variant light \
  --iso-2016 /path/to/WinServer2016.iso

# Apply provisioning
bash scripts/apply-provisioning.sh \
  --variant full \
  --inventory inventory/hosts.ini

# Health check
bash scripts/health-check.sh --inventory inventory/hosts.ini

# Cleanup (WARNING: deletes all VMs)
bash scripts/cleanup-vms.sh --variant full
```

## 🎯 Directory Structure After Setup

```
goad-vbox/
├── README.md                      # Main overview
├── INDEX.md                       # This file
├── docs/                          # Documentation
├── scripts/                       # Automation scripts
├── inventory/                     # Ansible inventory
│   └── hosts.ini                 # CUSTOMIZE THIS!
├── templates/                     # Helper scripts
├── playbooks/                     # Ansible playbooks (reference)
└── logs/                          # Generated logs
    ├── check-requirements.log
    ├── network-setup.log
    ├── create-vms.log
    ├── provision.log
    └── health-check.log
```

## ✅ What You Need Before Starting

### Hardware
- **CPU**: 4+ cores (8+ recommended for GOAD-full)
- **RAM**: 8GB minimum (16GB recommended for GOAD-full)
- **Disk**: 100GB free (160GB+ for GOAD-full)

### Software (install if missing)
- **VirtualBox 6.1+** (or 7.0+)
- **Ansible 2.10+**
- **Git** (to clone GOAD playbooks)
- **Python 3.7+**
- **pywinrm** (Python module): `pip install pywinrm`

### ISOs (download)
- **Windows Server 2016** (~6GB) - for domain controllers
- **Windows Server 2019** (~6GB) - for member servers
- **Windows 10** (optional, ~4GB) - for workstations

## 🔑 Key Concepts

### Three Stages of GOAD
1. **Templating** → Create base images/ISOs (you download)
2. **Providing** → Create VMs (our scripts do this with VBoxManage)
3. **Provisioning** → Configure with Ansible (Ansible playbooks)

### Why No Vagrant?
- Direct VirtualBox control (no abstraction)
- Works with any Windows ISO version
- Simpler to understand & debug
- More control over VM parameters

## 📞 Getting Help

### If Something Goes Wrong

1. **Check logs**:
   ```bash
   tail -f logs/provision.log
   tail -f logs/health-check.log
   ```

2. **Read troubleshooting guide**:
   ```bash
   cat docs/07-TROUBLESHOOTING.md
   ```

3. **Test connectivity**:
   ```bash
   # Verify VMs are running
   VBoxManage list runningvms
   
   # Test WinRM
   ansible -i inventory/hosts.ini windows -m win_ping -vvv
   ```

4. **Check Windows Event Viewer**:
   - RDP into failing VM
   - Open Event Viewer → Windows Logs → Application/System
   - Look for AD-related errors

### External Resources
- **GOAD Official**: https://github.com/Orange-Cyberdefense/GOAD
- **VirtualBox Manual**: https://www.virtualbox.org/manual/
- **Ansible Windows Guide**: https://docs.ansible.com/ansible/latest/os_guide/windows.html
- **WinRM Documentation**: https://docs.microsoft.com/en-us/windows/win32/winrm/

## 🔐 Security Notes

### Lab-Only Configuration
This setup uses **insecure defaults** suitable only for lab environments:
- ❌ Unencrypted WinRM (HTTP, not HTTPS)
- ❌ Basic authentication (not Kerberos)
- ❌ Weak passwords allowed
- ❌ Firewall relaxed

### For Production Use
- ✅ Use HTTPS (SSL certificates)
- ✅ Use Kerberos authentication
- ✅ Enforce strong passwords
- ✅ Restrict firewall rules
- ✅ Use Vault for credentials
- ✅ Enable audit logging

## 📊 Variants Quick Reference

### GOAD Full (5 VMs)
- **Resources**: 10 vCPU, 10GB RAM, 280GB disk
- **Time**: 2-3 hours
- **VMs**: dc01, dc02, srv02, srv03, ws01
- **Use case**: Complete AD lab with all features

### GOAD Light (3 VMs)
- **Resources**: 6 vCPU, 6GB RAM, 160GB disk
- **Time**: 1.5-2 hours
- **VMs**: dc01, srv02, ws01
- **Use case**: Learning AD basics, pentesting practice

## 💾 Files Included Summary

| Category | Count | Files |
|----------|-------|-------|
| **Documentation** | 8 | `.md` files in `docs/` |
| **Scripts** | 6 | `.sh` files in `scripts/` |
| **Inventory** | 2 | `.ini` and `.yml` files |
| **Templates** | 1 | PowerShell script |
| **Logs** | Dynamic | Generated at runtime |

**Total static files**: ~17 files

## 🎓 Recommended Reading Order

**For First-Time Users**:
1. README.md (this directory)
2. docs/01-QUICKSTART.md
3. docs/08-VARIANTS.md (choose GOAD-full or light)
4. Follow QUICKSTART step by step

**For Experienced AD/Pentesting**:
1. Skip to docs/01-QUICKSTART.md
2. Reference docs/02-VM-CREATION.md as needed
3. Run scripts

**For Troubleshooting**:
1. docs/07-TROUBLESHOOTING.md (start here!)
2. Cross-reference with docs/04-WINRM-SETUP.md (if WinRM issues)
3. Cross-reference with docs/06-RUNNING-PLAYBOOKS.md (if Ansible issues)

## 📝 License

This GOAD setup package follows the original GOAD project license (GPLv3).
See https://github.com/Orange-Cyberdefense/GOAD for official license.

---

**Ready to build your GOAD lab?**

Start here: `bash scripts/check-requirements.sh`

Then read: `cat README.md`

Then follow: `cat docs/01-QUICKSTART.md`
