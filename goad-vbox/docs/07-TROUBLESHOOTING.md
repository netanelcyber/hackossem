# Troubleshooting Guide

Common issues and their solutions.

## Network Issues

### VMs Don't Get IP Address

**Symptom**: VMs boot but have no IP (169.x.x.x address)

**Causes & Fixes**:
1. **Network not created**
   ```bash
   VBoxManage dhcpserver add --network=goad-internal --server-ip=192.168.1.1 --netmask=255.255.255.0 --lower-ip=192.168.1.100 --upper-ip=192.168.1.200 --enable
   ```

2. **DHCP disabled on network**
   ```bash
   VBoxManage dhcpserver modify --network=goad-internal --enable
   ```

3. **VM NIC not attached to correct network**
   ```bash
   VBoxManage showvminfo dc01 | grep NIC
   # Should show: nic1: intnet (internal network)
   ```
   If wrong, reattach:
   ```bash
   VBoxManage modifyvm dc01 --nic1 intnet --intnet1 goad-internal
   ```

### VMs Have IP But Can't Ping Each Other

**Symptom**: Each VM gets IP but isolated from others

**Causes & Fixes**:
1. **Multiple adapters configured**
   - Disable extra NICs (if not needed)
   ```bash
   VBoxManage modifyvm dc01 --nic2 none --nic3 none --nic4 none
   ```

2. **Windows Firewall blocking**
   - On VM (PowerShell as Admin):
   ```powershell
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled $false
   # Or allow ping:
   New-NetFirewallRule -Name "Allow-ICMP" -DisplayName "Allow ICMP" -Protocol ICMPv4 -Action Allow
   ```

## WinRM/Ansible Connection Issues

### Ansible Timeout: "Timeout waiting for..."

**Symptom**: `ansible -m win_ping` times out

**Causes & Fixes**:
1. **WinRM service not running on VM**
   ```powershell
   # On Windows VM (PS Admin):
   Start-Service WinRM
   Get-Service WinRM | Select Status
   ```

2. **Firewall blocking port 5985**
   ```powershell
   # On Windows VM:
   New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
   ```

3. **WinRM listener not configured**
   ```powershell
   # On Windows VM:
   Enable-PSRemoting -Force
   Test-WSMan localhost
   ```

4. **Timeout in inventory too short**
   ```bash
   # Try with longer timeout
   export ANSIBLE_TIMEOUT=60
   ansible -i inventory/hosts.ini windows -m win_ping
   ```

### "Access Denied" or "403 Forbidden"

**Symptom**: WinRM connects but authentication fails

**Causes & Fixes**:
1. **Wrong password in inventory**
   - Verify by logging into VM manually via RDP
   - Check for special characters that need escaping

2. **Basic auth disabled**
   ```powershell
   # On Windows VM:
   Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $true -Force
   ```

3. **IP changed from what's in inventory**
   ```bash
   # Verify IP on VM
   VBoxManage guestcontrol dc01 run --username Administrator --password "P@ssw0rd1" -- powershell ipconfig
   ```

### "Cannot connect to endpoint"

**Symptom**: Connection refused or host unreachable

**Causes & Fixes**:
1. **VM not running**
   ```bash
   VBoxManage list runningvms | grep dc01
   # If not listed, start it:
   VBoxManage startvm dc01 --type headless
   ```

2. **IP in inventory wrong**
   ```bash
   # Verify:
   ansible -i inventory/hosts.ini dc01 -m setup | grep ansible_ip
   ```

3. **Network connectivity broken**
   ```bash
   # From Linux host:
   ping 192.168.1.11
   # From Windows VM:
   ping 192.168.1.1
   ```

## Ansible Playbook Failures

### "The term 'Install-WindowsFeature' is not recognized"

**Symptom**: PowerShell module not available

**Cause**: PowerShell version too old (need PS 3.0+)

**Fix**:
```powershell
# On Windows VM:
$PSVersionTable.PSVersion
# If < 3.0, update via Windows Update
```

### "The specified domain already exists"

**Symptom**: Playbook fails on domain creation (second run)

**This is normal!** Playbooks are idempotent.

**Fix**: Rerun the playbook (it will skip already-completed tasks):
```bash
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml -v
```

### "WinRM message size exceeds policy"

**Symptom**: Large data transfers fail

**Cause**: Default WinRM quota too small

**Fix** (on Windows VMs):
```powershell
# Increase max envelope size
Set-Item -Path "WSMan:\localhost\MaxEnvelopeSizekb" -Value 2048 -Force
Set-Item -Path "WSMan:\localhost\Shell\MaxMemoryPerShellMB" -Value 1024 -Force
Restart-Service WinRM -Force
```

