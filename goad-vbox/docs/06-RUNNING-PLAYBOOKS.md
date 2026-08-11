# Running Ansible Playbooks for Provisioning

After WinRM is enabled on all VMs and inventory is configured, you provision the AD lab using Ansible playbooks.

## GOAD Playbook Structure

GOAD playbooks are organized by functionality:

```
playbooks/
├── 0-preflight.yml           # Validation & prerequisite checks
├── 1-domain-setup.yml        # Create forest & domain
├── 2-users-groups.yml        # Create users, groups, OUs
├── 3-gpo-policies.yml        # Deploy Group Policies
├── 4-services.yml            # Install services (ADCS, DHCP, etc.)
├── 5-misconfigs.yml          # Create security misconfigurations
├── roles/
│   ├── domain_controller/
│   ├── member_server/
│   ├── workstation/
│   ├── adcs/
│   └── ...
└── site.yml                  # Master playbook (runs all)
```

## Quick Provisioning (Automated)

```bash
bash scripts/apply-provisioning.sh \
  --variant full \
  --inventory inventory/hosts.ini
```

This script:
1. Validates prerequisite checks
2. Runs playbooks in correct order
3. Reports errors clearly
4. Logs all output to `logs/provision.log`

## Manual Provisioning (Step by Step)

If you want control over which playbooks run:

### Step 1: Preflight Checks
```bash
ansible-playbook -i inventory/hosts.ini playbooks/0-preflight.yml -v
```

**What it does:**
- Verifies Windows versions
- Checks network connectivity
- Validates administrator access
- Tests DNS resolution

### Step 2: Create Domain
```bash
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml -v
```

**What it does:**
- Installs Active Directory on DC01
- Creates forest: `goad.local`
- Creates domain: `goad.local`
- Sets DC02 as secondary DC
- Configures replication

**Expected duration: 10-15 minutes**

⚠️ **VMs will reboot during this step.**

### Step 3: Create Users & Groups
```bash
ansible-playbook -i inventory/hosts.ini playbooks/2-users-groups.yml -v
```

**What it does:**
- Creates OUs (Organizational Units)
- Creates users with realistic names
- Creates groups (developers, admins, etc.)
- Sets user properties (email, phone, description)

### Step 4: Deploy GPO Policies
```bash
ansible-playbook -i inventory/hosts.ini playbooks/3-gpo-policies.yml -v
```

**What it does:**
- Creates Group Policy Objects
- Links policies to OUs
- Applies security settings
- Configures password policies

### Step 5: Install Services
```bash
ansible-playbook -i inventory/hosts.ini playbooks/4-services.yml -v
```

**What it does:**
- Installs ADCS (Active Directory Certificate Services)
- Installs DHCP if needed
- Installs SCCM or other services
- Configures service permissions

**Expected duration: 10-20 minutes**

### Step 6: Create Misconfigurations
```bash
ansible-playbook -i inventory/hosts.ini playbooks/5-misconfigs.yml -v
```

**What it does:**
- Creates vulnerable AD configurations
- Sets weak permissions
- Configures privilege escalation paths
- Enables attack vectors for lab exercises

**Examples of misconfigurations:**
- AD users with plaintext passwords in description
- Overly permissive ACLs
- Service accounts with weak passwords
- Unconstrained delegation
- Resource-based constrained delegation
- Kerberoastable accounts

## Running All Playbooks at Once

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v
```

**This runs all playbooks in sequence (equivalent to `apply-provisioning.sh`)**

## Monitoring Playbook Execution

### Verbose Output
```bash
# Level 1: Standard output
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml

# Level 2: Verbose (show variable values)
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml -v

# Level 3: Extra verbose (task by task)
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml -vv

# Level 4: Debug (everything, including WinRM traffic)
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml -vvv
```

### Save Output to File
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v | tee logs/provision.log
```

### Check Syntax Before Running
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --syntax-check
```

## Idempotency: Rerun Safely

GOAD playbooks are **idempotent** — you can run them multiple times without side effects.

**Scenario:** Provisioning fails midway → Fix the issue → Rerun

```bash
# After fixing the issue, rerun from where it failed
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v
```

Ansible skips tasks that already succeeded and only runs necessary changes.

## Running Specific Tasks

To run only a specific subset:

```bash
# Run only tasks tagged "users"
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v --tags users

# Run only ADCS setup
ansible-playbook -i inventory/hosts.ini playbooks/4-services.yml -v --tags adcs

# Skip services (run everything except services)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v --skip-tags services
```

## Running on Specific Hosts

```bash
# Provision only DC01
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v --limit dc01

# Provision only member servers
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v --limit member_servers

# Provision all except workstations
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v --limit '!workstations'
```

## Dry-Run (Check Mode)

Preview changes without applying:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v --check
```

**Output shows:**
- What would change
- What commands would run
- What files would be created/modified
- **No actual changes are made**

## Debugging Playbook Failures

### 1. Check WinRM Connectivity First
```bash
ansible -i inventory/hosts.ini windows -m win_ping
```

If this fails, WinRM isn't working. See `docs/04-WINRM-SETUP.md`.

### 2. Run Playbook with Extra Verbosity
```bash
ansible-playbook -i inventory/hosts.ini playbooks/1-domain-setup.yml -vvv
```

Look for:
- Connection errors
- Module errors
- Variable substitution issues

### 3. Check Logs on Windows VM
SSH/RDP into the Windows machine and check:
```powershell
Get-EventLog -LogName System -Newest 20
Get-EventLog -LogName Application -Newest 20
```

### 4. Common Failures

| Error | Cause | Fix |
|-------|-------|-----|
| "Timeout waiting for" | WinRM connection slow | Increase timeout in playbook |
| "The term 'psrp' is not" | PowerShell version too old | Update PowerShell |
| "Access Denied" | Wrong credentials | Verify password in inventory |
| "The specified domain... already exists" | Domain already created | Run playbook idempotently (safe) |

## Post-Provisioning Verification

After playbooks complete:

```bash
# Test connectivity to all hosts
ansible -i inventory/hosts.ini windows -m win_ping

# Check domain was created
ansible -i inventory/hosts.ini dc01 -m win_command -a "Get-ADDomain"

# List created users
ansible -i inventory/hosts.ini dc01 -m win_command -a "Get-ADUser -Filter *"

# Verify services are running
ansible -i inventory/hosts.ini -m win_service -a "name=NTDS state=started" windows
```

## Performance Tuning

### Run Playbooks in Parallel

```bash
# Use 5 parallel forks (default is 1 for Windows)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v -f 5
```

### Increase Timeouts

If provisioning times out:

```bash
export ANSIBLE_TIMEOUT=600  # 10 minutes
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v
```

Or in `ansible.cfg`:
```ini
[defaults]
timeout = 600
```

---

**Next:** [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md) if issues arise.
