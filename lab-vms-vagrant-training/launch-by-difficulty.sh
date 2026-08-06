#!/bin/bash
# הפעל מעבדות לפי דרגת קושי
# Launch labs by difficulty level

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_menu() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🎓 VulnLab Training Platform - הפעל לפי דרגת קושי"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "בחר דרגת קושי (Select difficulty level):"
    echo ""
    echo "  1️⃣  Easy     - 35 labs למתחילים (1-35)"
    echo "  2️⃣  Medium   - 35 labs לרמה בינונית (36-70)"
    echo "  3️⃣  Hard     - 35 labs לרמה מתקדמת (71-105)"
    echo "  4️⃣  Mixed    - בחר labs ממספר רמות"
    echo "  5️⃣  All      - הפעל את כל 110 labs"
    echo "  6️⃣  Info     - מידע על דרגות קושי"
    echo ""
    echo "  0️⃣  Exit     - יציאה"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
}

launch_easy() {
    echo "🟢 Launching Easy labs (1-35)..."
    echo ""
    echo "Options:"
    echo "  1. Launch all Easy labs"
    echo "  2. Launch specific lab"
    echo "  3. Launch range of labs"
    echo ""
    read -p "Choose (1-3): " choice

    case $choice in
        1)
            echo "Launching all Easy labs (training-1 to training-35)..."
            echo "Note: This requires ~70GB RAM for all 35 labs"
            echo "Recommended: Run 3-5 at a time"
            echo ""
            read -p "Continue? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                cd easy
                vagrant up
            fi
            ;;
        2)
            read -p "Enter lab number (1-35): " lab_num
            if [ "$lab_num" -ge 1 ] && [ "$lab_num" -le 35 ]; then
                cd easy
                vagrant up training-$(printf "%03d" $lab_num)
            else
                echo "❌ Invalid lab number"
            fi
            ;;
        3)
            read -p "Enter start lab (1-35): " start_lab
            read -p "Enter end lab (1-35): " end_lab
            if [ "$start_lab" -ge 1 ] && [ "$end_lab" -le 35 ] && [ "$start_lab" -le "$end_lab" ]; then
                cd easy
                for i in $(seq $start_lab $end_lab); do
                    vagrant up training-$(printf "%03d" $i) &
                done
                wait
            else
                echo "❌ Invalid range"
            fi
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

launch_medium() {
    echo "🟡 Launching Medium labs (36-70)..."
    echo ""
    echo "Options:"
    echo "  1. Launch all Medium labs"
    echo "  2. Launch specific lab"
    echo "  3. Launch range of labs"
    echo ""
    read -p "Choose (1-3): " choice

    case $choice in
        1)
            echo "Launching all Medium labs (training-36 to training-70)..."
            echo "Note: This requires ~70GB RAM for all 35 labs"
            echo "Recommended: Run 2-3 at a time (more resource-intensive)"
            echo ""
            read -p "Continue? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                cd medium
                vagrant up
            fi
            ;;
        2)
            read -p "Enter lab number (36-70): " lab_num
            if [ "$lab_num" -ge 36 ] && [ "$lab_num" -le 70 ]; then
                cd medium
                vagrant up training-$(printf "%03d" $lab_num)
            else
                echo "❌ Invalid lab number"
            fi
            ;;
        3)
            read -p "Enter start lab (36-70): " start_lab
            read -p "Enter end lab (36-70): " end_lab
            if [ "$start_lab" -ge 36 ] && [ "$end_lab" -le 70 ] && [ "$start_lab" -le "$end_lab" ]; then
                cd medium
                for i in $(seq $start_lab $end_lab); do
                    vagrant up training-$(printf "%03d" $i) &
                done
                wait
            else
                echo "❌ Invalid range"
            fi
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

launch_hard() {
    echo "🔴 Launching Hard labs (71-105)..."
    echo ""
    echo "Options:"
    echo "  1. Launch all Hard labs"
    echo "  2. Launch specific lab"
    echo "  3. Launch range of labs"
    echo ""
    read -p "Choose (1-3): " choice

    case $choice in
        1)
            echo "Launching all Hard labs (training-71 to training-105)..."
            echo "⚠️  WARNING: Most resource-intensive tier"
            echo "Note: This requires ~70GB RAM for all 35 labs"
            echo "Recommended: Run 1-2 at a time only"
            echo ""
            read -p "Continue? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                cd hard
                vagrant up
            fi
            ;;
        2)
            read -p "Enter lab number (71-105): " lab_num
            if [ "$lab_num" -ge 71 ] && [ "$lab_num" -le 105 ]; then
                cd hard
                vagrant up training-$(printf "%03d" $lab_num)
            else
                echo "❌ Invalid lab number"
            fi
            ;;
        3)
            read -p "Enter start lab (71-105): " start_lab
            read -p "Enter end lab (71-105): " end_lab
            if [ "$start_lab" -ge 71 ] && [ "$end_lab" -le 105 ] && [ "$start_lab" -le "$end_lab" ]; then
                cd hard
                for i in $(seq $start_lab $end_lab); do
                    vagrant up training-$(printf "%03d" $i) &
                done
                wait
            else
                echo "❌ Invalid range"
            fi
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

show_info() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "ℹ️  דרגות קושי - Difficulty Levels"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "🟢 EASY LABS (1-35)"
    echo "   • Target: Beginners"
    echo "   • Time: 30-45 min per lab"
    echo "   • Topics: AD basics, LDAP, Kerberos, PrivEsc, Golden Ticket"
    echo "   • Resource: 2GB RAM per lab"
    echo "   • Recommended: Start here"
    echo ""
    echo "🟡 MEDIUM LABS (36-70)"
    echo "   • Target: Intermediate professionals"
    echo "   • Time: 45-90 min per lab"
    echo "   • Topics: Complex AD, multi-step chains"
    echo "   • Resource: 2GB RAM per lab (more CPU intensive)"
    echo "   • Recommended: After Easy completion"
    echo ""
    echo "🔴 HARD LABS (71-105)"
    echo "   • Target: Advanced professionals"
    echo "   • Time: 90-180 min per lab"
    echo "   • Topics: Domain compromise, red team scenarios"
    echo "   • Resource: 2GB+ RAM per lab (most intensive)"
    echo "   • Recommended: For experts only"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "📊 Quick Stats:"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Easy:    35 labs (1-35)   - ~17-26 hours total"
    echo "Medium:  35 labs (36-70)  - ~26-52 hours total"
    echo "Hard:    35 labs (71-105) - ~52-105 hours total"
    echo ""
    echo "Total:  110 labs        - Recommended: 20+ hours"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-6): " choice

    case $choice in
        1)
            launch_easy
            ;;
        2)
            launch_medium
            ;;
        3)
            launch_hard
            ;;
        4)
            echo "Mixed launch - select labs from multiple difficulties"
            echo "Not implemented in this version"
            echo "Use manual commands: cd easy && vagrant up training-001"
            ;;
        5)
            echo "Launching ALL 110 labs..."
            echo "⚠️  CRITICAL WARNING ⚠️"
            echo "This will require:"
            echo "  • ~220GB RAM (unrealistic)"
            echo "  • ~2.2TB disk space"
            echo "  • 30-60 minutes to initialize"
            echo ""
            read -p "Are you SURE? (type 'yes' to confirm): " confirm
            if [ "$confirm" = "yes" ]; then
                vagrant up
            else
                echo "Cancelled"
            fi
            ;;
        6)
            show_info
            ;;
        0)
            echo "Goodbye! 👋"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
