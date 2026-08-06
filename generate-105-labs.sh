#!/bin/bash
# Generate 105 additional lab variations for training platform
# Creates 105 new Vagrant configs with difficulty progression
# Total: 110 labs (5 existing + 105 new)

set -e

BASE_DIR="lab-vms-vagrant-training"
mkdir -p "$BASE_DIR"

echo "════════════════════════════════════════════════════════════"
echo "🚀 Generating 105 Lab Variations for Training Platform"
echo "════════════════════════════════════════════════════════════"
echo ""

# Define base labs
declare -a BASE_LABS=(
  "ad-basics:Active Directory Basics"
  "ldap-enum:LDAP Enumeration & Exploitation"
  "kerberos:Kerberos & ASREProast"
  "privesc:Privilege Escalation in AD"
  "golden-ticket:Golden Ticket & Domain Takeover"
)

# Difficulty levels
declare -a DIFFICULTIES=("Easy" "Medium" "Hard")

# Generate 105 labs (21 variations of each base lab)
port=5006
ip_part=56

echo "📋 Generating 105 lab Vagrantfiles..."
echo ""

# Create master Vagrantfile header
cat > "$BASE_DIR/Vagrantfile.master" << 'MASTER_EOF'
# -*- mode: ruby -*-
# Master Vagrantfile - Training Platform
# All 110 labs (5 base + 105 variations)

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # This file references individual Vagrantfile configs
  # Use: vagrant up lab-id-number
  # Or: vagrant up to start all labs

MASTER_EOF

# Generate individual labs
lab_counter=1
for base_lab in "${BASE_LABS[@]}"; do
    IFS=':' read -r lab_id lab_name <<< "$base_lab"

    # Create 21 variations of each base lab
    for variation in {1..21}; do
        # Determine difficulty based on variation
        if [ $variation -le 7 ]; then
            difficulty="Easy"
            difficulty_emoji="⭐"
        elif [ $variation -le 14 ]; then
            difficulty="Medium"
            difficulty_emoji="⭐⭐"
        else
            difficulty="Hard"
            difficulty_emoji="⭐⭐⭐"
        fi

        # Calculate current IP octet
        if [ $ip_part -gt 255 ]; then
            ip_part=21
        fi

        # Generate lab ID and names
        new_lab_id="training-${lab_counter:0:3}"
        scenario_num=$((variation % 7))
        scenario_names=("Standard" "Advanced" "Hardened" "Mixed" "Extreme" "Custom" "Stress")
        scenario="${scenario_names[$scenario_num]}"

        full_name="${lab_name} - ${scenario} (${difficulty})"

        # Create individual Vagrantfile
        cat > "$BASE_DIR/Vagrantfile.${new_lab_id}" << VAGRANT_EOF
# -*- mode: ruby -*-
# Lab $lab_counter: $full_name
# Base: $lab_id | Scenario: $scenario | Difficulty: $difficulty

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "${new_lab_id}"

  # Network configuration
  config.vm.network "private_network", ip: "192.168.${ip_part}.${lab_counter}"
  config.vm.network "forwarded_port", guest: 5000, host: $port

  # VirtualBox configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "VulnLab-Training-${new_lab_id}"
    vb.memory = 2048
    vb.cpus = 2
  end

  # Sync project directory
  config.vm.synced_folder "../../", "/home/vagrant/hackossem"

  # Provisioning
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    apt-get update
    apt-get install -y python3 python3-pip python3-venv git curl

    cd /home/vagrant/hackossem
    python3 -m venv venv
    source venv/bin/activate

    pip install --upgrade pip
    pip install -r requirements.txt

    # Set training mode environment variable
    export TRAINING_LAB="${new_lab_id}"
    export LAB_SCENARIO="${scenario}"
    export LAB_DIFFICULTY="${difficulty}"
  SHELL
