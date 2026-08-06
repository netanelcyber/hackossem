# 🏫 VulnLab AD Labs - Individual Lab VMs Guide

## עברית / Hebrew

יצירת VM נפרד לכל מעבדה של VulnLab AD. כל מעבדה יהיה ב-VM אחד עם פורט משלו.

---

## English

Create a separate VM for each VulnLab AD Lab. Each lab runs in its own VM with unique port mapping.

---

## 📋 Overview

### The 5 AD Labs

| # | Lab Name | Difficulty | Port | IP | VM Name |
|---|----------|-----------|------|----|----|
| 1 | Active Directory Basics | Easy | 5001 | 192.168.56.11 | VulnLab-ad-lab-1 |
| 2 | LDAP Enumeration & Exploitation | Medium | 5002 | 192.168.56.12 | VulnLab-ad-lab-2 |
| 3 | Kerberos & ASREProast | Medium | 5003 | 192.168.56.13 | VulnLab-ad-lab-3 |
| 4 | Privilege Escalation in AD | Hard | 5004 | 192.168.56.14 | VulnLab-ad-lab-4 |
| 5 | Golden Ticket & Domain Takeover | Hard | 5005 | 192.168.56.15 | VulnLab-ad-lab-5 |

---

## 🚀 Quick Start

### Option 1: Multiple Lab VMs with Vagrant (Recommended)

```bash
# Create individual lab VMs
./create-individual-labs.sh

# This creates:
# - lab-vms-vagrant/Vagrantfile (master - all 5 labs)
# - lab-vms-vagrant/Vagrantfile.ad-lab-* (individual labs)
# - lab-vms-vagrant/README.md

# Launch all labs
cd lab-vms-vagrant
vagrant up

# Or launch specific lab
vagrant up ad-lab-1
```

**Access**:
- Lab 1: http://localhost:5001
- Lab 2: http://localhost:5002
- Lab 3: http://localhost:5003
- Lab 4: http://localhost:5004
- Lab 5: http://localhost:5005

### Option 2: Export Individual Lab OVA Files

```bash
# Create separate OVA for each lab
./create-lab-vms.sh

# This creates:
# - lab-vms/lab-ad-lab-1.ova
# - lab-vms/lab-ad-lab-2.ova
# - lab-vms/lab-ad-lab-3.ova
# - lab-vms/lab-ad-lab-4.ova
# - lab-vms/lab-ad-lab-5.ova
# - lab-vms/MANIFEST.md
# - lab-vms/*.sha256 (checksums)

# Then import each OVA
VBoxManage import lab-vms/lab-ad-lab-1.ova --vsys 0 --vmname "AD-Lab-1"
VBoxManage import lab-vms/lab-ad-lab-2.ova --vsys 0 --vmname "AD-Lab-2"
# ... etc
```

---

## 📚 Using Individual Lab VMs with Vagrant

### Launch Everything

```bash
cd lab-vms-vagrant
vagrant up
```

This will:
- Create 5 separate VMs
- Allocate 2GB RAM each (10GB total)
- Configure networking (192.168.56.11-15)
- Map ports 5001-5005
- Install all dependencies

### Launch Specific Lab

```bash
cd lab-vms-vagrant
vagrant up ad-lab-1
```

Only Lab 1 will be created.

### SSH into Lab

```bash
# SSH into Lab 1
cd lab-vms-vagrant
vagrant ssh ad-lab-1

# SSH into Lab 3
vagrant ssh ad-lab-3
```

### Check Status

```bash
# Check all VMs
vagrant status

# Output example:
# Current machine states:
# ad-lab-1          running (virtualbox)
# ad-lab-2          running (virtualbox)
# ad-lab-3          running (virtualbox)
# ad-lab-4          running (virtualbox)
# ad-lab-5          running (virtualbox)
```

### Stop a Lab

```bash
# Stop Lab 1
vagrant halt ad-lab-1

# Stop all labs
vagrant halt
```

### Delete a Lab

```bash
# Delete Lab 1 (removes VM)
vagrant destroy ad-lab-1

# Delete all labs
vagrant destroy
```

### Reload Configuration

```bash
# Reload Lab 1 (restart with new config)
vagrant reload ad-lab-1
```

---

## 🐳 Using OVA Files (Export)

### Generate OVA Files

```bash
./create-lab-vms.sh
```

