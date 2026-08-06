# Windows Server 2022 Vulnerability Lab Platform

**20 penetration testing training labs** with Active Directory, intentional security vulnerabilities, and IIS web applications.

Perfect for learning and practicing:
- Active Directory exploitation
- Kerberos attacks
- Windows privilege escalation
- Web application penetration testing
- Red team techniques
- Defense and incident response

## Quick Start

### 1. Prerequisites
```powershell
# Install VirtualBox 7.0+
# Download Windows Server 2022 ISO
# Run PowerShell as Administrator
```

### 2. Create VMs (15-30 minutes)
```powershell
cd windows-vulnlabs/automation/
.\create-windows-vulnlabs.ps1 -Win2022ISO "C:\ISO\Windows2022.iso"
```

### 3. Setup Domain
```powershell
# Install Windows on each VM first (via ISO)
# Then run:
.\setup-ad-domain.ps1
```

### 4. Inject Vulnerabilities
```powershell
.\inject-vulnerabilities.ps1
.\setup-iis-apps.ps1
.\validate-vulnerabilities.ps1
```

### 5. Start Testing
See **Exploitation Guides** below for attack walkthroughs.

## Lab Structure

### 20 Labs Organized by Difficulty

**Easy Tier (6 labs)** - Single-step exploitations
- Weak password policy
- Default service accounts
- Unpatched systems
- Basic auth over HTTP
- Overshared SMB folders
- UAC bypass

**Medium Tier (7 labs)** - Attack chaining required
- SQL injection in web apps
- Kerberos delegation abuse
- Kerberoasting
- Directory traversal + upload
- GPO misconfiguration
- LDAP injection
- Token impersonation

**Hard Tier (7 labs)** - Advanced multi-stage attacks
- Kernel exploit chains
- NTLM relay attacks
- AD ACL abuse
- WebDAV RCE
- DLL injection
- Kerberos S4U attacks
- Persistence mechanisms

## Resources

### Setup & Configuration
- [Complete Setup Guide](./docs/WINDOWS_VULNLAB_SETUP.md) - Detailed deployment walkthrough
- [Configuration](./automation/windows-vulnlab-config.json) - Machine definitions and settings

### Exploitation Guides
- [Easy Tier Guide](./docs/windows-vulnlab-easy.md)
- [Medium Tier Guide](./docs/windows-vulnlab-medium.md)
- [Hard Tier Guide](./docs/windows-vulnlab-hard.md)
- [Full Penetesting Guide](./docs/WINDOWS_VULNLAB_PENETESTING_GUIDE.md)

### Lab Index
- [Quick Reference](./docs/INDEX.md) - All labs at a glance
- [Credentials File](./docs/WINDOWS_VULNLAB_CREDENTIALS.md) - Access information (git-ignored)

## Features

✅ **20 Distinct Labs** - Varied vulnerabilities across all tiers
✅ **Active Directory** - Full hackossem.local domain with OUs
✅ **Web Vulnerabilities** - SQL injection, file upload, LDAP injection
✅ **Windows-native** - PowerShell + VBoxManage automation
✅ **Penetration Testing** - Real exploitation paths, not CTF-style flags
✅ **Difficulty Progression** - Easy → Medium → Hard learning path
✅ **Isolated Environment** - Host-only networking for safety
✅ **Team-ready** - Clone and customize for group exercises

## System Requirements

### Minimum (5 labs)
- 32GB RAM
- 300GB disk
- 4-core CPU

### Recommended (20 labs)
- 96GB+ RAM  
- 1.2TB+ disk
- 8+ core CPU

### Per-VM
- 4GB RAM
- 2 CPUs
- 60GB disk

## Automation Scripts

Located in `automation/`:

| Script | Purpose |
|--------|---------|
| `create-windows-vulnlabs.ps1` | VM creation via VBoxManage |
| `setup-ad-domain.ps1` | Active Directory forest + domain |
| `inject-vulnerabilities.ps1` | Add security misconfigurations |
| `setup-iis-apps.ps1` | Deploy vulnerable web apps |
| `validate-vulnerabilities.ps1` | Verify all vulnerabilities present |
| `cleanup-windows-vulnlabs.ps1` | Safe VM deletion |

