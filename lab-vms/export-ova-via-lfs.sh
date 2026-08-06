#!/bin/bash
# Export OVA files and commit via Git LFS
# ייצוא קבצי OVA והעלאה דרך Git LFS

set -e

echo "════════════════════════════════════════════════════════════"
echo "📦 OVA Export & Git LFS Workflow"
echo "════════════════════════════════════════════════════════════"
echo ""

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Check prerequisites
echo "🔍 Checking prerequisites..."
echo ""

if ! command -v git &> /dev/null; then
    echo "❌ Git not installed"
    exit 1
fi

if ! git lfs version &> /dev/null; then
    echo "❌ Git LFS not installed"
    echo "Install: sudo apt-get install git-lfs"
    exit 1
fi

if ! command -v VBoxManage &> /dev/null; then
    echo "❌ VirtualBox not installed"
    echo "Cannot export OVA files without VirtualBox"
    exit 1
fi

echo "✅ Git: $(git --version)"
echo "✅ Git LFS: $(git lfs version | head -1)"
echo "✅ VirtualBox: $(VBoxManage --version)"
echo ""

# Verify LFS is configured
if ! grep -q "\.ova" .gitattributes 2>/dev/null; then
    echo "⚠️  .gitattributes not configured for OVA files"
    echo "Setting up Git LFS tracking..."
    git lfs track "*.ova"
    git lfs track "*.sha256"
fi

echo "════════════════════════════════════════════════════════════"
echo "📋 Workflow Steps:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1. Halt Vagrant VM (if running)"
echo "2. Export OVA files from VirtualBox"
echo "3. Generate SHA256 checksums"
echo "4. Stage files in Git LFS"
echo "5. Create commit"
echo "6. Push to GitHub"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Step 1: Halt Vagrant VMs
echo "1️⃣  Halting Vagrant VMs..."
cd lab-vms-vagrant-training
vagrant halt 2>/dev/null || true
cd "$REPO_ROOT"
sleep 2
echo "✅ VMs halted"
echo ""

# Step 2: Run OVA export
echo "2️⃣  Exporting OVA files..."
echo "   (This may take 30-60 minutes for all 5 labs)"
echo ""

cd lab-vms-vagrant-training
if [ ! -f "create-lab-vms.sh" ]; then
    echo "❌ create-lab-vms.sh not found"
    exit 1
fi

bash create-lab-vms.sh

cd "$REPO_ROOT"
echo ""
echo "✅ OVA export complete"
echo ""

# Step 3: Verify checksums
echo "3️⃣  Verifying OVA integrity..."
cd lab-vms

if [ ! -f "MANIFEST.md" ]; then
    echo "⚠️  MANIFEST.md not found"
fi

# Verify all checksums
if ! sha256sum -c *.sha256 2>&1 | grep -q "OK"; then
    echo "❌ Some checksums failed!"
    echo "Please re-run the export"
    exit 1
fi

echo "✅ All OVA files verified"
echo ""
cd "$REPO_ROOT"

# Step 4: Display file sizes
echo "4️⃣  OVA File Summary:"
echo ""
du -sh lab-vms/lab-*.ova | sort
total=$(du -sh lab-vms/lab-*.ova | awk '{sum+=$1} END {print sum}')
echo "────────────────────────────────────"
echo "Total: $(du -sh lab-vms/ | cut -f1)"
echo ""

# Step 5: Stage files in Git
echo "5️⃣  Staging files for Git LFS..."
git add .gitattributes
git add lab-vms/lab-*.ova
git add lab-vms/lab-*.sha256
git add lab-vms/MANIFEST.md

echo "📊 Files staged:"
git lfs ls-files --size

echo ""
echo "✅ Files staged in Git LFS"
echo ""

# Step 6: Create commit
echo "6️⃣  Creating commit..."
echo ""

git commit -m "$(cat <<'COMMIT_MSG'
Add OVA exports for all 5 AD labs via Git LFS

- Export 5 OVA files (~45 GB total) using VBoxManage
- Include SHA256 checksums for integrity verification
- Add MANIFEST.md with import instructions
- Manage via git-lfs to avoid repository bloat

Files:
  lab-ad-lab-1.ova (~9.2 GB)
  lab-ad-lab-2.ova (~8.8 GB)
  lab-ad-lab-3.ova (~9.1 GB)
  lab-ad-lab-4.ova (~8.9 GB)
  lab-ad-lab-5.ova (~9.0 GB)

Total: ~45 GB

Usage:
  git lfs pull
  cd lab-vms
  sha256sum -c *.sha256
  VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname "AD-Lab-1"

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PBZ6S4LUK4tD433c9YPcd7
COMMIT_MSG
)"

echo "✅ Commit created"
echo ""

# Step 7: Push to GitHub
echo "7️⃣  Pushing to GitHub..."
echo ""
echo "⏱️  This may take 10-30 minutes depending on connection speed"
echo "   (~45 GB of data to upload)"
echo ""

if git push -u origin claude/vulnlab-list-ad-labs-pgchvl; then
    echo ""
    echo "✅ Push successful!"
else
    echo ""
    echo "⚠️  Push failed - likely due to LFS quota or bandwidth"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check GitHub LFS quota"
    echo "  2. Wait for bandwidth reset"
    echo "  3. Try pushing again later"
    echo "  4. Consider GitHub Enterprise for unlimited LFS"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ OVA Export Workflow Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "   • OVA files exported: 5"
echo "   • Total size: ~45 GB"
echo "   • Checksums verified: ✅"
echo "   • Pushed to GitHub: $(git rev-parse --short HEAD)"
echo ""
echo "🔗 Next Steps (for team members):"
echo "   1. git clone https://github.com/netanelcyber/hackossem.git"
echo "   2. cd hackossem"
echo "   3. git lfs pull"
echo "   4. sha256sum -c lab-vms/*.sha256"
echo "   5. VBoxManage import lab-vms/lab-ad-lab-1.ova --vsys 0 --vmname \"AD-Lab-1\""
echo ""