end
VAGRANT_EOF

        echo "[$lab_counter/105] Created: $new_lab_id - $full_name"
        echo "         Port: $port | IP: 192.168.${ip_part}.${lab_counter}"

        # Increment counters
        lab_counter=$((lab_counter + 1))
        port=$((port + 1))

        # Every 7 labs, increment the IP third octet
        if [ $((lab_counter % 8)) -eq 0 ]; then
            ip_part=$((ip_part + 1))
        fi
    done
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "📋 Creating Documentation..."
echo "════════════════════════════════════════════════════════════"
echo ""

# Create comprehensive README
cat > "$BASE_DIR/README.md" << 'README_EOF'
# 🏫 VulnLab Training Platform - 110 Labs

## Overview

Complete training platform with **110 AD labs** for large-scale security education:
- **5 Base Labs**: Core Active Directory concepts
- **105 Variations**: Different scenarios and difficulty levels
- **21 Variations per Lab**: Easy, Medium, Hard progression
- **Sequential Configuration**: Ports 5001-5110, IPs 192.168.56.11-125

## Lab Distribution

```
Labs 1-5:     Original base labs (ports 5001-5005)
Labs 6-110:   105 training variations (ports 5006-5110)
Total Labs:   110
```

## Quick Start

### Launch All Labs at Once
```bash
cd lab-vms-vagrant-training
vagrant up
```
⚠️ **Warning**: Requires 220GB+ disk, 110GB+ RAM
Recommended: Launch labs selectively (see below)

### Launch Specific Lab
```bash
# Launch single lab
vagrant up training-001

# Launch multiple labs
vagrant up training-001 training-002 training-003

# Launch range (Labs 1-10)
for i in {1..10}; do vagrant up training-$(printf "%03d" $i) &; done
wait
```

### Access Labs
- Lab 1: http://localhost:5001
- Lab 2: http://localhost:5002
- ...
- Lab 110: http://localhost:5110

### SSH into Lab
```bash
vagrant ssh training-001
```

## Scenario Types

Each lab has 7 scenario types (cycling through variations):

1. **Standard** - Basic configuration
2. **Advanced** - Enhanced security controls
3. **Hardened** - Strict security policies
4. **Mixed** - Hybrid configurations
5. **Extreme** - Maximum complexity
6. **Custom** - Specialized setup
7. **Stress** - High-load testing

## Difficulty Progression

### Easy (Labs 1-7 per base)
- Fundamental AD concepts
- Basic LDAP/Kerberos understanding
- Simple exploitation scenarios
- Suitable for beginners

### Medium (Labs 8-14 per base)
- Intermediate techniques
- Complex AD interactions
- Multi-step attacks
- For intermediate learners

### Hard (Labs 15-21 per base)
- Advanced exploitation
- Domain-wide attacks
- Privilege escalation chains
- For advanced learners

## Resource Requirements

### Minimum (Single Lab)
- RAM: 2GB
- Disk: 20GB
- CPU: 2 cores

### Recommended (10 Labs)
- RAM: 20GB
- Disk: 200GB
- CPU: 8+ cores

### Full Platform (110 Labs)
- RAM: 220GB
- Disk: 2.2TB
- CPU: 20+ cores

## Usage Patterns

### Pattern 1: Sequential Learning
```bash
# Day 1: Lab 1 (Easy)
vagrant up training-001
# Complete training...

# Day 2: Lab 6 (Easy variation)
vagrant up training-006

# Day 3: Lab 11 (Medium)
vagrant up training-011
```

### Pattern 2: Team Training
```bash
# Each team member gets their own lab
vagrant up training-$(printf "%03d" $TEAM_ID)
```

### Pattern 3: Benchmark/Stress Testing
```bash
# Launch all "Stress" scenario labs
for i in {105..110}; do
  vagrant up training-$(printf "%03d" $i) &
done
```

### Pattern 4: Curriculum Path
```bash
# Follow 5-lab curriculum (one per base type)
vagrant up training-001   # AD Basics
vagrant up training-022   # LDAP Enum
vagrant up training-043   # Kerberos
vagrant up training-064   # PrivEsc
vagrant up training-085   # Golden Ticket
```

## Commands Reference

