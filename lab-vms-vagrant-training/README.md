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
