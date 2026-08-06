# ⚡ Quick Start - Labs by Difficulty

## 🚀 5-Minute Setup

### Step 1: Navigate to training directory
```bash
cd lab-vms-vagrant-training
```

### Step 2: Choose your difficulty level

#### 🟢 For Beginners - Easy Labs (1-35)
```bash
cd easy
vagrant up training-001
# Access: http://localhost:5001
```

#### 🟡 For Intermediate - Medium Labs (36-70)
```bash
cd medium
vagrant up training-036
# Access: http://localhost:5036
```

#### 🔴 For Advanced - Hard Labs (71-105)
```bash
cd hard
vagrant up training-071
# Access: http://localhost:5071
```

---

## 📋 Directory Layout

```
lab-vms-vagrant-training/
├── easy/          ← 35 Beginner labs (1-35)
├── medium/        ← 35 Intermediate labs (36-70)
├── hard/          ← 35 Advanced labs (71-105)
│
├── launch-by-difficulty.sh    ← Interactive launcher
├── organize-by-difficulty.sh  ← Organization script
├── DIFFICULTY_GUIDE.md        ← Complete guide
├── QUICKSTART_BY_DIFFICULTY.md← This file
└── README.md
```

---

## 🎯 Common Commands

### Launch Single Lab
```bash
# Easy
cd easy && vagrant up training-001

# Medium
cd medium && vagrant up training-036

# Hard
cd hard && vagrant up training-071
```

### Launch Multiple Labs in Parallel
```bash
# Easy: Labs 1-5
cd easy
for i in {1..5}; do vagrant up training-$(printf "%03d" $i) &; done
wait

# Medium: Labs 36-40
cd medium
for i in {36..40}; do vagrant up training-$(printf "%03d" $i) &; done
wait

# Hard: Labs 71-75
cd hard
for i in {71..75}; do vagrant up training-$(printf "%03d" $i) &; done
wait
```

### Stop All Labs
```bash
cd easy && vagrant halt
cd ../medium && vagrant halt
cd ../hard && vagrant halt
```

### Check Status
```bash
cd easy && vagrant status
```

### SSH into Lab
```bash
cd easy && vagrant ssh training-001
```

### Destroy Lab
```bash
cd easy && vagrant destroy training-001
```

---

## 📊 Lab Distribution

| Level | Range | Count | Best For |
|-------|-------|-------|----------|
| Easy | 1-35 | 35 | Beginners |
| Medium | 36-70 | 35 | Intermediate |
| Hard | 71-105 | 35 | Advanced |

---

## 💡 Recommended Learning Paths

### Path 1: Start from scratch (Recommended)
```
Week 1: Easy 1-7
Week 2: Easy 8-14
Week 3: Easy 15-21
Week 4: Easy 22-28
Week 5: Easy 29-35
→ Then move to Medium
```

### Path 2: Fast track (Experienced only)
```
Day 1-2: Easy 1-5
Day 3-4: Medium 36-40
Day 5: Hard 71-75
```

### Path 3: Focused learning (Pick a topic)
```
LDAP Focus:
- Easy: 8-14
- Medium: 43-49
- Hard: 78-84
```

---

## 🔗 Interactive Launcher

For a menu-driven interface:

```bash
./launch-by-difficulty.sh
```

This provides:
- Easy lab selection
- Medium lab selection
- Hard lab selection
- Lab information
- Interactive navigation

---

## 📈 Difficulty Breakdown

### Easy (1-35) ⭐
- **Per lab**: 30-45 minutes
- **Topics**: AD basics, LDAP intro, Kerberos 101, simple privesc, golden ticket intro
- **Best for**: Learning fundamentals
- **Resource**: 2GB RAM per lab

### Medium (36-70) ⭐⭐
- **Per lab**: 45-90 minutes
- **Topics**: Advanced AD, LDAP exploitation, Kerberos attacks, complex chains
- **Best for**: Building skills
- **Resource**: 2GB RAM per lab (more CPU intensive)

### Hard (71-105) ⭐⭐⭐
- **Per lab**: 90-180 minutes
- **Topics**: Domain compromise, red team scenarios, complete takeover
- **Best for**: Mastering the subject
- **Resource**: 2GB+ RAM per lab (most intensive)

---

## 🚦 Port Mapping Quick Reference

### Easy Labs (1-35)
```
Lab 1:  localhost:5001
Lab 2:  localhost:5002
...
Lab 35: localhost:5035
```

### Medium Labs (36-70)
```
Lab 36: localhost:5036
Lab 37: localhost:5037
...
Lab 70: localhost:5070
```

### Hard Labs (71-105)
```
Lab 71: localhost:5071
Lab 72: localhost:5072
...
Lab 105: localhost:5105
```

---

## ⚙️ System Requirements

### Minimum (Single Lab)
- RAM: 2GB
- Disk: 20GB
- CPU: 2 cores

### Recommended (5 Labs)
- RAM: 10GB
- Disk: 100GB
- CPU: 8 cores

### Resource Notes
- **Easy**: Can run 3-5 simultaneously
- **Medium**: Run 2-3 simultaneously (more resource intensive)
- **Hard**: Run 1-2 simultaneously (most intensive)

---

## 🛠️ Troubleshooting

### Lab won't start
```bash
cd easy
vagrant up training-001 --debug
```

### Port already in use
```bash
lsof -i :5001
# Kill process or use different port
```

### Low disk space
```bash
vagrant box prune
vagrant destroy training-001
```

### SSH connection fails
```bash
vagrant ssh training-001 -- -v
```

---

## 📚 More Information

- **Complete guide**: See `DIFFICULTY_GUIDE.md`
- **Lab inventory**: See `LAB_INVENTORY.txt`
- **General README**: See `README.md`
- **Lab index**: See `INDEX.md`

---

## 🎓 Study Tips

1. **Start at Easy** - Build foundations
2. **Complete 7 variations per topic** - Each teaches something new
3. **Don't skip levels** - Progressive learning works
4. **Take notes** - Document techniques
5. **Compare labs** - See how difficulty increases
6. **Repeat if needed** - Go through again if concepts unclear
7. **Focus on one at a time** - Master one lab before moving on

---

**Version**: 1.0  
**Status**: ✅ Ready to use  
**Created**: 2026-08-06
