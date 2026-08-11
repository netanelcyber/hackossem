# WinRM Setup Guide (Critical for Ansible)

**WinRM = Windows Remote Management.** Ansible uses WinRM to execute commands on Windows machines. Without it, provisioning fails immediately.

## Why WinRM is Critical

- **Default Windows**: No remote management enabled
- **Ansible requirement**: Needs WinRM service listening on port 5985 (HTTP) or 5986 (HTTPS)
- **PowerShell Remoting**: WinRM enables `Invoke-Command` and other remote PS tasks

## Quick Setup (5 minutes per VM)

### 1. Start VM & Log In

```bash
VBoxManage startvm dc01 --type gui
```

Wait for Windows to boot. Log in as Administrator.

### 2. Open PowerShell as Administrator

- Press `Win+X`
- Select "Windows PowerShell (Admin)"
- Accept UAC prompt

### 3. Run WinRM Setup Script

Copy-paste this entire block into PowerShell:

```powershell
# Enable PowerShell script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Enable PSRemoting (WinRM service & firewall rules)
Enable-PSRemoting -Force

# Allow Ansible to use basic authentication (if not using Kerberos)
Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $true -Force

# Allow unencrypted connections (for lab environment only!)
Set-Item -Path "WSMan:\localhost\Service\AllowUnencrypted" -Value $true -Force

# Increase WinRM memory quota (default is often too small)
Set-Item -Path "WSMan:\localhost\Shell\MaxMemoryPerShellMB" -Value 1024 -Force

# Restart WinRM service
Restart-Service WinRM -Force

# Test WinRM locally
Test-WSMan localhost
```

**Expected output:**
```
wsmid     : http://schemas.dmtf.org/wbem/wscim/1/cim-schema/1/SCIM_WSManIdentityIdentity
ProtocolVersion : http://schemas.dmtf.org/wbem/wscim/1/common
ProductVendor   : Microsoft Corporation
ProductVersion  : OS: X.X.X BuildVersion: XXXXX
```

If you see this → **WinRM is working!**

### 4. Verify Firewall Rules

```powershell
# Check WinRM firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*WinRM*"}

# Should show rules for HTTP (5985) and/or HTTPS (5986)
```

If rules are missing:
```powershell
# Add rules manually
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

### 5. Shutdown VM

```powershell
Stop-Computer -Force
```

## Configuring Ansible to Connect

On your **Ansible control machine** (not on the VM), create/edit `inventory/hosts.ini`:

```ini
[windows:vars]
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_port=5985
ansible_winrm_message_encryption=auto

[windows]
dc01 ansible_host=192.168.1.11 ansible_user=Administrator ansible_password="P@ssw0rd1"
dc02 ansible_host=192.168.1.12 ansible_user=Administrator ansible_password="P@ssw0rd1"
srv02 ansible_host=192.168.1.22 ansible_user=Administrator ansible_password="P@ssw0rd1"
srv03 ansible_host=192.168.1.23 ansible_user=Administrator ansible_password="P@ssw0rd1"
ws01 ansible_host=192.168.1.30 ansible_user=Administrator ansible_password="P@ssw0rd1"
```

## Testing Connectivity from Ansible Host

After WinRM is enabled on **all VMs**:

1. **Start all VMs:**
   ```bash
   for vm in dc01 dc02 srv02 srv03 ws01; do
     VBoxManage startvm $vm --type headless
   done
   sleep 30  # Wait for VMs to boot
   ```

2. **Test from Ansible control machine:**
   ```bash
   # Test one VM
   ansible -i inventory/hosts.ini dc01 -m win_ping

   # Expected output:
   # dc01 | SUCCESS => {
   #     "changed": false,
   #     "ping": "pong"
   # }
   ```

3. **Test all VMs:**
   ```bash
   ansible -i inventory/hosts.ini windows -m win_ping
   ```

**If ping fails:**
- See `docs/07-TROUBLESHOOTING.md`

## Advanced WinRM Configuration

### Use HTTPS Instead of HTTP (More Secure)

```powershell
# Generate self-signed certificate
$cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "dc01"

# Create HTTPS WinRM listener
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force

# Firewall rule for HTTPS
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

**Then in inventory, use:**
```ini
ansible_winrm_transport=ssl
ansible_port=5986
```

### Increase WinRM Limits

For large playbooks that exceed memory quotas:

```powershell
# Increase shell memory quota
Set-Item -Path "WSMan:\localhost\Shell\MaxMemoryPerShellMB" -Value 2048 -Force

# Increase timeouts
Set-Item -Path "WSMan:\localhost\Client\TrustedHosts" -Value "*" -Force
```

### Debug WinRM Issues

```powershell
# Check WinRM status
Get-Service WinRM | Select-Object Name, Status, StartType

# View WinRM configuration
winrm get winrm/config

# Enable WinRM debug logging
Set-PSDebug -Trace 2  # Run before commands you want to debug
```

## Troubleshooting WinRM

| Issue | Solution |
|-------|----------|
| "WinRM is not running" | `Start-Service WinRM` |
| "Cannot find listener" | Run `Enable-PSRemoting -Force` again |
| "Access Denied" | Check credentials & user permissions |
| "Timeout connecting to host" | Check firewall rules & network connectivity |
| "HTTPS certificate error" | Use self-signed cert or skip cert validation in Ansible |

## Lab-Only Configuration (Insecure!)

For a lab environment **only** (not production), disable security:

```powershell
# Allow unencrypted traffic
Set-Item -Path "WSMan:\localhost\Service\AllowUnencrypted" -Value $true -Force

# Allow all hosts to connect
Set-Item -Path "WSMan:\localhost\Client\TrustedHosts" -Value "*" -Force

# Restart WinRM
Restart-Service WinRM -Force
```

In Ansible inventory, add:
```ini
ansible_winrm_message_encryption=never
```

---

**Next:** [`docs/05-ANSIBLE-INVENTORY.md`](05-ANSIBLE-INVENTORY.md) to build your inventory file.
