# 🎓 VulnLab Training Platform - Difficulty Level Guide

## עברית | English | العربية

---

## 📊 Lab Distribution by Difficulty

### Overview

```
┌─────────────────────────────────────────┐
│     VulnLab Training Platform (110)      │
├─────────────────────────────────────────┤
│ Easy (1-35)     → 35 Labs   ⭐          │
│ Medium (36-70)  → 35 Labs   ⭐⭐        │
│ Hard (71-105)   → 35 Labs   ⭐⭐⭐      │
└─────────────────────────────────────────┘
```

### Directory Structure

```
lab-vms-vagrant-training/
├── easy/              # 35 beginner labs (training-1 to training-35)
│   ├── Vagrantfile.training-1
│   ├── Vagrantfile.training-2
│   └── ... (through training-35)
│
├── medium/            # 35 intermediate labs (training-36 to training-70)
│   ├── Vagrantfile.training-36
│   ├── Vagrantfile.training-37
│   └── ... (through training-70)
│
├── hard/              # 35 advanced labs (training-71 to training-105)
│   ├── Vagrantfile.training-71
│   ├── Vagrantfile.training-72
│   └── ... (through training-105)
│
├── Vagrantfile.master
├── Vagrantfile.training-* (all 105)
├── README.md
├── INDEX.md
├── LAB_INVENTORY.txt
└── organize-by-difficulty.sh
```

---

## ⭐ Easy Labs (1-35)

### Target Audience
- Beginners to Active Directory
- First-time security learners
- Students starting cybersecurity education

### Learning Outcomes
- Basic AD concepts and architecture
- LDAP fundamentals
- Kerberos basics
- Simple privilege escalation paths
- Introduction to domain concepts

### Lab Breakdown

```
Labs 1-7:       Active Directory Basics (Easy)
Labs 8-14:      LDAP Enumeration (Easy)
Labs 15-21:     Kerberos & ASREProast (Easy)
Labs 22-28:     Privilege Escalation (Easy)
Labs 29-35:     Golden Ticket (Easy)
```

### Quick Start

**Launch all Easy labs:**
```bash
cd lab-vms-vagrant-training/easy
vagrant up
```

**Launch specific Easy lab:**
```bash
cd lab-vms-vagrant-training/easy
vagrant up training-001
```

**Launch multiple Easy labs in parallel:**
```bash
cd lab-vms-vagrant-training/easy
for i in {1..5}; do
  vagrant up training-$(printf "%03d" $i) &
done
wait
```

**Access Easy labs:**
```
Lab 1:  http://localhost:5001 (training-001)
Lab 2:  http://localhost:5002 (training-002)
...
Lab 35: http://localhost:5035 (training-035)
```

### Estimated Time
- Per lab: 30-45 minutes
- Full sequence (7 labs): 3.5-5 hours
- All 35 labs: 17-26 hours

---

## ⭐⭐ Medium Labs (36-70)

### Target Audience
- Intermediate security professionals
- Students with AD fundamentals
- Penetration testers starting AD testing
- Security engineers learning AD attacks

### Learning Outcomes
- Complex AD interactions
- Multi-step attack chains
- Intermediate privilege escalation
- LDAP/Kerberos exploitation techniques
- Active Directory vulnerabilities
- Domain compromise scenarios

### Lab Breakdown

```
Labs 36-42:     Active Directory Basics (Medium)
Labs 43-49:     LDAP Enumeration (Medium)
Labs 50-56:     Kerberos & ASREProast (Medium)
Labs 57-63:     Privilege Escalation (Medium)
Labs 64-70:     Golden Ticket (Medium)
```

### Quick Start

**Launch all Medium labs:**
```bash
cd lab-vms-vagrant-training/medium
vagrant up
```

**Launch specific Medium lab:**
```bash
cd lab-vms-vagrant-training/medium
vagrant up training-036
```

**Launch range of Medium labs (training-36 to training-40):**
```bash
cd lab-vms-vagrant-training/medium
for i in {36..40}; do
  vagrant up training-$(printf "%03d" $i) &
done
wait
```

**Access Medium labs:**
```
Lab 36: http://localhost:5036 (training-036)
Lab 37: http://localhost:5037 (training-037)
...
Lab 70: http://localhost:5070 (training-070)
```

### Estimated Time
- Per lab: 45-90 minutes
- Full sequence (7 labs): 5-10 hours
- All 35 labs: 26-52 hours

---

## ⭐⭐⭐ Hard Labs (71-105)

### Target Audience
- Advanced security professionals
- Red teamers
- Penetration testing professionals
- Active Directory specialists
- Security architects
- Threat researchers

### Learning Outcomes
- Domain-wide exploitation chains
- Advanced privilege escalation
- Complete domain compromise
- Lateral movement techniques
- Defense bypass strategies
- Active Directory architecture exploitation
- Real-world attack simulation

### Lab Breakdown

