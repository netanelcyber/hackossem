#!/bin/bash
# ארגון מעבדות לפי דרגת קושי
# Organize labs by difficulty level

set -e

echo "════════════════════════════════════════════════════════════"
echo "📊 ארגון מעבדות לפי דרגת קושי"
echo "════════════════════════════════════════════════════════════"
echo ""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

# Create directories if they don't exist
mkdir -p easy medium hard

echo "🔗 יצירת סימולינקים (Creating symbolic links)..."
echo ""

# Easy Labs: 1-35 (7 per base lab × 5 base labs)
# Labs 1-7: AD Basics Easy
# Labs 8-14: LDAP Easy
# Labs 15-21: Kerberos Easy
# Labs 22-28: PrivEsc Easy
# Labs 29-35: Golden Ticket Easy

for i in {1..35}; do
    if [ -f "Vagrantfile.training-$i" ]; then
        ln -sf "../Vagrantfile.training-$i" "easy/Vagrantfile.training-$i" 2>/dev/null || true
    fi
done
echo "✅ Easy labs (1-35): 35 labs"

# Medium Labs: 36-70 (7 per base lab × 5 base labs)
# Labs 36-42: AD Basics Medium
# Labs 43-49: LDAP Medium
# Labs 50-56: Kerberos Medium
# Labs 57-63: PrivEsc Medium
# Labs 64-70: Golden Ticket Medium

for i in {36..70}; do
    if [ -f "Vagrantfile.training-$i" ]; then
        ln -sf "../Vagrantfile.training-$i" "medium/Vagrantfile.training-$i" 2>/dev/null || true
    fi
done
echo "✅ Medium labs (36-70): 35 labs"

# Hard Labs: 71-105 (7 per base lab × 5 base labs)
# Labs 71-77: AD Basics Hard
# Labs 78-84: LDAP Hard
# Labs 85-91: Kerberos Hard
# Labs 92-98: PrivEsc Hard
# Labs 99-105: Golden Ticket Hard

for i in {71..105}; do
    if [ -f "Vagrantfile.training-$i" ]; then
        ln -sf "../Vagrantfile.training-$i" "hard/Vagrantfile.training-$i" 2>/dev/null || true
    fi
done
echo "✅ Hard labs (71-105): 35 labs"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "📁 מבנה הדיוקים (Directory Structure)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "easy/          - 35 labs למתחילים (Beginner labs)"
echo "├── training-1 to training-35"
echo ""
echo "medium/        - 35 labs לרמה בינונית (Intermediate labs)"
echo "├── training-36 to training-70"
echo ""
echo "hard/          - 35 labs לרמה מתקדמת (Advanced labs)"
echo "├── training-71 to training-105"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "🚀 דוגמאות שימוש (Usage Examples)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  הפעל את כל ה-Easy labs:"
echo "    cd easy && vagrant up"
echo ""
echo "2️⃣  הפעל lab ספציפי (Easy):"
echo "    cd easy && vagrant up training-001"
echo ""
echo "3️⃣  הפעל טווח labs (Medium 36-40):"
echo "    cd medium && for i in {36..40}; do vagrant up training-\$i &; done; wait"
echo ""
echo "4️⃣  ראה את כל ה-Hard labs:"
echo "    ls -la hard/"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ ארגון הושלם!"
echo "════════════════════════════════════════════════════════════"
echo ""
