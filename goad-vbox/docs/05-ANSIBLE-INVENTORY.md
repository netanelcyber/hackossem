# Ansible Inventory Configuration Guide

The **inventory** file tells Ansible which hosts to target and how to connect to them.

## Inventory Structure

```ini
[group_name]
host1 ansible_host=IP ansible_user=user ansible_password=pass
host2 ansible_host=IP ansible_user=user ansible_password=pass

[group_name:vars]
ansible_var=value
```

## Basic Inventory for GOAD (Full Variant)

**File: `inventory/hosts.ini`**

```ini
[windows:vars]
# Connection settings
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_port=5985
ansible_winrm_message_encryption=auto

# Ansible settings
ansible_become_method=runas
ansible_language_locale=en_US

[windows]
# Domain Controllers
dc01 ansible_host=192.168.1.11 ansible_user=Administrator ansible_password="P@ssw0rd1"
dc02 ansible_host=192.168.1.12 ansible_user=Administrator ansible_password="P@ssw0rd1"

# Member Servers
srv02 ansible_host=192.168.1.22 ansible_user=Administrator ansible_password="P@ssw0rd1"
srv03 ansible_host=192.168.1.23 ansible_user=Administrator ansible_password="P@ssw0rd1"

# Workstations
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

## Inventory for GOAD Light (3 VMs)

```ini
[windows:vars]
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_port=5985
ansible_winrm_message_encryption=auto

[windows]
dc01 ansible_host=192.168.1.11 ansible_user=Administrator ansible_password="P@ssw0rd1"
srv02 ansible_host=192.168.1.22 ansible_user=Administrator ansible_password="P@ssw0rd1"
ws01 ansible_host=192.168.1.30 ansible_user=Administrator ansible_password="P@ssw0rd1"

[domain_controllers]
dc01

[member_servers]
srv02

[workstations]
ws01
```

## Inventory with Group Variables

For cleaner organization, use separate `group_vars/` files:

**Directory structure:**
```
inventory/
├── hosts.ini
└── group_vars/
    ├── windows.yml
    ├── domain_controllers.yml
    └── member_servers.yml
```

**`inventory/hosts.ini`:**
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

**`inventory/group_vars/windows.yml`:**
```yaml
---
ansible_connection: winrm
ansible_winrm_transport: basic
ansible_port: 5985
ansible_winrm_message_encryption: auto
ansible_become_method: runas
```

**`inventory/group_vars/domain_controllers.yml`:**
```yaml
---
dc_role: primary
forest_mode: 2016
domain_functional_level: 2016
```

**`inventory/group_vars/member_servers.yml`:**
```yaml
---
server_role: member
adcs_enabled: false
sccm_enabled: false
```

## Inventory Variables Explained

| Variable | Purpose |
|----------|---------|
| `ansible_host` | IP address of the Windows machine |
| `ansible_user` | Administrator username (local to machine) |
| `ansible_password` | Administrator password |
| `ansible_connection` | Use `winrm` for Windows |
| `ansible_winrm_transport` | Use `basic` for lab; `ssl` for production |
| `ansible_port` | 5985 (HTTP) or 5986 (HTTPS) |
| `ansible_winrm_message_encryption` | `auto`, `never`, or `always` |
| `ansible_become_method` | `runas` for Windows (sudo equivalent) |

## Using Vault for Credentials (Secure!)

Instead of storing plaintext passwords, use Ansible Vault:

```bash
# Create vault file with passwords
ansible-vault create inventory/group_vars/windows-vault.yml
```

**Enter in the vault editor:**
```yaml
---
ansible_user: Administrator
ansible_password: P@ssw0rd1
```

**Then reference in `inventory/hosts.ini`:**
```ini
[windows:vars]
@include ../group_vars/windows-vault.yml
```

**Run Ansible with vault:**
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass
# Enter vault password when prompted
```

## Testing Inventory

**Check inventory syntax:**
```bash
ansible-inventory -i inventory/hosts.ini --list
```

**Test connectivity to all hosts:**
```bash
ansible -i inventory/hosts.ini windows -m win_ping
```

**Test specific group:**
```bash
ansible -i inventory/hosts.ini domain_controllers -m win_ping
```

**Run command on all:**
```bash
ansible -i inventory/hosts.ini windows -m win_command -a "hostname"
```

## Dynamic Inventory (Advanced)

If you want to auto-generate inventory from VirtualBox:

**`scripts/generate-inventory.py`:**
```python
#!/usr/bin/env python3
import subprocess
import json
import sys

# Get all running VMs
result = subprocess.run(
    ["VBoxManage", "list", "vms", "--long"],
    capture_output=True, text=True
)

# Parse and build inventory
# (Implementation depends on your VM naming convention)
```

## Common Mistakes

❌ **Wrong IP**: Copy-paste errors cause connection timeouts  
❌ **Typo in hostname**: Ansible can't find the host  
❌ **Credentials with special characters**: Quote them!  
❌ **Forgetting WinRM is enabled**: Test with `win_ping` first  
❌ **Using domain credentials before domain exists**: Use local Administrator  

## Multi-Domain Inventory (Advanced)

If setting up multiple domains:

```ini
[domain_goad]
dc01 ansible_host=192.168.1.11
srv02 ansible_host=192.168.1.22

[domain_extern]
dc01_extern ansible_host=192.168.2.11
srv02_extern ansible_host=192.168.2.22

[windows:children]
domain_goad
domain_extern

[domain_goad:vars]
domain_name=goad.local
domain_admin=goad\\Administrator

[domain_extern:vars]
domain_name=extern.local
domain_admin=extern\\Administrator
```

---

**Next:** [`docs/06-RUNNING-PLAYBOOKS.md`](06-RUNNING-PLAYBOOKS.md)
