# 💾 OVA/OVF Files Management with Git LFS

## Overview

Git LFS (Large File Storage) enables efficient storage and management of large virtual machine export files (OVA/OVF) without bloating the git repository.

**Key Benefits:**
- ✅ Store large VM files (8-10GB each) without repository bloat
- ✅ Efficient bandwidth usage - only download files you need
- ✅ Full version control history for VM exports
- ✅ Secure storage and sharing with team members
- ✅ Automatic integrity verification via checksums

---

## Setup (One-Time)

### 1. Install Git LFS

**Ubuntu/Debian:**
```bash
sudo apt-get install git-lfs
```

**macOS (Homebrew):**
```bash
brew install git-lfs
```

**Windows:**
- Download from: https://git-lfs.github.com/
- Or: `choco install git-lfs` (via Chocolatey)

### 2. Initialize LFS in Repository

```bash
git lfs install
# Output: Updated Git hooks.
#         Git LFS initialized.
```

This should already be done in this repository (see `.gitattributes`).

### 3. Verify Configuration

```bash
# Check git lfs is installed
git lfs version

# Check .gitattributes is configured
cat .gitattributes
```

---

## Workflow: Creating OVA Files Locally

### Prerequisites

- VirtualBox installed
- 50GB+ free disk space
- 20+ GB RAM
- Network connection (for pushing to GitHub)

### Step 1: Generate OVA Files

On your local machine with VirtualBox:

```bash
cd lab-vms-vagrant-training

# Make sure Vagrant VM is halted
vagrant halt

# Export individual labs as OVA files
./create-lab-vms.sh
```

This creates:
```
lab-vms/
├── lab-ad-lab-1.ova (8-10 GB)
├── lab-ad-lab-1.ova.sha256
├── lab-ad-lab-2.ova (8-10 GB)
├── lab-ad-lab-2.ova.sha256
├── ... (through lab-ad-lab-5.ova)
└── MANIFEST.md
```

### Step 2: Verify OVA Integrity

```bash
cd lab-vms

# Verify checksums
sha256sum -c *.sha256

# Output should show:
# lab-ad-lab-1.ova: OK
# lab-ad-lab-2.ova: OK
# ... etc
```

### Step 3: Stage Files for Git LFS

```bash
# Navigate to repo root
cd /path/to/hackossem

# Add OVA files (git lfs will automatically handle)
git add lab-vms/*.ova
git add lab-vms/*.sha256
git add lab-vms/MANIFEST.md

# Verify files are tracked by LFS
git lfs ls-files
```

Expected output:
```
lab-vms/lab-ad-lab-1.ova (pointer -> 9.2 GB)
lab-vms/lab-ad-lab-2.ova (pointer -> 8.8 GB)
lab-vms/lab-ad-lab-3.ova (pointer -> 9.1 GB)
lab-vms/lab-ad-lab-4.ova (pointer -> 8.9 GB)
lab-vms/lab-ad-lab-5.ova (pointer -> 9.0 GB)
lab-vms/lab-ad-lab-1.ova.sha256
lab-vms/lab-ad-lab-2.ova.sha256
... etc
```

### Step 4: Commit Files

```bash
git commit -m "Add OVA exports for all 5 AD labs via git-lfs

- 5 OVA files (~45 GB total)
- SHA256 checksums for integrity verification
- MANIFEST.md with import instructions
- Managed via git-lfs to avoid repository bloat

Files:
  - lab-ad-lab-1.ova (9.2 GB)
  - lab-ad-lab-2.ova (8.8 GB)
  - lab-ad-lab-3.ova (9.1 GB)
  - lab-ad-lab-4.ova (8.9 GB)
  - lab-ad-lab-5.ova (9.0 GB)

To use:
  git lfs pull
  cd lab-vms
  VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname \"AD-Lab-1\""
```

### Step 5: Push to GitHub

```bash
# Push commits and LFS files
git push -u origin your-branch-name

# Monitor progress (can take 10-30 minutes for 45GB)
# You'll see output like:
# Uploading LFS objects: 100% (5/5), 45 GB | 1.5 MB/s
```

---

## Workflow: Downloading OVA Files

### For Team Members

Once OVA files are pushed to GitHub:

```bash
# Clone repository (minimal download first)
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem

# Fetch LFS files (~45 GB)
git lfs pull

# Verify downloads
git lfs ls-files

# Verify integrity
cd lab-vms
sha256sum -c *.sha256
```

---

## Commands Reference

### Git LFS Management

```bash
# Initialize LFS for repository
git lfs install

# Track file types with LFS
git lfs track "*.ova"

# List tracked file types
cat .gitattributes

# Show LFS-tracked files
git lfs ls-files

# Show detailed LFS information
git lfs ls-files --long
git lfs ls-files --size

# Get information about LFS storage
git lfs env
```

### Working with OVA Files

```bash
# Pull all LFS files
git lfs pull

# Pull specific files
git lfs pull --include="lab-vms/*.ova"

# Fetch without checking out
git lfs fetch

# Check status of LFS files
git lfs status

# Migrate existing files to LFS
git lfs migrate import --include="*.ova"

# Prune local LFS cache
git lfs prune
```

### OVA File Operations