```
Labs 71-77:     Active Directory Basics (Hard)
Labs 78-84:     LDAP Enumeration (Hard)
Labs 85-91:     Kerberos & ASREProast (Hard)
Labs 92-98:     Privilege Escalation (Hard)
Labs 99-105:    Golden Ticket (Hard)
```

### Quick Start

**Launch all Hard labs:**
```bash
cd lab-vms-vagrant-training/hard
vagrant up
```

**Launch specific Hard lab:**
```bash
cd lab-vms-vagrant-training/hard
vagrant up training-071
```

**Launch range of Hard labs (training-71 to training-75):**
```bash
cd lab-vms-vagrant-training/hard
for i in {71..75}; do
  vagrant up training-$(printf "%03d" $i) &
done
wait
```

**Access Hard labs:**
```
Lab 71: http://localhost:5071 (training-071)
Lab 72: http://localhost:5072 (training-072)
...
Lab 105: http://localhost:5105 (training-105)
```

### Estimated Time
- Per lab: 90-180 minutes
- Full sequence (7 labs): 10-21 hours
- All 35 labs: 52-105 hours

---

## 🎯 Learning Paths

### Path 1: Foundation Builder (Beginner)
Perfect for someone starting with Active Directory

```
Week 1: Easy Labs (1-7) - AD Basics
Week 2: Easy Labs (8-14) - LDAP
Week 3: Easy Labs (15-21) - Kerberos
Week 4: Easy Labs (22-28) - PrivEsc
Week 5: Easy Labs (29-35) - Golden Ticket
```

**Time**: ~5 weeks, 17-26 hours total
**Goal**: Solid AD fundamentals

---

### Path 2: Intermediate Mastery (Mid-Level)
For security professionals with AD basics

```
Week 1: Medium Labs (36-42) - AD Basics Advanced
Week 2: Medium Labs (43-49) - LDAP Advanced
Week 3: Medium Labs (50-56) - Kerberos Advanced
Week 4: Medium Labs (57-63) - PrivEsc Advanced
Week 5: Medium Labs (64-70) - Golden Ticket Advanced
```

**Time**: ~5 weeks, 26-52 hours total
**Goal**: Master intermediate AD exploitation

---

### Path 3: Expert Red Teamer (Advanced)
For red teamers and AD specialists

```
Week 1: Hard Labs (71-77) - AD Basics Expert
Week 2: Hard Labs (78-84) - LDAP Expert
Week 3: Hard Labs (85-91) - Kerberos Expert
Week 4: Hard Labs (92-98) - PrivEsc Expert
Week 5: Hard Labs (99-105) - Golden Ticket Expert
```

**Time**: ~5 weeks, 52-105 hours total
**Goal**: Expert-level AD exploitation mastery

---

### Path 4: Fast Track (Mixed Difficulty)
For experienced security professionals

```
Day 1: Easy Lab 1-2 (Refresh basics)
Day 2: Medium Labs 36-37 (Intermediate)
Day 3: Medium Labs 50-51 (Kerberos deep dive)
Day 4: Hard Labs 71-72 (Domain compromise)
Day 5: Hard Labs 99-100 (Domain takeover)
```

**Time**: ~5 days
**Goal**: Rapid assessment and specific skill areas

---

### Path 5: Role-Based Focus

#### For LDAP Specialists
```
Easy:   Labs 8-14 (LDAP Basics)
Medium: Labs 43-49 (LDAP Advanced)
Hard:   Labs 78-84 (LDAP Expert)
```

#### For Kerberos Specialists
```
Easy:   Labs 15-21 (Kerberos Basics)
Medium: Labs 50-56 (Kerberos Advanced)
Hard:   Labs 85-91 (Kerberos Expert)
```

#### For Privilege Escalation Specialists
```
Easy:   Labs 22-28 (PrivEsc Basics)
Medium: Labs 57-63 (PrivEsc Advanced)
Hard:   Labs 92-98 (PrivEsc Expert)
```

#### For Domain Compromise Specialists
```
Easy:   Labs 29-35 (Golden Ticket Basics)
Medium: Labs 64-70 (Golden Ticket Advanced)
Hard:   Labs 99-105 (Golden Ticket Expert)
```

---

## 🔄 Switching Between Difficulty Levels

### From Easy to Medium

```bash
# Stop Easy labs
cd lab-vms-vagrant-training/easy
vagrant halt

# Start Medium labs
cd ../medium
vagrant up
```

### Progressive Learning

```bash
# Lab workflow: Easy → Medium → Hard

# Day 1-5: Easy
cd lab-vms-vagrant-training/easy
vagrant up training-001
# ... complete lab ...
vagrant halt training-001

# Day 6-10: Medium
cd ../medium
vagrant up training-036
# ... continue learning ...

# Day 11-15: Hard
cd ../hard
vagrant up training-071
# ... master the concepts ...
```

---

## 📊 Resource Requirements by Difficulty

