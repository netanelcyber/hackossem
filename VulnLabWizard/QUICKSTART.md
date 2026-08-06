# VulnLabWizard Quick Start Guide

Get up and running with 20 Windows vulnerability labs in 5 minutes!

---

## ⚡ 5-Minute Setup

### Step 1: Install VirtualBox (2 min)
```powershell
# Using Chocolatey
choco install virtualbox -y

# Verify installation
VBoxManage --version
```

**Or** download from: https://www.virtualbox.org/wiki/Downloads

### Step 2: Download Windows Server 2022 ISO (1 min)
```
URL: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
File: windows-server-2022.iso (~5GB)
Save to: D:\ISO\ or your preferred location
```

### Step 3: Run VulnLabWizard (1 min)
```powershell
# Right-click VulnLabWizard.exe → Run as Administrator
# Or run from PowerShell
powershell -Command "Start-Process .\VulnLabWizard.exe -Verb RunAs"
```

### Step 4: Follow the Wizard (1 min)
```
Mode: Select "Instructor Mode"
     ↓
ISO: Browse to windows-server-2022.iso
     ↓
Config: 
  - Lab Count: 20 (or 5/10/15)
  - RAM/VM: 2GB (adjust slider as needed)
  - Strategy: Sequential (default, uses less RAM)
     ↓
Deploy: Click "Next" and wait ~90 minutes
     ↓
Done! Summary shows network details & credentials
```

### Step 5: Access Your First Lab
```powershell
# Use Student Mode to access labs
# Or connect via RDP directly:
mstsc /v:127.0.0.1:5100
```

**Credentials**:
- Domain: `hackossem.local`
- User: `administrator`
- Password: `P@ssw0rd!2024`

---

## 🎯 Choose Your Path

### I want labs for practice (Students)
1. ✅ Run VulnLabWizard installer
2. ✅ Instructor launches wizard, deploys 5-20 labs
3. ✅ You use **Student Mode** to access labs
4. ✅ Start labs, RDP connect, begin exploitation

### I'm setting up labs for a team
1. ✅ Run VulnLabWizard on deployment machine
2. ✅ Instructor Mode: Deploy 10-20 labs
3. ✅ Use Admin Mode to create team copies
4. ✅ Distribute lab access to team members

### I need to automate deployment for CI/CD
1. ✅ Create `deployment.json` config file
2. ✅ Run: `VulnLabWizard.exe --mode auto --config deployment.json`
3. ✅ Script runs silently, logs output
4. ✅ Check exit code (0 = success, 1 = error)

### I have limited RAM (10-20GB)
1. ✅ VulnLabWizard supports **flexible deployment**
2. ✅ Select **5 labs** instead of 20 (uses 10GB RAM)
3. ✅ Or select **Sequential strategy** (only 2 VMs running at a time)
4. ✅ Start small, scale up as resources allow

---

## 🔑 Login Credentials

**Domain Admin** (all labs):
```
Domain:   hackossem.local
Username: administrator
Password: P@ssw0rd!2024
```

**Lab-Specific Users** (assigned per lab):
Each lab has custom users with weak/default passwords for exploitation.

See lab details in Student Mode dashboard.

---

## 📊 System Requirements

### Minimum (5 Labs)
- Windows 10 / Server 2019+
- 10GB RAM
- 50GB disk space
- VirtualBox 7.0+

### Recommended (20 Labs Sequential)
- Windows 10 / Server 2019+
- 20GB RAM
- 200GB disk space
- VirtualBox 7.0+

### Optimal (20 Labs Simultaneous)
- Windows Server 2022
- 40GB+ RAM
- 250GB disk space
- VirtualBox 7.0+

---

## 🎮 Using Student Mode

After Instructor deploys labs:

```
1. Launch VulnLabWizard.exe
2. Select "Student Mode"
3. View all 20 labs in dashboard
4. Click a lab to see details:
   - IP Address (192.168.56.100-119)
   - RDP Port (5100-5119)
   - Vulnerability Type
   - Difficulty Level (Easy/Medium/Hard)
5. Click "Start Lab" button
6. Wait for VM to boot
7. Click "RDP Connect" → connects automatically
8. Begin exploitation!
```

**Available Controls**:
- 🟢 **Start Lab** - Boot the VM
- 🔴 **Stop Lab** - Graceful shutdown
- 🔄 **Reset** - Restore to clean snapshot
- 🖥️ **RDP Connect** - One-click remote desktop
- 🔑 **View Credentials** - Lab access details
- 📖 **View Guide** - Exploitation walkthrough

---

## 💻 Command Line Reference

### Quick RDP Connection
```powershell
# Connect to Lab 1
mstsc /v:127.0.0.1:5100

# Connect to Lab 5
mstsc /v:127.0.0.1:5104

# Connect to Lab 20
mstsc /v:127.0.0.1:5119
```

### Start/Stop Labs via PowerShell
```powershell
# Start Lab 1
VBoxManage startvm "VulnLab-ad-lab-1" --type headless

# Stop Lab 1
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff

# Check status
VBoxManage list runningvms
```