```bash
# Verify all OVA files
cd lab-vms
sha256sum -c *.sha256

# Check OVA file size
ls -lh *.ova

# Get OVA file statistics
du -sh *.ova

# Import OVA into VirtualBox
VBoxManage import lab-ad-lab-1.ova \
  --vsys 0 \
  --vmname "AD-Lab-1" \
  --description "VulnLab Active Directory Basics"

# Start imported VM
VBoxManage startvm "AD-Lab-1"
```

---

## Storage Information

### OVA File Sizes (Estimated)

```
lab-ad-lab-1.ova  ≈ 9.2 GB
lab-ad-lab-2.ova  ≈ 8.8 GB
lab-ad-lab-3.ova  ≈ 9.1 GB
lab-ad-lab-4.ova  ≈ 8.9 GB
lab-ad-lab-5.ova  ≈ 9.0 GB
────────────────────────────
Total             ≈ 45.0 GB
```

### Storage Considerations

**GitHub LFS Quotas:**
- Free tier: 1 GB storage, 1 GB bandwidth/month
- Pro tier: Unlimited storage, 100 GB bandwidth/month
- Enterprise: Custom

**Recommendation:**
- For 45 GB of OVA files, consider GitHub Enterprise
- Or use dedicated LFS server (GitLab, Gitea)
- Or use cloud storage (AWS S3, Azure Blob Storage)

### Bandwidth Optimization

```bash
# Clone only recent history (shallow clone)
git clone --depth=1 --single-branch https://github.com/netanelcyber/hackossem.git

# Fetch only specific LFS files
git lfs fetch --include="lab-ad-lab-1.ova"

# Prune old LFS objects
git lfs prune --verify-remote
```

---

## Troubleshooting

### "Git LFS not installed"

```bash
# Install git-lfs
sudo apt-get install git-lfs

# Initialize
git lfs install
```

### "File not tracked by LFS"

```bash
# Check if .gitattributes is configured
cat .gitattributes

# Verify file pattern
git lfs track "*.ova"

# Re-add file
git rm --cached lab-vms/lab-ad-lab-1.ova
git add lab-vms/lab-ad-lab-1.ova

# Check status
git lfs ls-files
```

### "LFS push fails (bandwidth exceeded)"

```bash
# Check usage
git lfs env

# Wait for quota reset
# Or upgrade GitHub plan
# Or use different LFS server
```

### "Cannot download OVA files"

```bash
# Check LFS server connectivity
git lfs version

# Re-authenticate
git config --global credential.helper store

# Retry pull
git lfs pull --verbose
```

### "OVA files are corrupt"

```bash
# Verify checksums
cd lab-vms
sha256sum -c *.sha256

# If failed, re-download
cd ..
git lfs pull --force

# Try again
cd lab-vms
sha256sum -c *.sha256
```

### "Disk space issues"

```bash
# Check LFS cache size
du -sh .git/lfs/

# Prune unused objects
git lfs prune

# Check available disk
df -h /

# Clean local repository
git gc --aggressive
```

---

## Best Practices

### For Developers

1. **Always verify checksums** before importing OVA files
2. **Pull OVA files selectively** - don't download all 45GB if you only need one lab
3. **Use shallow clones** for faster initial setup
4. **Prune LFS cache regularly** to save disk space

### For Repository Maintainers

1. **Keep .gitattributes updated** with new file types
2. **Monitor LFS storage usage** regularly
3. **Set up LFS server** if exceeding GitHub quotas
4. **Test OVA imports periodically** to ensure file integrity
5. **Document storage limits** for team members

### For CI/CD Pipelines

```bash
# In GitHub Actions, avoid large LFS downloads
- name: Checkout code
  uses: actions/checkout@v3
  with:
    lfs: false  # Don't pull LFS files in CI

# Only download if needed
- name: Download OVA files
  if: matrix.include-ova == true
  run: git lfs pull --include="lab-vms/*.ova"
```

---

## Alternative Solutions

### For Large Team Deployments

**Option 1: S3 + Pre-signed URLs**
```bash
# Store OVA files in AWS S3
# Generate pre-signed download URLs
# Link from repository README
```

**Option 2: Dedicated LFS Server**
```bash
# Use GitLab LFS or Gitea
# Self-hosted Git with LFS support
# Full control over storage
```

**Option 3: Docker Registry**
```bash
# Package OVA files in Docker images
# Push to Docker Hub or private registry
# More suitable for containerized deployments
```

**Option 4: Bittorrent Distribution**
```bash
# Create .torrent files for OVA exports
# Distribute via torrent protocol
# Efficient for large team distributions
```

---

## Reference Links

- [Git LFS Documentation](https://git-lfs.com/doc)
- [GitHub LFS Quotas](https://docs.github.com/en/billing/managing-billing-for-git-large-file-storage)
- [VirtualBox OVA Import](https://www.virtualbox.org/manual/ch01.html)
- [GitLab LFS](https://docs.gitlab.com/ee/topics/git/lfs/)

---

## Quick Command Summary

```bash
# Setup (one-time)
sudo apt-get install git-lfs
git lfs install

# Create OVA files locally
cd lab-vms-vagrant-training
./create-lab-vms.sh

# Verify integrity
cd lab-vms
sha256sum -c *.sha256

# Commit via LFS
cd ../..
git add lab-vms/*.ova lab-vms/*.sha256
git commit -m "Add OVA exports via git-lfs"
git push

# Download OVA files (on another machine)
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
git lfs pull
```

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Ready for Production
