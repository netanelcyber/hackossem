# GOAD Variants: Full vs Light vs Custom

GOAD offers multiple lab configurations for different use cases.

## GOAD Full

**5 VMs, complete Active Directory infrastructure**

### VM Configuration

| VM | OS | vCPU | RAM | Disk | Role |
|----|----|----|-----|------|------|
| **dc01** | Windows Server 2016 | 2 | 2GB | 60GB | Primary DC, forest root |
| **dc02** | Windows Server 2016 | 2 | 2GB | 60GB | Secondary DC, child domain |
| **srv02** | Windows Server 2019 | 2 | 2GB | 60GB | File/Print Server, ADCS |
| **srv03** | Windows Server 2019 | 2 | 2GB | 60GB | Exchange or SCCM |
| **ws01** | Windows 10 | 2 | 2GB | 40GB | User Workstation |

**Total Resources**: 10 vCPU, 10GB RAM, 280GB disk

### Forest/Domain Structure

```
goad.local (Forest Root)
├── DC: dc01 (Primary)
├── DC: dc02 (Secondary)
├── SRV: srv02 (ADCS, File Services)
├── SRV: srv03 (Additional services)
└── WS: ws01 (User workstation)
```

### Included Services

- ✅ Active Directory Domain Services (ADDS)
- ✅ Active Directory Certificate Services (ADCS)
- ✅ Group Policy Objects (GPOs)
- ✅ File & Print Services
- ✅ Kerberos authentication
- ✅ DNS (BIND or Windows DNS)
- ✅ DHCP services
- ✅ Optional: SCCM, Exchange, or other enterprise services

### Use Cases

- **Red teamers**: Full enterprise environment to exploit
- **Blue teamers**: Comprehensive monitoring/detection lab
- **Domain administrators**: Complete AD infrastructure training
- **Security researchers**: Rich attack surface with multiple paths

### Estimated Setup Time

- VM creation: 10-15 min (automated)
- Windows installation: 30-40 min (per VM, manual)
- WinRM setup: 5 min (per VM)
- Ansible provisioning: 30-45 min (fully automated)
- **Total: 2-3 hours**

## GOAD Light

**3 VMs, simplified but realistic**

### VM Configuration

| VM | OS | vCPU | RAM | Disk | Role |
|----|----|----|-----|------|------|
| **dc01** | Windows Server 2016 | 2 | 2GB | 60GB | Primary DC, forest root |
| **srv02** | Windows Server 2019 | 2 | 2GB | 60GB | Member server |
| **ws01** | Windows 10 | 2 | 2GB | 40GB | User workstation |

**Total Resources**: 6 vCPU, 6GB RAM, 160GB disk

### Forest/Domain Structure

```
goad.local
├── DC: dc01 (Primary)
├── SRV: srv02 (Member server)
└── WS: ws01 (User workstation)
```

### Included Services

- ✅ Active Directory Domain Services
- ✅ Group Policy Objects (basic)
- ✅ File Services
- ✅ DNS
- ✅ Core attack vectors (Kerberoasting, constrained delegation, etc.)
- ❌ No secondary DC (simpler replication)
- ❌ No ADCS (no certificate-based attacks)
- ❌ No advanced services

### Use Cases

- **Learning AD basics**: Smaller footprint, easier to understand
- **Pentesting practice**: All essential attack paths, lighter resource usage
- **CI/CD labs**: Faster deployment, less resource overhead
- **Resource-constrained environments**: Laptop with 8GB RAM

### Estimated Setup Time

- VM creation: 5-10 min
- Windows installation: 20-30 min (per VM, manual)
- WinRM setup: 5 min
- Ansible provisioning: 15-25 min
- **Total: 1.5-2 hours**

## GOAD Custom

**Build your own variant**

### Example: GOAD Minimal (2 VMs)

```bash
# dc01: Domain controller only
# ws01: Workstation for attacking DC

# VM specs:
# - dc01: 2 vCPU, 2GB RAM, 50GB disk
# - ws01: 2 vCPU, 2GB RAM, 30GB disk
# Total: 4 vCPU, 4GB RAM, 80GB disk
```

### Example: Multi-Domain Lab

```bash
# Two separate domains:
# - goad.local (forest root)
# - child.goad.local (child domain)
# 
# VMs:
# - dc01: goad.local DC
# - dc02: child.goad.local DC
# - srv01: Member in goad.local
# - srv02: Member in child.goad.local
# - ws01: Joined to goad.local
```

### Building Custom Variants

1. **Choose your VMs** (DC, member server, workstation, etc.)
2. **Assign IPs** (update `inventory/hosts.ini`)
3. **Select services** (edit playbooks/roles)
4. **Run provisioning** (Ansible playbooks)

## Choosing a Variant

### Quick Decision Tree