Creates in `lab-vms/` directory:
- `lab-ad-lab-1.ova` (~5-10 GB each)
- `lab-ad-lab-1.ova.sha256` (checksum)
- `MANIFEST.md` (documentation)

### Import OVA into VirtualBox

```bash
# Import Lab 1
VBoxManage import lab-vms/lab-ad-lab-1.ova \
  --vsys 0 \
  --vmname "AD-Lab-1" \
  --description "VulnLab Active Directory Basics"

# Import all labs
for i in {1..5}; do
  VBoxManage import lab-vms/lab-ad-lab-$i.ova \
    --vsys 0 \
    --vmname "AD-Lab-$i"
done
```

### Launch Imported VM

```bash
# Start Lab 1
VBoxManage startvm "AD-Lab-1"

# Or start via GUI
```

### Verify Integrity

```bash
# Verify downloaded files
sha256sum -c lab-vms/lab-ad-lab-1.ova.sha256

# Output: lab-ad-lab-1.ova: OK
```

---

## 🔄 Workflow Examples

### Example 1: Learn All Labs Progressively

```bash
# Start with Lab 1 (Easy)
cd lab-vms-vagrant
vagrant up ad-lab-1
# Work through Lab 1...
# http://localhost:5001

# After completing Lab 1, add Lab 2
vagrant up ad-lab-2
# Now both labs run
# http://localhost:5001 and http://localhost:5002

# Continue adding labs as needed
vagrant up ad-lab-3
vagrant up ad-lab-4
vagrant up ad-lab-5
```

### Example 2: Compare Labs Side-by-Side

```bash
# Run 2 labs at same time for comparison
cd lab-vms-vagrant
vagrant up ad-lab-2 ad-lab-3

# Terminal 1: SSH into Lab 2
vagrant ssh ad-lab-2

# Terminal 2: SSH into Lab 3
vagrant ssh ad-lab-3

# Compare LDAP and Kerberos implementations
```

### Example 3: Test Multiple Configurations

```bash
# Start all labs
vagrant up

# Test different scenarios in each lab
# Lab 1: Basic AD concepts
# Lab 2: LDAP attacks
# Lab 3: Kerberos attacks
# Lab 4: Privilege escalation
# Lab 5: Domain takeover
```

---

## 🛠️ Managing Multiple VMs

### View All VMs

```bash
# List all VBoxManage VMs
VBoxManage list vms

# List running VMs
VBoxManage list runningvms
```

### VM Details

```bash
# Get info about specific VM
VBoxManage showvminfo "VulnLab-ad-lab-1"

# Get network info
VBoxManage showvminfo "VulnLab-ad-lab-1" | grep IP
```

### Resource Management

```bash
# Modify memory (must be powered off)
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096

# Modify CPUs
VBoxManage modifyvm "VulnLab-ad-lab-1" --cpus 4

# Modify VRAM
VBoxManage modifyvm "VulnLab-ad-lab-1" --vram 64
```

---

## 📊 Resource Requirements

### Memory per Lab
- Lab 1 (Easy): 1GB minimum
- Lab 2 (Medium): 2GB recommended
- Lab 3 (Medium): 2GB recommended
- Lab 4 (Hard): 2GB+ recommended
- Lab 5 (Hard): 2GB+ recommended

### Total Resources

| Setup | VMs | RAM | Disk | CPU |
|-------|-----|-----|------|-----|
| One Lab | 1 | 2GB | 20GB | 2 |
| Two Labs | 2 | 4GB | 40GB | 4 |
| All Labs | 5 | 10GB | 100GB | 10 |

### Optimize for Your System

```bash
# Edit Vagrantfile to change resources
# lab-vms-vagrant/Vagrantfile

# Example: Reduce memory per VM
vb.memory = 1024  # Instead of 2048
vb.cpus = 1       # Instead of 2

# Then reload
vagrant reload
```

---

## 🔐 Backup & Restore

### Backup Single Lab VM

```bash
# Create snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" take "before-testing" --description "Backup before testing"

# List snapshots
VBoxManage snapshot "VulnLab-ad-lab-1" list

# Restore from snapshot
VBoxManage snapshot "VulnLab-ad-lab-1" restore "before-testing"
```

### Export Lab for Sharing

