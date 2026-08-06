#!/bin/bash
# יצירת VM נפרד לכל מעבדה של VulnLab AD
# Create separate VM for each VulnLab AD Lab

set -e

COLORS=(
  '\033[0;31m'  # Red
  '\033[0;32m'  # Green
  '\033[0;33m'  # Yellow
  '\033[0;34m'  # Blue
  '\033[0;35m'  # Purple
)
NC='\033[0m'    # No Color

# Define labs with colors
declare -a LABS=(
  "ad-lab-1|Active Directory Basics|Easy|2049"
  "ad-lab-2|LDAP Enumeration & Exploitation|Medium|2050"
  "ad-lab-3|Kerberos & ASREProast|Medium|2051"
  "ad-lab-4|Privilege Escalation in AD|Hard|2052"
  "ad-lab-5|Golden Ticket & Domain Takeover|Hard|2053"
)

OUTPUT_DIR="./lab-vms"
VAGRANT_DIR="./lab-vms-vagrant"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$VAGRANT_DIR"

echo "════════════════════════════════════════════════════════════"
echo "🚀 VulnLab AD Labs - יצירת VMs נפרדים"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create master Vagrantfile for all labs
cat > "$VAGRANT_DIR/Vagrantfile" << 'VAGRANT_EOF'
# -*- mode: ruby -*-
# VulnLab AD Labs - כל מעבדה ב-VM נפרד
# Master Vagrantfile for multiple lab VMs

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # Lab 1: Active Directory Basics
  config.vm.define "ad-lab-1" do |lab1|
    lab1.vm.hostname = "ad-lab-1"
    lab1.vm.network "private_network", ip: "192.168.56.11"
    lab1.vm.network "forwarded_port", guest: 5000, host: 5001
    lab1.vm.provider "virtualbox" do |vb|
      vb.name = "VulnLab-AD-Lab-1"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  # Lab 2: LDAP Enumeration
  config.vm.define "ad-lab-2" do |lab2|
    lab2.vm.hostname = "ad-lab-2"
    lab2.vm.network "private_network", ip: "192.168.56.12"
    lab2.vm.network "forwarded_port", guest: 5000, host: 5002
    lab2.vm.provider "virtualbox" do |vb|
      vb.name = "VulnLab-AD-Lab-2"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  # Lab 3: Kerberos
  config.vm.define "ad-lab-3" do |lab3|
    lab3.vm.hostname = "ad-lab-3"
    lab3.vm.network "private_network", ip: "192.168.56.13"
    lab3.vm.network "forwarded_port", guest: 5000, host: 5003
    lab3.vm.provider "virtualbox" do |vb|
      vb.name = "VulnLab-AD-Lab-3"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  # Lab 4: Privilege Escalation
  config.vm.define "ad-lab-4" do |lab4|
    lab4.vm.hostname = "ad-lab-4"
    lab4.vm.network "private_network", ip: "192.168.56.14"
    lab4.vm.network "forwarded_port", guest: 5000, host: 5004
    lab4.vm.provider "virtualbox" do |vb|
      vb.name = "VulnLab-AD-Lab-4"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  # Lab 5: Golden Ticket
  config.vm.define "ad-lab-5" do |lab5|
    lab5.vm.hostname = "ad-lab-5"
    lab5.vm.network "private_network", ip: "192.168.56.15"
    lab5.vm.network "forwarded_port", guest: 5000, host: 5005
    lab5.vm.provider "virtualbox" do |vb|
      vb.name = "VulnLab-AD-Lab-5"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  # Provisioning for all labs
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    apt-get update
    apt-get install -y python3 python3-pip python3-venv git curl
    cd /home/vagrant/hackossem
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
  SHELL
end
VAGRANT_EOF

echo "✅ Master Vagrantfile נוצר"
echo ""

# Create individual Vagrant configs
for lab in "${LABS[@]}"; do
    IFS='|' read -r id name difficulty port <<< "$lab"

    cat > "$VAGRANT_DIR/Vagrantfile.$id" << VAGRANT_SINGLE