## Lab Machines

```
192.168.56.100-105   Easy Tier (6 labs)
192.168.56.106-112   Medium Tier (7 labs)
192.168.56.113-119   Hard Tier (7 labs)

Ports:
2100-2119            WinRM (5985)
5100-5119            RDP (3389)
```

## Usage Examples

### Single Lab Testing
```powershell
# Start and RDP into lab 1
VBoxManage startvm "AD-WS-Easy-1" --type headless
mstsc /v:localhost:5100
```

### Team Exercise
```powershell
# Clone lab for team member
VBoxManage clonevm "AD-WS-Easy-1" --name "Lab-Team-B" --register

# Deploy multiple labs for class
.\create-windows-vulnlabs.ps1 -StartLab 1 -EndLab 6  # Easy tier only
```

### Rapid Testing
```powershell
# Snapshot before each test
VBoxManage snapshot "AD-WS-Easy-1" take "before-test"

# Restore after exploitation
VBoxManage snapshot "AD-WS-Easy-1" restore "before-test"
```

## Attack Paths

### Easy Tier Example: Weak Password Policy (Lab 1)
1. Enumerate AD users
2. Perform password spraying
3. Capture valid credentials
4. Gain initial access

### Medium Tier Example: Kerberoasting (Lab 9)
1. Identify service accounts with SPNs
2. Request service tickets
3. Crack passwords offline
4. Escalate privileges

### Hard Tier Example: NTLM Relay (Lab 15)
1. Disable SMB signing
2. Setup NTLM relay
3. Force authentication via WebDAV
4. Relay to LDAP/SMB
5. Modify AD objects or access files

## Integration with hackossem Platform

These labs integrate with the main hackossem project:
- Added to VulnLab API mock data
- Accessible via `/api/vulnlab/ad-labs` endpoint
- Filterable by difficulty and vulnerability type
- Part of broader 110+ lab platform

## Security Considerations

⚠️ **CRITICAL:** These labs contain **intentional vulnerabilities**.

- 🔒 Only run in **isolated environments**
- 🔒 Use **host-only networking**
- 🔒 Take **snapshots** before testing
- 🔒 **Never** expose to internet
- 🔒 **Don't reuse** credentials in production
- 🔒 Clean up with **cleanup-windows-vulnlabs.ps1**

## Learning Path

### Week 1-2: Easy Tier
- Labs 1-6: Basic Windows exploitation
- Focus: Credential attacks, weak configurations
- Skills: Enumeration, password attacks, basic privilege escalation

### Week 3-4: Medium Tier
- Labs 7-13: AD and chained attacks
- Focus: Kerberos, web apps, delegation
- Skills: Attack chaining, ticket analysis, web exploitation

### Week 5+: Hard Tier
- Labs 14-20: Advanced red team scenarios
- Focus: NTLM relay, kernel exploits, persistence
- Skills: Multi-stage attacks, evasion, persistence mechanisms

## Troubleshooting

**Q: VMs won't boot from ISO?**
```powershell
VBoxManage modifyvm "AD-WS-Easy-1" --boot1 dvd --boot2 disk
```

**Q: WinRM not working?**
```powershell
# On VM:
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
```

**Q: Vulnerability not present?**
```powershell
.\inject-vulnerabilities.ps1 -LabID 3
```

See [WINDOWS_VULNLAB_SETUP.md](./docs/WINDOWS_VULNLAB_SETUP.md) for detailed troubleshooting.

## Contributing

Found a bug or want to add a vulnerability? Contributions welcome!

1. Test in isolated environment
2. Document the vulnerability
3. Add to appropriate tier (Easy/Medium/Hard)
4. Update exploitation guide
5. Submit with clear exploitation path

## License

Part of the hackossem project. See root LICENSE file.

## Support

- Issues: [GitHub Issues](https://github.com/netanelcyber/hackossem/issues)
- Documentation: [Docs Directory](./docs/)
- Main Project: [HackOSSEM Repository](https://github.com/netanelcyber/hackossem)

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready  
**Last Updated**: 2026-08-06

**Next Step**: Read [WINDOWS_VULNLAB_SETUP.md](./docs/WINDOWS_VULNLAB_SETUP.md) for complete deployment guide.