## VirtualBox Issues

### "VirtualBox kernel module not loaded"

**Symptom**: `VBoxManage` commands fail with kernel module error

**Fix**:
```bash
# Linux only:
sudo modprobe vboxdrv
# Or:
sudo /sbin/vboxconfig
```

### "Disk image not found" When Creating VM

**Symptom**: VM creation fails with ISO/disk path error

**Cause**: File path doesn't exist

**Fix**:
```bash
# Verify file exists:
ls -lh /opt/iso/WinServer2016.iso

# Use absolute path in create-vms.sh:
bash scripts/create-vms.sh --iso-2016 /full/path/to/WinServer2016.iso
```

### "Cannot create medium: insufficient disk space"

**Symptom**: VM disk creation fails

**Fix**:
```bash
# Check disk space:
df -h /var/lib/vbox/

# Free up space or change disk location:
VBoxManage setproperty machinefolder /path/with/more/space/
```

### VM "Stuck" or Unresponsive

**Symptom**: VM won't shutdown, appears frozen

**Fix**:
```bash
# Force power off:
VBoxManage controlvm dc01 poweroff

# If that doesn't work:
VBoxManage unregistervm dc01 --delete-config
# Then recreate VM
```

## Domain Join Issues

### "The specified domain controller could not be contacted"

**Symptom**: SRV/WS VMs fail to join domain

**Cause**: DNS not pointing to DC

**Fix** (on member server):
```powershell
# Set DNS to DC01 IP:
Set-DnsClientServerAddress -InterfaceIndex <interface> -ServerAddresses ("192.168.1.11")

# Verify:
nslookup goad.local
# Should resolve to DC01 IP
```

### "Access denied" When Joining Domain

**Symptom**: Domain join fails with access error

**Cause**: Wrong credentials or insufficient permissions

**Fix**:
```powershell
# Verify domain admin creds (in playbook)
# Usually: GOAD\Administrator or goad.local\Administrator

# Test credentials manually:
$cred = Get-Credential
# Enter: goad\Administrator / Password
Add-Computer -DomainName goad.local -Credential $cred -Restart
```

## Post-Provisioning Verification

### Lab Not Working as Expected

**Checklist**:
```bash
# 1. All VMs running?
VBoxManage list runningvms

# 2. WinRM working?
ansible -i inventory/hosts.ini windows -m win_ping

# 3. Domain created?
ansible -i inventory/hosts.ini dc01 -m win_command -a "Get-ADDomain"

# 4. Users created?
ansible -i inventory/hosts.ini dc01 -m win_command -a "Get-ADUser -Filter *" | head -20

# 5. Services running?
ansible -i inventory/hosts.ini dc01 -m win_service -a "name=NTDS" -c "Get-Service"
```

### Can't RDP into VM

**Symptom**: RDP connection refused

**Cause**: RDP service not enabled or firewall blocking

**Fix** (on Windows VM):
```powershell
# Enable RDP:
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0

# Allow firewall:
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

**From Linux, use xfreerdp:**
```bash
xfreerdp /u:goad\\Administrator /p:Password /v:192.168.1.11
```

## Performance Issues

### Lab Is Very Slow

**Possible causes & fixes**:

1. **Insufficient RAM**
   - Check VirtualBox memory: `free -h`
   - Increase VM memory: `VBoxManage modifyvm dc01 --memory 4096`

2. **Disk I/O bottleneck**
   - Use SSD instead of HDD
   - Check disk usage: `df -h`

3. **Too many VMs running**
   - Stop unused VMs: `VBoxManage controlvm srv03 poweroff`
   - Use GOAD-Light (3 VMs) instead of full (5 VMs)

## Getting Help

If you're stuck:

1. **Check this guide again** — most common issues are documented
2. **Review playbook output** — look for specific error messages
3. **Check Windows Event Viewer** on the failing VM
4. **Ask in GOAD GitHub issues** — https://github.com/Orange-Cyberdefense/GOAD/issues
5. **Enable Ansible debug** — use `-vvv` flag for maximum verbosity

---

**Common Commands for Debugging**:

```bash
# Start all VMs
for vm in dc01 dc02 srv02 srv03 ws01; do VBoxManage startvm $vm --type headless; done

# Test connectivity
ansible -i inventory/hosts.ini windows -m win_ping -vvv

# Check domain
ansible -i inventory/hosts.ini dc01 -m win_command -a "Get-ADDomain"

# View logs
tail -f logs/provision.log

# SSH into VM (if configured)
ssh -p 22 Administrator@192.168.1.11
```
