#!/bin/bash
# Script to create separate OVA files for each VulnLab AD Lab
# יצירת קובץ OVA נפרד לכל מעבדה

set -e

echo "════════════════════════════════════════════════════════════"
echo "📚 VulnLab AD Labs - יצירת קבצי OVA נפרדים"
echo "════════════════════════════════════════════════════════════"
echo ""

# Define labs
declare -a LABS=(
  "ad-lab-1:Active Directory Basics:Easy"
  "ad-lab-2:LDAP Enumeration & Exploitation:Medium"
  "ad-lab-3:Kerberos & ASREProast:Medium"
  "ad-lab-4:Privilege Escalation in AD:Hard"
  "ad-lab-5:Golden Ticket & Domain Takeover:Hard"
)

# Create output directory
OUTPUT_DIR="./lab-vms"
mkdir -p "$OUTPUT_DIR"

echo "📁 תיקיית פלט: $OUTPUT_DIR"
echo ""

# Check if VirtualBox is available
if ! command -v VBoxManage &> /dev/null; then
    echo "❌ VirtualBox לא מותקן!"
    exit 1
fi

echo "════════════════════════════════════════════════════════════"
echo "📋 רשימת המעבדות:"
echo "════════════════════════════════════════════════════════════"
echo ""

for lab in "${LABS[@]}"; do
    IFS=':' read -r id name difficulty <<< "$lab"
    echo "🔹 $name ($difficulty)"
    echo "   ID: $id"
    echo ""
done

echo "════════════════════════════════════════════════════════════"
echo "⚙️  הכנה לייצוא..."
echo "════════════════════════════════════════════════════════════"
echo ""

# Stop the main VM if running
echo "🛑 עצירת ה-VM הראשי (אם פועל)..."
vagrant halt 2>/dev/null || true
VBoxManage controlvm "VulnLab-Hackossem" poweroff 2>/dev/null || true

sleep 2

echo "✅ ה-VM עוצר."
echo ""

echo "════════════════════════════════════════════════════════════"
echo "📦 ייצוא קבצי OVA"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create manifest file
MANIFEST="$OUTPUT_DIR/MANIFEST.md"
cat > "$MANIFEST" << 'MANIFEST_EOF'
# 📚 VulnLab AD Labs - Manifest

## זהו אחסן קבצי OVA עבור כל מעבדה

### דרישות מערכת:
- VirtualBox 6.1+
- 2GB RAM למעבדה
- 20GB מקום פנוי

### הוראות ייבוא:

#### דרך שורת הפקודה:
```bash
VBoxManage import lab-ad-lab-1.ova --vsys 0 --vmname "AD-Lab-1"
VBoxManage startvm "AD-Lab-1"
```

#### דרך VirtualBox GUI:
1. File → Import Appliance
2. בחר את קובץ ה-OVA
3. לחץ Import
4. הפעל את ה-VM

---

## 📖 רשימת מעבדות:

MANIFEST_EOF

# Export each lab
counter=1
for lab in "${LABS[@]}"; do
    IFS=':' read -r id name difficulty <<< "$lab"

    ova_file="$OUTPUT_DIR/lab-${id}.ova"
    log_file="$OUTPUT_DIR/lab-${id}.log"

    echo "[$counter/${#LABS[@]}] 📤 ייצוא: $name ($difficulty)"
    echo "     קובץ: $ova_file"

    # Export with metadata
    {
        VBoxManage export "VulnLab-Hackossem" \
            -o "$ova_file" \
            --vsys 0 \
            --product "VulnLab $name" \
            --producturl "https://vulnlab.com" \
            --vendor "VulnLab" \
            --vendorurl "https://vulnlab.com" \
            --version "1.0" \
            --description "VulnLab AD Lab: $name (Difficulty: $difficulty)" \
            --eula "https://vulnlab.com/terms"
    } > "$log_file" 2>&1

    if [ -f "$ova_file" ]; then
        size=$(du -h "$ova_file" | cut -f1)
        echo "     ✅ הושלם! גודל: $size"

        # Add to manifest
        echo "" >> "$MANIFEST"
        echo "### $counter. $name" >> "$MANIFEST"
        echo "- **ID**: $id" >> "$MANIFEST"
        echo "- **Difficulty**: $difficulty" >> "$MANIFEST"
        echo "- **File**: \`lab-${id}.ova\`" >> "$MANIFEST"
        echo "- **Size**: $size" >> "$MANIFEST"
        echo "- **Import**: \`VBoxManage import lab-${id}.ova --vsys 0 --vmname \"AD-Lab-$counter\"\`" >> "$MANIFEST"
    else
        echo "     ❌ שגיאה בייצוא!"
    fi

    echo ""
    counter=$((counter + 1))
done

echo "════════════════════════════════════════════════════════════"
echo "✅ יצירת Checksum"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create checksums
cd "$OUTPUT_DIR"
for ova_file in lab-*.ova; do
    if [ -f "$ova_file" ]; then
        echo "🔐 checksum ל-$ova_file..."
        sha256sum "$ova_file" > "${ova_file}.sha256"
    fi
done
cd ..

echo "✅ Checksums נוצרו"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "📊 סיכום"
echo "════════════════════════════════════════════════════════════"
echo ""

# Print summary
total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)
ova_count=$(ls -1 "$OUTPUT_DIR"/lab-*.ova 2>/dev/null | wc -l)

echo "📁 תיקיה: $OUTPUT_DIR"
echo "📦 קבצי OVA: $ova_count"
echo "💾 גודל כולל: $total_size"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "📋 קבצים שנוצרו:"
echo "════════════════════════════════════════════════════════════"
echo ""

ls -lh "$OUTPUT_DIR"/

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 הצעדים הבאים:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  ייבא מעבדה:"
echo "   VBoxManage import $OUTPUT_DIR/lab-ad-lab-1.ova --vsys 0 --vmname \"AD-Lab-1\""
echo ""
echo "2️⃣  הפעל את המעבדה:"
echo "   VBoxManage startvm \"AD-Lab-1\""
echo ""
echo "3️⃣  גשת לאתר:"
echo "   http://localhost:5000"
echo ""
echo "4️⃣  ראה את הדוקומנטציה:"
echo "   cat $MANIFEST"
echo ""
echo "✅ יצירת קבצי OVA הושלמה!"
echo ""
