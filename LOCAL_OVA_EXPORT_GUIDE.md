# 🏠 Local OVA Export Guide

## Important: OVA Export Requires VirtualBox

OVA (Open Virtual Appliance) export must be done **on your local machine** with VirtualBox installed. This cloud environment cannot export OVA files.

---

## Prerequisites (Local Machine Only)

- **VirtualBox 6.1+** - Download: https://www.virtualbox.org/wiki/Downloads
- **Vagrant 2.3+** - Download: https://www.vagrantup.com/downloads
- **Git LFS** - Install: `sudo apt-get install git-lfs` (Ubuntu/Debian)
- **50GB+ free disk space**
- **20+ GB RAM** (for running VMs during export)
- **Network connectivity** (for pushing to GitHub)

---

## Workflow: Export OVA Files Locally

### Step 1: Clone Repository

```bash
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
git checkout claude/vulnlab-list-ad-labs-pgchvl
```

### Step 2: Create Vagrant VMs

First, create the 5 base AD lab VMs using Vagrant:

```bash
cd lab-vms-vagrant

# Create all 5 lab VMs
vagrant up

# This creates:
# - ad-lab-1 (Active Directory Basics)
# - ad-lab-2 (LDAP Enumeration)
# - ad-lab-3 (Kerberos & ASREProast)
# - ad-lab-4 (Privilege Escalation)
# - ad-lab-5 (Golden Ticket & Domain Takeover)

# VMs are created and running with all provisioning complete
```

### Step 3: Verify VMs are Running

```bash
vagrant status

# Output should show:
# Current machine states:
# ad-lab-1          running (virtualbox)
# ad-lab-2          running (virtualbox)
# ad-lab-3          running (virtualbox)
# ad-lab-4          running (virtualbox)
# ad-lab-5          running (virtualbox)
```

### Step 4: Export OVA Files

```bash
# Return to repo root
cd ../..

# Run the OVA export script
./lab-vms/export-ova-via-lfs.sh
```

This script will:
1. ✅ Halt the Vagrant VMs
2. ✅ Export each VM as OVA file via VBoxManage
3. ✅ Generate SHA256 checksums
4. ✅ Create MANIFEST.md
5. ✅ Stage files in Git LFS
6. ✅ Create commit
7. ✅ Push to GitHub

### Step 5: Monitor Export Progress

The export process takes **30-60 minutes** for all 5 labs (~45 GB total):

```
[1/5] 📤 Exporting: Active Directory Basics (Easy)
     File: lab-vms/lab-ad-lab-1.ova
     ✅ Complete! Size: 9.2 GB

[2/5] 📤 Exporting: LDAP Enumeration & Exploitation (Medium)
     File: lab-vms/lab-ad-lab-2.ova
     ✅ Complete! Size: 8.8 GB

... (continuing for all 5 labs)

✅ Checksums verified
✅ Files staged in Git LFS
✅ Commit created
✅ Push successful!
```

### Step 6: Verify Success

```bash
# Check git log
git log --oneline | head -1
# Should show the OVA export commit

# Verify LFS tracking
git lfs ls-files
# Should show all OVA files with sizes
```

---

## Manual Export (If Script Fails)

If the automated script fails, export manually:

### 1. Halt VMs
```bash
cd lab-vms-vagrant
vagrant halt
cd ../..
```

### 2. Verify VirtualBox VMs
```bash
VBoxManage list vms
# Should see: "VulnLab-AD-Lab-1" {...}
```

### 3. Export Each Lab

```bash
# Lab 1
VBoxManage export "VulnLab-AD-Lab-1" \
  -o "lab-vms/lab-ad-lab-1.ova" \
  --vsys 0 \
  --product "VulnLab Active Directory Basics" \
  --vendor "VulnLab" \
  --version "1.0" \
  --description "VulnLab AD Lab 1"

# Lab 2
VBoxManage export "VulnLab-AD-Lab-2" \
  -o "lab-vms/lab-ad-lab-2.ova" \
  --vsys 0 \
  --product "VulnLab LDAP Enumeration" \
  --vendor "VulnLab" \
  --version "1.0" \
  --description "VulnLab AD Lab 2"

# ... repeat for labs 3, 4, 5
```

### 4. Generate Checksums

```bash
cd lab-vms
sha256sum *.ova > checksums.txt
sha256sum -c checksums.txt  # Verify

# Create individual checksums
for ova in lab-*.ova; do
  sha256sum "$ova" > "${ova}.sha256"
done

cd ..
```

### 5. Commit via Git LFS