```bash
# Export Lab 1 as OVA
VBoxManage export "VulnLab-ad-lab-1" -o ad-lab-1-backup.ova

# Share the file
# scp ad-lab-1-backup.ova user@server:
# Upload to cloud storage
```

### Backup All Labs

```bash
# Create backup directory
mkdir -p backups

# Export all labs
for i in {1..5}; do
  VBoxManage export "VulnLab-ad-lab-$i" \
    -o "backups/ad-lab-$i-backup.ova"
done

# Create manifest
tar -czf labs-backup-$(date +%Y%m%d).tar.gz backups/
```

---

## 🐛 Troubleshooting

### VM Won't Start

```bash
# Check logs
vagrant up ad-lab-1 --debug

# Check VirtualBox status
VBoxManage list vms
VBoxManage list runningvms

# Reset VM
vagrant destroy ad-lab-1
vagrant up ad-lab-1
```

### Port Conflicts

```bash
# Check which process uses port
lsof -i :5001

# Kill process or change port in Vagrantfile
# Edit: config.vm.network "forwarded_port", guest: 5000, host: 5006
vagrant reload ad-lab-1
```

### Networking Issues

```bash
# Check VM networking
VBoxManage modifyvm "VulnLab-ad-lab-1" --natdnshostresolver1 on

# Restart VM
vagrant reload ad-lab-1

# Test connectivity
vagrant ssh ad-lab-1
ping 8.8.8.8
```

### Disk Space Issues

```bash
# Check disk usage
du -sh lab-vms-vagrant/.vagrant/

# Clean up old boxes
vagrant box prune

# Remove old VMs
vagrant destroy ad-lab-3 ad-lab-4
```

---

## 📈 Advanced Usage

### Automate Lab Setup

```bash
#!/bin/bash
# setup-all-labs.sh

cd lab-vms-vagrant

echo "Creating all labs..."
vagrant up

echo "Waiting for labs to initialize..."
sleep 30

echo "Testing Lab 1..."
curl http://localhost:5001

echo "All labs ready!"
```

### Monitor All Labs

```bash
# Terminal 1: Watch all logs
watch 'vagrant status'

# Terminal 2: SSH and test
for i in {1..5}; do
  echo "Lab $i:"
  curl http://localhost:500$i
done
```

### Network Testing Between Labs

```bash
# SSH into Lab 1
vagrant ssh ad-lab-1

# Test connection to Lab 2
ping 192.168.56.12

# SSH to Lab 2 from Lab 1
ssh -i .vagrant/machines/ad-lab-2/virtualbox/private_key vagrant@192.168.56.12
```

---

## 📝 Scripts Reference

### create-individual-labs.sh
Creates Vagrant configuration for individual lab VMs:
- Master Vagrantfile (all 5 labs)
- Individual Vagrantfiles (one per lab)
- README.md with instructions

**Usage**:
```bash
./create-individual-labs.sh
```

### create-lab-vms.sh
Exports OVA files for each lab:
- lab-ad-lab-1.ova through lab-ad-lab-5.ova
- SHA256 checksums
- MANIFEST.md

**Usage**:
```bash
./create-lab-vms.sh
```

---

## 🎯 Best Practices

### Organization
- Keep each lab in separate directory
- Use consistent naming (ad-lab-1, ad-lab-2, etc.)
- Document which lab is which difficulty

### Resource Management
- Don't run all 5 labs simultaneously if low on RAM
- Stop labs when not in use
- Use snapshots before testing

### Backup Strategy
- Export OVAs before major changes
- Create checksums for integrity
- Keep backups in multiple locations

### Security
- Use strong credentials in VMs
- Isolate lab networks if needed
- Don't expose labs to internet

---

## 📚 Additional Resources

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [VulnLab Website](https://vulnlab.com)
- [Project Repository](https://github.com/netanelcyber/hackossem)

---

## ✅ Quick Checklist

- [ ] VirtualBox installed
- [ ] Vagrant installed
- [ ] Sufficient disk space (100GB+ for all labs)
- [ ] Sufficient RAM (10GB+ for all labs)
- [ ] Run `./create-individual-labs.sh`
- [ ] `cd lab-vms-vagrant && vagrant up`
- [ ] Access labs on ports 5001-5005
- [ ] Read lab documentation
- [ ] Start learning! 🎓

---

**Version**: 1.0  
**Last Updated**: 2026-08-06  
**Status**: ✅ Production Ready