### Easy Labs (35 labs)
- **Per Lab**: 2GB RAM, 2 CPUs, 20GB disk
- **Single Lab**: 2GB RAM
- **5 Labs**: 10GB RAM
- **All 35**: 70GB RAM (unrealistic)
- **Recommended**: Run 3-5 at a time

### Medium Labs (35 labs)
- **Per Lab**: 2GB RAM, 2 CPUs, 20GB disk
- **Single Lab**: 2GB RAM
- **5 Labs**: 10GB RAM
- **All 35**: 70GB RAM (unrealistic)
- **Recommended**: Run 2-3 at a time
- **Note**: More resource-intensive than Easy

### Hard Labs (35 labs)
- **Per Lab**: 2GB+ RAM, 2 CPUs, 20GB+ disk
- **Single Lab**: 2GB RAM
- **5 Labs**: 10GB RAM
- **All 35**: 70GB RAM (unrealistic)
- **Recommended**: Run 1-2 at a time
- **Note**: Most resource-intensive

---

## 🛠️ Advanced Usage

### List all labs in a difficulty level

**Easy:**
```bash
cd lab-vms-vagrant-training/easy
ls -la | grep Vagrantfile
```

**Medium:**
```bash
cd lab-vms-vagrant-training/medium
ls -la | grep Vagrantfile
```

**Hard:**
```bash
cd lab-vms-vagrant-training/hard
ls -la | grep Vagrantfile
```

### Check status of difficulty tier

**Easy:**
```bash
cd lab-vms-vagrant-training/easy
vagrant status
```

**Medium:**
```bash
cd lab-vms-vagrant-training/medium
vagrant status
```

**Hard:**
```bash
cd lab-vms-vagrant-training/hard
vagrant status
```

### Destroy all labs in a difficulty level

**Easy:**
```bash
cd lab-vms-vagrant-training/easy
vagrant destroy
```

### Create snapshot before attempting hard lab

```bash
cd lab-vms-vagrant-training/hard
vagrant up training-071
vagrant ssh training-071
# Inside VM:
sudo su -
# Might add more challenging changes
```

### Performance Optimization

For running multiple labs, reduce resources per lab:

```bash
# Edit Vagrantfile in easy/ directory
# Change:
# vb.memory = 2048  →  vb.memory = 1024
# vb.cpus = 2       →  vb.cpus = 1

# Then reload
vagrant reload
```

---

## 📈 Progress Tracking

### Completion Checklist

**Easy Labs** (35 total)
- [ ] AD Basics (1-7)
- [ ] LDAP (8-14)
- [ ] Kerberos (15-21)
- [ ] PrivEsc (22-28)
- [ ] Golden Ticket (29-35)

**Medium Labs** (35 total)
- [ ] AD Basics (36-42)
- [ ] LDAP (43-49)
- [ ] Kerberos (50-56)
- [ ] PrivEsc (57-63)
- [ ] Golden Ticket (64-70)

**Hard Labs** (35 total)
- [ ] AD Basics (71-77)
- [ ] LDAP (78-84)
- [ ] Kerberos (85-91)
- [ ] PrivEsc (92-98)
- [ ] Golden Ticket (99-105)

---

## 🎓 Study Tips

### Easy Labs
1. **Understand fundamentals** - Don't rush
2. **Read documentation** - Each lab has theory
3. **Take notes** - Concepts build on each other
4. **Complete all 7 variations** - Each scenario teaches something
5. **Repeat if needed** - Go through twice if concepts unclear

### Medium Labs
1. **Compare with Easy** - See how complexity increased
2. **Identify patterns** - Recognize attack chains
3. **Document techniques** - Build your playbook
4. **Focus on weaknesses** - Where did Easy labs fail?
5. **Study code** - Look at actual exploitation

### Hard Labs
1. **Combine techniques** - Mix multiple attack vectors
2. **Think like attacker** - Full compromise scenarios
3. **Build automation** - Create scripts for complex steps
4. **Threat modeling** - Understand attacker perspective
5. **Document findings** - Create detailed reports

---

## 🤝 Community & Support

### Need Help?

1. **Check logs**:
   ```bash
   vagrant ssh training-001
   sudo journalctl -n 50
   ```

2. **Review README**: See `README.md` for general info

3. **Check inventory**: See `LAB_INVENTORY.txt` for all labs

4. **Use INDEX**: See `INDEX.md` for quick navigation

---

## 📚 Quick Reference

| Level | Labs | Time | Difficulty | Target |
|-------|------|------|-----------|--------|
| Easy | 1-35 | 17-26h | ⭐ | Beginners |
| Medium | 36-70 | 26-52h | ⭐⭐ | Intermediate |
| Hard | 71-105 | 52-105h | ⭐⭐⭐ | Advanced |

---

**Version**: 2.0  
**Last Updated**: 2026-08-06  
**Status**: ✅ Production Ready