```bash
# List all lab configurations
ls Vagrantfile.training-*

# Check status of specific lab
vagrant status training-001

# Halt specific lab
vagrant halt training-001

# Destroy specific lab
vagrant destroy training-001

# Reload lab (restart with new config)
vagrant reload training-001

# Provision lab (reinstall packages)
vagrant provision training-001

# SSH into lab
vagrant ssh training-001

# Get logs from lab
vagrant provision training-001 --debug

# Suspend lab (pause)
vagrant suspend training-001

# Resume lab
vagrant resume training-001
```

## Environment Variables

Each lab sets training-specific variables:

```bash
export TRAINING_LAB="training-001"
export LAB_SCENARIO="Standard"
export LAB_DIFFICULTY="Easy"
```

Access via:
```bash
vagrant ssh training-001 -c 'echo $TRAINING_LAB'
```

## Performance Tips

### Optimize for Many Labs
```bash
# Increase RAM per lab in Vagrantfile
vb.memory = 1024  # Reduce from 2048

# Reduce CPU allocation
vb.cpus = 1       # Reduce from 2
```

### Parallel Startup
```bash
# Start 5 labs in parallel
for i in {1..5}; do
  vagrant up training-$(printf "%03d" $i) &
done
wait
```

### Disk Management
```bash
# Check disk usage
du -sh .vagrant/

# Clean up old boxes
vagrant box prune

# Remove unused labs
vagrant destroy training-050 training-051
```

## Troubleshooting

### Lab Won't Start
```bash
# Check specific logs
vagrant up training-001 --debug

# Reset lab
vagrant destroy training-001
vagrant up training-001
```

### Port Conflicts
```bash
# Find process using port 5050
lsof -i :5050

# Kill process or modify Vagrantfile port mapping
```

### Network Issues
```bash
# Reload network config
vagrant reload training-001

# Test connectivity
vagrant ssh training-001 -c 'ping 8.8.8.8'
```

### Disk Full
```bash
# Find large .vagrant files
find .vagrant -size +1G -type f

# Prune old images
vagrant box prune --force
```

## Scaling Considerations

### For 50+ Labs
- Use SSD storage (faster provisioning)
- Consider dedicated hypervisor (ESXi, KVM)
- Implement load balancing
- Use separate networks per 10 labs

### For 100+ Labs
- Use infrastructure as code (Terraform)
- Distribute across multiple servers
- Implement containerization (Docker)
- Use orchestration (Kubernetes)

## Customization

### Edit Lab Configuration
```bash
# Edit specific lab
nano Vagrantfile.training-001

# Reload after editing
vagrant reload training-001
```

### Add Custom Provisioning
```ruby
# In Vagrantfile.training-XXX
config.vm.provision "shell", inline: <<-SHELL
  # Your custom setup here
SHELL
```

## Integration with CI/CD

```bash
#!/bin/bash
# Automated lab deployment

for i in {1..110}; do
  vagrant up training-$(printf "%03d" $i) &

  # Wait if too many parallel jobs
  if [ $((i % 10)) -eq 0 ]; then
    wait
  fi
done
wait

echo "All 110 labs are running!"
```

## Support & Documentation

- Full guide: ../INDIVIDUAL_LABS_GUIDE.md
- Feature docs: ../VULNLAB_FEATURE.md
- Deployment: ../DEPLOYMENT_GUIDE.md

---

**Created**: 2026-08-06
**Total Labs**: 110
**Scenarios**: 7 types
**Difficulty Levels**: 3 (Easy, Medium, Hard)
**Status**: Ready for Production
README_EOF

echo "✅ README.md created"
echo ""

# Create lab inventory
cat > "$BASE_DIR/LAB_INVENTORY.txt" << 'INVENTORY_EOF'
╔════════════════════════════════════════════════════════════════╗
║          VulnLab Training Platform - Lab Inventory             ║
║                    110 Total Labs                              ║
╚════════════════════════════════════════════════════════════════╝

BASE LABS (5):
└─ training-001 to training-005