```bash
# Ensure git lfs is installed
git lfs install

# Stage files
git add lab-vms/lab-*.ova
git add lab-vms/*.sha256
git add lab-vms/MANIFEST.md

# Verify LFS tracking
git lfs ls-files

# Commit
git commit -m "Add OVA exports for all 5 AD labs via Git LFS"

# Push (takes 10-30 minutes for 45GB)
git push -u origin claude/vulnlab-list-ad-labs-pgchvl
```

---

## Troubleshooting

### "VBoxManage: error: Could not find a registered machine"

**Cause**: VM doesn't exist or wasn't created by Vagrant

**Solution**:
```bash
# Make sure Vagrant VMs were created
cd lab-vms-vagrant
vagrant up

# Verify they exist
VBoxManage list vms | grep VulnLab

# Check their names - must match:
# "VulnLab-AD-Lab-1"
# "VulnLab-AD-Lab-2"
# etc.
```

### "Not enough disk space"

**Solution**:
- Need ~50GB free for 5 OVA files
- Check available space: `df -h /`
- Delete unused files or use different disk

### "Export takes too long"

**Normal behavior**:
- Each 10GB OVA takes 10-20 minutes
- Total for 5 labs: 30-60 minutes
- Let it complete - don't interrupt

### "Git LFS push fails (bandwidth exceeded)"

**Cause**: GitHub LFS quota exceeded

**Solutions**:
1. Wait for monthly quota reset
2. Upgrade GitHub plan (Pro or Enterprise)
3. Use alternative storage (GitLab, Gitea)
4. Try pushing later

### "OVA files are corrupt after export"

**Solution**:
```bash
cd lab-vms

# Verify checksums
sha256sum -c *.sha256

# If failed, re-export that lab
VBoxManage export "VulnLab-AD-Lab-X" -o "lab-ad-lab-X.ova" ...

# Generate new checksum
sha256sum "lab-ad-lab-X.ova" > "lab-ad-lab-X.ova.sha256"

# Verify again
sha256sum -c lab-ad-lab-X.ova.sha256
```

---

## Important Notes

### ⚠️ This is a Local-Only Process

```
┌─────────────────────────────────────────────────────┐
│  Cloud Environment (hackossem git repo)              │
│  ✅ Can pull code                                    │
│  ✅ Can modify code                                  │
│  ✅ Can push commits                                 │
│  ❌ Cannot export OVA (no VirtualBox)               │
└─────────────────────────────────────────────────────┘
                        ↕️ git push/pull
┌─────────────────────────────────────────────────────┐
│  Your Local Machine (with VirtualBox)                │
│  ✅ Can export OVA files                             │
│  ✅ Can verify checksums                             │
│  ✅ Can push OVA files via git-lfs                   │
└─────────────────────────────────────────────────────┘
```

### 📊 Typical Workflow Timeline

```
1. Clone repo (5 min)
2. vagrant up (create VMs) (15 min)
3. ./export-ova-via-lfs.sh (45-60 min)
   - Export lab 1 (12 min)
   - Export lab 2 (12 min)
   - Export lab 3 (12 min)
   - Export lab 4 (10 min)
   - Export lab 5 (10 min)
4. Generate checksums (2 min)
5. Push to GitHub (20-30 min for 45GB)

Total: ~2-2.5 hours
```

### 💾 Storage Requirements

```
Vagrant VMs (temporary, deleted after export): ~50 GB
OVA exports (kept): ~45 GB
Git repo clone: ~1 GB
Git LFS cache: ~45 GB (local copy)
────────────────────────────────
Total disk needed: ~141 GB
```

---

## For Team Members: Download OVA Files

Once OVA files are pushed to GitHub, teammates can download them:

```bash
# Clone repo (minimal download first)
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem

# Install git-lfs if needed
sudo apt-get install git-lfs

# Pull OVA files (~45 GB)
git lfs pull

# Verify integrity
cd lab-vms
sha256sum -c *.sha256

# Import into VirtualBox
VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname "AD-Lab-1"
VBoxManage import lab-ad-lab-2.ova --vsys 0 --vmname "AD-Lab-2"
# ... etc for all 5 labs
```

---

## Reference

- **OVA Export Guide**: See `OVA_GIT_LFS_GUIDE.md`
- **Git LFS Docs**: https://git-lfs.com/
- **VirtualBox Docs**: https://www.virtualbox.org/manual/
- **Vagrant Docs**: https://www.vagrantup.com/docs

---

**Version**: 1.0  
**Status**: ✅ Ready  
**Created**: 2026-08-06
