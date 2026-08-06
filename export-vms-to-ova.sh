#!/bin/bash
# Export VirtualBox VMs to OVA/OVF format
# ייצוא VMs ל-OVA/OVF

set -e

echo "════════════════════════════════════════════════════════════"
echo "📦 Export VirtualBox VMs to OVA/OVF Format"
echo "════════════════════════════════════════════════════════════"
echo ""

# Configuration
OUTPUT_DIR="./lab-vms"
EXPORT_FORMAT="ova"  # or "ovf"

mkdir -p "$OUTPUT_DIR"

# Check prerequisites
echo "🔍 Checking prerequisites..."
echo ""

if ! command -v VBoxManage &> /dev/null; then
    echo "❌ VirtualBox not installed!"
    exit 1
fi

if ! git lfs version &> /dev/null; then
    echo "⚠️  Git LFS not installed"
    echo "Some features will not work"
    echo "Install: sudo apt-get install git-lfs"
fi

echo "✅ VBoxManage: $(VBoxManage --version)"
echo "✅ Output directory: $OUTPUT_DIR"
echo ""

# Define labs
declare -a LABS=(
  "ad-lab-1:Active Directory Basics"
  "ad-lab-2:LDAP Enumeration & Exploitation"
  "ad-lab-3:Kerberos & ASREProast"
  "ad-lab-4:Privilege Escalation in AD"
  "ad-lab-5:Golden Ticket & Domain Takeover"
)

echo "════════════════════════════════════════════════════════════"
echo "📋 Labs to Export:"
echo "════════════════════════════════════════════════════════════"
echo ""

for lab in "${LABS[@]}"; do
    IFS=':' read -r id name <<< "$lab"
    echo "🔹 $name"
    echo "   VM: VulnLab-$id"
    echo ""
done

echo "════════════════════════════════════════════════════════════"
echo "⚙️  Export Settings:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Format: $EXPORT_FORMAT"
echo "Output directory: $OUTPUT_DIR"
echo ""

read -p "Continue with export? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "⚠️  Pre-Export Steps:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Shutting down all VMs..."
echo ""

for lab in "${LABS[@]}"; do
    IFS=':' read -r id name <<< "$lab"
    vm_name="VulnLab-$id"

    if VBoxManage list runningvms | grep -q "\"$vm_name\""; then
        echo "   Shutting down $vm_name..."
        VBoxManage controlvm "$vm_name" poweroff 2>/dev/null || true
    fi
done

sleep 3

echo "✅ All VMs stopped"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "📦 Exporting VMs..."
echo "════════════════════════════════════════════════════════════"
echo ""

counter=1
for lab in "${LABS[@]}"; do
    IFS=':' read -r id name <<< "$lab"
    vm_name="VulnLab-$id"
    export_file="$OUTPUT_DIR/lab-${id}.${EXPORT_FORMAT}"
    log_file="$OUTPUT_DIR/lab-${id}-export.log"

    echo "[$counter/5] 📤 Exporting: $name"
    echo "    VM: $vm_name"
    echo "    Format: $EXPORT_FORMAT"
    echo "    File: $export_file"
    echo ""

    # Check if VM exists
    if ! VBoxManage list vms | grep -q "\"$vm_name\""; then
        echo "    ❌ VM not found: $vm_name"
        echo ""
        counter=$((counter + 1))
        continue
    fi

    # Export VM
    {
        echo "Starting export at $(date)"
        VBoxManage export "$vm_name" \
            -o "$export_file" \
            --vsys 0 \
            --product "VulnLab $name" \
            --producturl "https://vulnlab.com" \
            --vendor "VulnLab" \
            --vendorurl "https://vulnlab.com" \
            --version "1.0" \
            --description "VulnLab AD Lab: $name" 2>&1
        echo "Export completed at $(date)"
    } | tee "$log_file"

    if [ -f "$export_file" ]; then
        size=$(du -h "$export_file" | cut -f1)
        echo ""
        echo "    ✅ Export complete!"
        echo "    Size: $size"
        echo "    Log: $log_file"
    else
        echo ""
        echo "    ❌ Export failed!"
        echo "    Check log: $log_file"
    fi

    echo ""
    counter=$((counter + 1))
done

echo "════════════════════════════════════════════════════════════"
echo "🔐 Generating SHA256 Checksums..."
echo "════════════════════════════════════════════════════════════"
echo ""

cd "$OUTPUT_DIR"

for export_file in lab-*.${EXPORT_FORMAT}; do
    if [ -f "$export_file" ]; then
        echo "Generating checksum for $export_file..."
        sha256sum "$export_file" > "${export_file}.sha256"
    fi
done

echo "✅ Checksums generated"
echo ""
cd ..

echo "════════════════════════════════════════════════════════════"
echo "📊 Export Summary"
echo "════════════════════════════════════════════════════════════"
echo ""

# List exported files
echo "Files created:"
ls -lh "$OUTPUT_DIR"/lab-*.${EXPORT_FORMAT} 2>/dev/null || echo "   (None)"

echo ""
echo "Checksums:"
ls -lh "$OUTPUT_DIR"/lab-*.sha256 2>/dev/null || echo "   (None)"

echo ""
echo "Total size:"
du -sh "$OUTPUT_DIR" 2>/dev/null || echo "   (Unknown)"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Post-Export Steps:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Verify checksums:"
echo "    cd $OUTPUT_DIR"
echo "    sha256sum -c *.sha256"
echo ""
echo "2️⃣  Commit to Git LFS (if configured):"
echo "    git add $OUTPUT_DIR/lab-*.${EXPORT_FORMAT}"
echo "    git add $OUTPUT_DIR/lab-*.sha256"
echo "    git commit -m 'Export OVA files for all labs'"
echo "    git push"
echo ""
echo "3️⃣  Share exported files:"
echo "    - Via Git LFS: git lfs pull (for team members)"
echo "    - Via S3/Cloud storage"
echo "    - Via torrent for large distributions"
echo ""
echo "4️⃣  Import in another system:"
echo "    VBoxManage import $OUTPUT_DIR/lab-ad-lab-1.${EXPORT_FORMAT} \\"
echo "      --vsys 0 --vmname \"Imported-Lab-1\""
echo "    VBoxManage startvm \"Imported-Lab-1\""
echo ""
echo "════════════════════════════════════════════════════════════"
echo "📝 Notes:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "• Each OVA file is 8-10 GB"
echo "• Total size ~45 GB for all 5 labs"
echo "• Checksums ensure file integrity"
echo "• Export time: 30-60 minutes total"
echo "• Network bandwidth: Check before uploading"
echo ""
echo "✅ Export workflow complete!"
echo ""