# -*- mode: ruby -*-
# $name ($difficulty)

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "$id"

  config.vm.network "private_network", ip: "192.168.56.$((${port: -2}))"
  config.vm.network "forwarded_port", guest: 5000, host: $port

  config.vm.provider "virtualbox" do |vb|
    vb.name = "VulnLab-$id"
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.synced_folder "../", "/home/vagrant/hackossem"

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    apt-get update
    apt-get install -y python3 python3-pip python3-venv git
    cd /home/vagrant/hackossem
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
  SHELL
end
VAGRANT_SINGLE

    echo "✅ Vagrantfile.$id נוצר"
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "📋 מעבדות:"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create README
cat > "$VAGRANT_DIR/README.md" << 'README_EOF'
# 🏫 VulnLab AD Labs - Multi-VM Setup

## יצירת כל מעבדה ב-VM נפרד

### אפשרות 1: הפעל את כל ה-VMs (מומלץ)

```bash
cd lab-vms-vagrant
vagrant up
```

זה יהיה:
- יוצר 5 VMs בו-זמנית
- מחבר כל אחד לפורט שונה
- מתקין את כל התלויות

### אפשרות 2: הפעל מעבדה ספציפית

```bash
cd lab-vms-vagrant
vagrant up ad-lab-1
```

### גישה למעבדות

| Lab | Name | Port | IP |
|-----|------|------|-------|
| Lab 1 | Active Directory Basics | 5001 | 192.168.56.11 |
| Lab 2 | LDAP Enumeration | 5002 | 192.168.56.12 |
| Lab 3 | Kerberos & ASREProast | 5003 | 192.168.56.13 |
| Lab 4 | Privilege Escalation | 5004 | 192.168.56.14 |
| Lab 5 | Golden Ticket | 5005 | 192.168.56.15 |

גשת לאתר: http://localhost:5001 (עבור Lab 1)

### פקודות שימושיות

```bash
# הפעל Lab ספציפי
vagrant up ad-lab-1

# SSH לתוך Lab
vagrant ssh ad-lab-1

# עצור Lab
vagrant halt ad-lab-1

# מחק Lab
vagrant destroy ad-lab-1

# בדוק סטטוס
vagrant status
```

### דרישות

- VirtualBox
- Vagrant
- 10GB RAM (2GB לכל Lab)
- 100GB דיסק

### ייצוא לקבצי OVA

```bash
# עצור את ה-VMs
vagrant halt

# ייצא
VBoxManage export "VulnLab-ad-lab-1" -o lab-ad-lab-1.ova
```

README_EOF

echo "📋 תיקיות ה-Vagrant:"
echo ""

counter=1
for lab in "${LABS[@]}"; do
    IFS='|' read -r id name difficulty port <<< "$lab"
    color=${COLORS[$((counter-1))]}
    echo -e "${color}[$counter]${NC} $name"
    echo "     Port: $port | IP: 192.168.56.$((port % 256))"
    echo "     פקודה: vagrant up $id"
    echo ""
    counter=$((counter+1))
done

echo "════════════════════════════════════════════════════════════"
echo "📁 מבנה תיקיות:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "lab-vms-vagrant/"
echo "├── Vagrantfile (הפעל את כל ה-VMs)"
echo "├── Vagrantfile.ad-lab-1"
echo "├── Vagrantfile.ad-lab-2"
echo "├── Vagrantfile.ad-lab-3"
echo "├── Vagrantfile.ad-lab-4"
echo "├── Vagrantfile.ad-lab-5"
echo "└── README.md (הוראות)"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "🚀 הצעדים הבאים:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  עבור לתיקיית ה-Vagrant:"
echo "    cd lab-vms-vagrant"
echo ""
echo "2️⃣  הפעל את כל ה-VMs:"
echo "    vagrant up"
echo ""
echo "    או Lab ספציפי:"
echo "    vagrant up ad-lab-1"
echo ""
echo "3️⃣  גשת לאתר:"
echo "    http://localhost:5001  (Lab 1)"
echo "    http://localhost:5002  (Lab 2)"
echo "    ... וכו'"
echo ""
echo "✅ הכנת ה-VMs הושלמה!"
echo ""