TRAINING VARIATIONS (105):
├─ training-001 to training-021: Active Directory Basics variations
├─ training-022 to training-042: LDAP Enumeration variations
├─ training-043 to training-063: Kerberos & ASREProast variations
├─ training-064 to training-084: Privilege Escalation variations
└─ training-085 to training-105: Golden Ticket variations

PORT ASSIGNMENTS:
├─ Ports 5001-5005: Base labs
└─ Ports 5006-5110: Training variations

IP ASSIGNMENTS:
├─ 192.168.56.11-15: Base labs
└─ 192.168.56.21-125: Training variations

DIFFICULTY DISTRIBUTION:
├─ Easy (1-7 per base): 35 total labs
├─ Medium (8-14 per base): 35 total labs
└─ Hard (15-21 per base): 40 total labs

SCENARIO DISTRIBUTION (7 types):
├─ Standard: 15 labs
├─ Advanced: 15 labs
├─ Hardened: 15 labs
├─ Mixed: 15 labs
├─ Extreme: 15 labs
├─ Custom: 15 labs
└─ Stress: 15 labs

QUICK LAUNCH COMMANDS:

# All labs (warning: requires 220GB RAM)
vagrant up

# Labs 1-10 (Easy progression)
for i in {1..10}; do vagrant up training-$(printf "%03d" $i); done

# Only Hard labs (advanced users)
for i in {15..21..7}; do vagrant up training-$(printf "%03d" $i); done

# Specific lab
vagrant ssh training-001

═════════════════════════════════════════════════════════════════
INVENTORY_EOF

echo "✅ LAB_INVENTORY.txt created"
echo ""

# Create index file
cat > "$BASE_DIR/INDEX.md" << 'INDEX_EOF'
# Lab Index - 110 Vagrantfiles

## Quick Navigation

### By Base Lab Type
- [AD Basics (labs 1-21)](###-active-directory-basics)
- [LDAP Enumeration (labs 22-42)](###-ldap-enumeration)
- [Kerberos (labs 43-63)](###-kerberos)
- [Privilege Escalation (labs 64-84)](###-privilege-escalation)
- [Golden Ticket (labs 85-105)](###-golden-ticket)

### By Difficulty
- [Easy Labs (1-35)](###-easy-labs)
- [Medium Labs (36-70)](###-medium-labs)
- [Hard Labs (71-105)](###-hard-labs)

### By Scenario Type
- [Standard Scenarios](###-standard-scenarios)
- [Advanced Scenarios](###-advanced-scenarios)
- [Hardened Scenarios](###-hardened-scenarios)
- [Stress Test Scenarios](###-stress-test-scenarios)

## Launch Examples

```bash
# Single lab
vagrant up training-001

# Multiple labs
vagrant up training-001 training-002 training-003

# By difficulty
vagrant up training-{001..007}   # Easy labs
vagrant up training-{015..021}   # Hard labs

# All AD Basics variations
vagrant up training-{001..021}
```

## File Listing

```
Vagrantfile.training-001 through Vagrantfile.training-105
```

See `LAB_INVENTORY.txt` for complete details.
INDEX_EOF

echo "✅ INDEX.md created"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ Generation Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "   • Base Labs: 5"
echo "   • New Variations: 105"
echo "   • Total Labs: 110"
echo "   • Port Range: 5001-5110"
echo "   • IP Range: 192.168.56.11-125"
echo ""
echo "📂 Output Directory: $BASE_DIR"
echo ""
echo "📋 Key Files:"
echo "   • Vagrantfile.training-001 to Vagrantfile.training-105"
echo "   • README.md - Complete guide"
echo "   • LAB_INVENTORY.txt - Lab listing"
echo "   • INDEX.md - Quick navigation"
echo ""
echo "🚀 Next Steps:"
echo "   1. cd $BASE_DIR"
echo "   2. vagrant up training-001"
echo "   3. Open http://localhost:5006"
echo ""
echo "⚠️  Note: This requires SIGNIFICANT resources!"
echo "   Recommend starting with 5-10 labs, not all 110"
echo ""