```
Are you:
  ├─ Learning AD for first time?
  │  └─ → GOAD Light
  ├─ Practicing pentesting techniques?
  │  ├─ Need kerberoasting?
  │  │  └─ → GOAD Light (sufficient)
  │  ├─ Need certificate attacks (ADCS)?
  │  │  └─ → GOAD Full
  │  └─ Need multi-domain attacks?
  │     └─ → GOAD Full or Custom
  ├─ Training on domain administration?
  │  └─ → GOAD Full (complete environment)
  ├─ Have limited resources (<8GB RAM)?
  │  └─ → GOAD Light
  └─ Have plenty of resources?
     └─ → GOAD Full
```

## Resource Requirements Comparison

| Resource | GOAD Light | GOAD Full |
|----------|----------|----------|
| **Host RAM** | 8GB minimum | 16GB recommended |
| **Host CPU** | 4+ cores | 8+ cores ideal |
| **Disk Space** | 160GB | 280GB |
| **Setup Time** | ~1.5 hours | ~2.5 hours |
| **Playbook Time** | ~15 min | ~45 min |
| **Reboot Cycles** | 1-2 | 2-3 |

## Creating Your Custom Variant

### Step 1: Define VMs

Create a new configuration file:
```bash
cp scripts/create-vms.sh scripts/create-vms-custom.sh
# Edit to create your VM set
```

### Step 2: Create Inventory

```bash
cp inventory/hosts-template.ini inventory/hosts-custom.ini
# Edit with your VM details
```

### Step 3: Select Playbooks

```bash
# Run only specific playbooks:
ansible-playbook -i inventory/hosts-custom.ini playbooks/0-preflight.yml
ansible-playbook -i inventory/hosts-custom.ini playbooks/1-domain-setup.yml
ansible-playbook -i inventory/hosts-custom.ini playbooks/2-users-groups.yml
# Skip playbooks you don't need (ADCS, services, etc.)
```

## Variant Comparison: Features

### Core AD Features

| Feature | Light | Full |
|---------|-------|------|
| Domain creation | ✅ | ✅ |
| Users & groups | ✅ | ✅ |
| Group Policy | ✅ | ✅ |
| Kerberos auth | ✅ | ✅ |
| DNS | ✅ | ✅ |
| File shares | ✅ | ✅ |

### Advanced Features

| Feature | Light | Full |
|---------|-------|------|
| Secondary DC | ❌ | ✅ |
| Multi-domain | ❌ | ✅ |
| ADCS (certificates) | ❌ | ✅ |
| SCCM/Exchange | ❌ | ✅ |
| Service accounts | ⚠️ Limited | ✅ |
| Delegation | ⚠️ Limited | ✅ |

## Attack Vectors by Variant

### GOAD Light: What You Can Test

- ✅ Kerberoasting
- ✅ Domain enumeration
- ✅ Lateral movement (basic)
- ✅ Privilege escalation (local)
- ✅ GPO exploitation
- ✅ Unconstrained delegation
- ✅ Weak permissions

### GOAD Full: Additional Vectors

- ✅ All Light attacks
- ✅ Certificate-based attacks (ADCS)
- ✅ Multi-domain attacks
- ✅ Cross-domain delegation
- ✅ Service account hunting
- ✅ More complex privilege paths

## Memory Usage Notes

### During Provisioning

GOAD playbooks can temporarily increase memory usage:

```bash
# Monitor memory on host:
watch -n 1 free -h

# If running out of memory:
# 1. Stop unused VMs
# 2. Increase host RAM
# 3. Reduce VM RAM (not recommended)
```

### Idle VMs

- **Each VM**: ~500 MB - 1 GB RAM (when idle, headless)
- **GOAD Light**: ~2-3 GB total
- **GOAD Full**: ~4-5 GB total

## Migration: Light → Full

If you start with GOAD Light and want to upgrade:

```bash
# Add new VMs to existing setup
bash scripts/create-vms.sh --variant full --add-only-new

# Update inventory with new IPs
vim inventory/hosts.ini

# Configure WinRM on new VMs
# Run provisioning for new VMs only
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --limit dc02,srv03
```

## Recommended Configurations by Use Case

### Pentester Training (Individual)
- **Variant**: GOAD Light
- **Resources**: 8GB RAM, 160GB disk
- **Setup time**: 1.5 hours
- **Daily use**: Exercises, labs, practice

### Security Team (Multiple users)
- **Variant**: GOAD Full (2 instances)
- **Resources**: 32GB RAM, 600GB disk
- **Setup time**: 3-4 hours (parallel)
- **Use**: Shared lab for team training

### Production-Like Testing
- **Variant**: GOAD Full + Custom additions
- **Resources**: 32GB+ RAM, 1TB+ disk
- **Setup time**: 4+ hours
- **Use**: Realistic security testing

---

**Recommendation**: Start with GOAD Light if new to AD. Upgrade to Full once comfortable.
