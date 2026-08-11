# GOAD VirtualBox Setup: Quick Start (10 Minutes)

**Assumption**: You've already read the main `README.md`. This guide gets you from zero to a working GOAD lab.

## Step 1: Verify Prerequisites (2 min)

```bash
cd goad-vbox
bash scripts/check-requirements.sh
```

**Expected output:**
```
✓ VirtualBox 7.0.8 installed
✓ VBoxManage available
✓ Ansible 2.10+ installed
✓ Git available
✓ Sufficient disk space (100 GB free)
✓ Sufficient RAM (12 GB available)
```

If any check fails, install the missing tool. See main README for installation links.

## Step 2: Prepare Windows ISOs (5-10 min)

**You need two Windows Server ISOs** (or one, used for multiple VMs):

1. **Windows Server 2016** (for DC01, DC02)
   - Download from: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2016
   - Or use: `sudo apt-get install ... # distro-specific`
   - File: `WinServer2016.iso` (~6 GB)

2. **Windows Server 2019** (for SRV02, SRV03)
   - Download from: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019
   - File: `WinServer2019.iso` (~6 GB)

**Optional**: Windows 10 ISO for WS01 workstation.

Store ISOs in a known location, e.g., `~/Downloads/` or `/opt/iso/`.

## Step 3: Create VirtualBox Network (1 min)

```bash
bash scripts/network-setup.sh --variant full
```