### Automated Deployment
```powershell
# Create config file (deployment.json)
$config = @{
    deployment_method = "from-scratch"
    windows_iso = "D:\ISO\Windows Server 2022.iso"
    lab_prefix = "VulnLab"
    lab_count = 10
    memory_per_vm_gb = 2
    is_sequential = $true
    domain_name = "hackossem.local"
    domain_password = "P@ssw0rd!2024"
    create_snapshots = $true
    validate_after = $true
} | ConvertTo-Json | Out-File deployment.json

# Run automated deployment
VulnLabWizard.exe --mode auto --config deployment.json
```

---

## 🚀 Lab Progression

### Easy Labs (1-6) - 15-30 min each
Start here! Basic vulnerability types:
1. Weak Password Policy
2. Default Service Accounts
3. Unpatched System
4. IIS Basic Auth
5. Misconfigured Shares
6. UAC Bypass

### Medium Labs (7-13) - 30-60 min each
Build skills here:
7. SQL Injection
8. AD Delegation Abuse
9. Kerberoasting
10. Directory Traversal
11. GPO Misconfiguration
12. LDAP Injection
13. Token Impersonation

### Hard Labs (14-20) - 60-120 min each
Advanced techniques:
14. Multi-Stage PrivEsc
15. NTLM Relay
16. AD ACL Abuse
17. WebDAV RCE
18. DLL Injection
19. Kerberos S4U
20. Persistence

---

## 🔧 Troubleshooting

### "VirtualBox not found"
```powershell
# Install VirtualBox
choco install virtualbox -y

# Add to PATH if needed
$env:PATH += ";C:\Program Files\Oracle\VirtualBox"
```

### "Insufficient disk space"
```powershell
# Check available space
Get-Volume C: | Select-Object SizeRemaining

# Solutions:
# 1. Delete old VMs
VBoxManage unregistervm "VulnLab-ad-lab-1" --delete

# 2. Use different drive
VBoxManage setproperty machinefolder D:\VMs
```

### "Out of memory"
```powershell
# Reduce labs deployed
# Select "5 labs" instead of "20 labs" in wizard

# Or reduce per-VM RAM
# Use RAM slider: set to "1GB" instead of "2GB"

# Or use Sequential strategy (not Simultaneous)
```

### "Can't connect via RDP"
```powershell
# Verify VM is running
VBoxManage list runningvms

# Verify RDP port is configured
VBoxManage showvminfo "VulnLab-ad-lab-1" | findstr VRDE

# Restart VM
VBoxManage controlvm "VulnLab-ad-lab-1" poweroff
Start-Sleep -Seconds 5
VBoxManage startvm "VulnLab-ad-lab-1" --type headless

# Try again
mstsc /v:127.0.0.1:5100
```

---

## 📚 Full Documentation

- **README.md** - Complete feature overview
- **ARCHITECTURE.md** - System design and internals
- **VIRTUALBOX_SETUP.md** - Detailed VirtualBox configuration
- **DISCUSSIONS.md** - Architectural decisions and rationale

---

## 🎯 Next Steps

1. ✅ **Install** VirtualBox
2. ✅ **Download** Windows Server 2022 ISO
3. ✅ **Run** VulnLabWizard.exe (as Administrator)
4. ✅ **Follow** Instructor wizard steps
5. ✅ **Wait** for deployment (~90 min for 20 labs)
6. ✅ **Launch** Student Mode
7. ✅ **Connect** to first lab via RDP
8. ✅ **Start** exploiting!

---

## ❓ FAQ

**Q: How long does deployment take?**  
A: ~90 min for 20 labs (ISO method), ~5 min for OVA import

**Q: Can I pause/resume deployment?**  
A: Yes, stop VMs anytime. Resume by starting individual VMs.

**Q: What if I deploy wrong lab count?**  
A: Delete VMs and re-run wizard with correct count.

**Q: Can I share labs between team members?**  
A: Use Admin Mode → Team Setup to create isolated team sets.

**Q: Do I need internet for the labs?**  
A: No, labs are isolated on host-only network. Internet not required.

**Q: Can I change the default password?**  
A: Yes, configure during setup. Or change in AD after deployment.

**Q: What's the difference between Sequential and Simultaneous?**  
A: Sequential = lower RAM (2×2GB=4GB), slower  
Simultaneous = higher RAM (20×2GB=40GB), faster

**Q: Can I backup/restore lab progress?**  
A: Yes! Use Admin Mode → Snapshots → Create/Restore

---

## 📞 Support

**GitHub Issues**: https://github.com/netanelcyber/hackossem/issues

**Documentation**: See /docs/ folder in repository

**Contact**: 
- Create an issue on GitHub
- Check existing issues for solutions

---

## 🎉 You're Ready!

Download VulnLabWizard.exe and start learning!

**Remember**: 
- Always run as Administrator
- Network is isolated (no internet)
- Labs automatically have Active Directory deployed
- Each lab has its own RDP port (5100-5119)

Happy hacking! 🚀

---

**VulnLabWizard v1.0**  
*All-in-one Windows vulnerability lab automation*