This creates an isolated internal network:
- **Network**: `goad-internal`
- **DHCP Range**: `192.168.1.100 – 192.168.1.200`
- **Gateway/DNS**: `192.168.1.1` (you'll configure this)

**Verify:**
```bash
VBoxManage list networks | grep -i goad
```

## Step 4: Create VMs (2 min automated + 10-30 min per VM setup)

### For GOAD Full (5 VMs):
```bash
bash scripts/create-vms.sh \
  --variant full \
  --iso-2016 ~/Downloads/WinServer2016.iso \
  --iso-2019 ~/Downloads/WinServer2019.iso
```

### For GOAD Light (3 VMs):
```bash
bash scripts/create-vms.sh \
  --variant light \
  --iso-2016 ~/Downloads/WinServer2016.iso \
  --iso-2019 ~/Downloads/WinServer2019.iso
```

**What this does:**
- Creates VM disks (QCOW2 format)
- Allocates vCPU, RAM, NICs
- Attaches ISO to each VM
- **Does NOT start VMs** yet

**Verify:**
```bash
VBoxManage list vms
# Output:
# "dc01" {uuid...}
# "dc02" {uuid...}
# "srv02" {uuid...}
# ...
```

## Step 5: Install Windows (Manual GUI—15-30 min per VM)

For **EACH VM**, start the installer:

```bash
# Start VM with GUI
VBoxManage startvm dc01 --type gui
```

**For each Windows Server VM:**
1. **Boot and follow installer**
   - Language: English (or your preference)
   - Installation type: **Windows Server 2016/2019 Standard Desktop Experience**
   - Disk: Accept default (single disk)
   - Installation location: Select available disk

2. **After installation, configure network**
   - IP: **Manual** (do NOT use DHCP yet)
   - Address: `192.168.1.11` (for dc01; increment for others)
   - Netmask: `255.255.255.0`
   - Gateway: `192.168.1.1`
   - DNS: **Leave blank for now** (we'll configure after domain setup)

3. **Set Administrator password**
   - Use something memorable: e.g., `P@ssw0rd1`
   - **Write it down**—you'll need it for Ansible

4. **Hostname**
   - Right-click "This PC" → Properties → Rename
   - Set to: `dc01`, `dc02`, `srv02`, `srv03` (matching your VMs)
   - Restart

5. **Shutdown VM**
   ```bash
   VBoxManage controlvm dc01 poweroff
   ```

**VM Assignments (GOAD Full):**
| VM | IP | Hostname | OS |
|----|----|---------|----|
| dc01 | 192.168.1.11 | dc01 | Windows Server 2016 |
| dc02 | 192.168.1.12 | dc02 | Windows Server 2016 |
| srv02 | 192.168.1.22 | srv02 | Windows Server 2019 |
| srv03 | 192.168.1.23 | srv03 | Windows Server 2019 |
| ws01 | 192.168.1.30 | ws01 | Windows 10 |

## Step 6: Enable WinRM (Remote Management) (5 min per VM)

**Ansible uses WinRM (Windows Remote Management) to communicate with VMs.** This is critical!

For **EACH VM**:

1. **Start VM**
   ```bash
   VBoxManage startvm dc01 --type gui
   ```

2. **On Windows, open PowerShell as Administrator**
   - Press `Win+X` → Choose "Windows PowerShell (Admin)"

3. **Run this script** (copy-paste into PowerShell):
   ```powershell
   # Allow script execution
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
   
   # Enable WinRM
   Enable-PSRemoting -Force
   
   # Configure WinRM listener
   New-NetFirewallRule -Name "WinRM HTTP" -DisplayName "WinRM HTTP" -Enabled True -Profile Public -Action Allow -Protocol TCP -LocalPort 5985
   New-NetFirewallRule -Name "WinRM HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Profile Public -Action Allow -Protocol TCP -LocalPort 5986
   
   # Test WinRM
   Test-WSMan localhost
   # Should output: wsmid : http://schemas.dmtf.org/wbem/wscim/1/cim-schema/1/SCIM_WSManIdentityIdentity
   ```

4. **Shutdown VM**
   ```bash
   Stop-Computer -Force
   ```

Repeat for all VMs.

## Step 7: Create Ansible Inventory (2 min)

Edit `inventory/hosts.ini`:

```bash
cp inventory/hosts-template.ini inventory/hosts.ini
# Edit with your IP addresses & passwords
```

**For GOAD Full**, populate:
```ini
[windows]
dc01 ansible_host=192.168.1.11 ansible_user=Administrator ansible_password="P@ssw0rd1"
dc02 ansible_host=192.168.1.12 ansible_user=Administrator ansible_password="P@ssw0rd1"
srv02 ansible_host=192.168.1.22 ansible_user=Administrator ansible_password="P@ssw0rd1"
srv03 ansible_host=192.168.1.23 ansible_user=Administrator ansible_password="P@ssw0rd1"
ws01 ansible_host=192.168.1.30 ansible_user=Administrator ansible_password="P@ssw0rd1"

[domain_controllers]
dc01
dc02

[member_servers]
srv02
srv03

[workstations]
ws01
```

## Step 8: Test Ansible Connectivity (2 min)

```bash
# Start all VMs
VBoxManage startvm dc01 --type headless
VBoxManage startvm dc02 --type headless
VBoxManage startvm srv02 --type headless
VBoxManage startvm srv03 --type headless
VBoxManage startvm ws01 --type headless

# Wait 30 seconds for VMs to boot

# Test connectivity
ansible -i inventory/hosts.ini windows -m win_ping

# Expected output:
# dc01 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
# ...
```

If all return `pong`, WinRM is working!

## Step 9: Run Ansible Provisioning (20-30 min)

```bash
bash scripts/apply-provisioning.sh \
  --variant full \
  --inventory inventory/hosts.ini
```

This runs Ansible playbooks that:
1. Create AD forest/domain
2. Create users & groups
3. Deploy GPO policies
4. Install services (ADCS, SCCM, etc.)
5. Create vulnerable misconfigurations

**Monitor output for errors**. If a playbook fails, see `docs/07-TROUBLESHOOTING.md`.

## Step 10: Verify Lab is Ready (2 min)

```bash
bash scripts/health-check.sh --inventory inventory/hosts.ini

# Expected output:
# ✓ dc01: WinRM connectivity OK
# ✓ dc02: WinRM connectivity OK
# ✓ Domain "goad.local" reachable from dc01
# ✓ All users created
# ✓ Lab is ready!
```

## ✅ Done!

Your GOAD lab is now ready for pentesting!

### What You Can Now Do

- **RDP into any VM** (e.g., `xfreerdp /u:goad\\hacker /p:PASSWORD /v:192.168.1.11`)
- **Scan with Nmap**: `nmap -sV 192.168.1.0/24`
- **Enumerate AD**: `enum4linux -a 192.168.1.11`
- **Exploit misconfigs**: See GOAD documentation for known vectors

### Cleanup (When You're Done)

```bash
bash scripts/cleanup-vms.sh --variant full
# Removes all VMs and storage
```

---

**Next**: See [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md) if you encounter issues.
