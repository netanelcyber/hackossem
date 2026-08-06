# VulnLabWizard Architecture Discussions

## Overview
This document captures key architectural decisions, design rationale, and technical discussions for VulnLabWizard - an all-in-one Windows vulnerability lab automation platform.

---

## Discussion 1: Single .EXE vs Multiple Tools

**Status**: ✅ DECIDED - Single .EXE approach

### Problem
Need to consolidate multiple PowerShell scripts, configuration files, and UI components into a single deployable artifact for ease of use.

### Decision
Build a single ~15-20MB .EXE file that:
- Embeds all 7 PowerShell scripts as resources
- Embeds all JSON/INI configuration files as resources
- Runs on .NET Framework 4.8+ (pre-installed on Windows 10+)
- Extracts and executes scripts at runtime

### Rationale
- **Ease of Use**: Users only download 1 file, no file distribution headaches
- **Self-Contained**: No external dependencies except VirtualBox
- **Security**: All scripts bundled, verified at build time
- **Portability**: Single .EXE can be copied to any Windows machine

### Trade-offs
- .EXE size ~15-20MB (vs smaller CLI, but worth it for UX)
- Windows-only (acceptable given Windows Server 2022 target)
- .NET Framework required (ubiquitous on Windows 10+)

### Alternative Considered
- Separate PowerShell modules + standalone UI - rejected due to deployment complexity
- Docker/WSL approach - rejected, breaks VirtualBox integration

---

## Discussion 2: Flexible Resource Allocation (Addressing 40GB RAM Issue)

**Status**: ✅ DECIDED - Tiered deployment strategy

### Problem
Initial system requirements stated "40GB+ free RAM" which is prohibitive for most users. User feedback: "40GB+ free RAM ?????"

### Decision
Implement flexible deployment with three tiers:
1. **Minimum (5 labs)**: 10GB RAM + 50GB disk
2. **Recommended (20 labs)**: 20GB RAM + 200GB disk with sequential strategy
3. **Full Simultaneous (20 labs)**: 40GB+ RAM for all VMs running concurrently

### Implementation
- **Lab Count Selection**: Users choose 5, 10, 15, or 20 labs
- **RAM Per-VM Slider**: 1-4GB configurable (default 2GB)
- **Deployment Strategy**: Sequential (lower RAM) or Simultaneous (faster)
- **Sequential Strategy RAM Calculation**: Only 2 VMs at a time = (2 × RAM per VM) total needed

### Rationale
- **Inclusivity**: Allows deployment on consumer-grade hardware (10GB RAM laptops)
- **Flexibility**: Organizations can scale based on resources
- **Education**: Students can start with 5 Easy labs, progress to 20
- **Real-world**: Most educational use cases don't need all 20 simultaneous

### Example Scenarios
| Scenario | Labs | RAM/VM | Strategy | Total RAM | Hardware |
|----------|------|--------|----------|-----------|----------|
| Student (limited resources) | 5 | 1GB | Sequential | 2GB | Laptop |
| Lab instructor | 10 | 2GB | Sequential | 4GB | Desktop |
| CTF competition | 20 | 2GB | Sequential | 4GB | Any modern PC |
| Research (all simultaneous) | 20 | 2GB | Simultaneous | 40GB | Server |

---

## Discussion 3: Multi-Mode Architecture (Instructor/Student/Admin/Auto)

**Status**: ✅ DECIDED - Four distinct operating modes

### Design
```
VulnLabWizard.exe
├─ Instructor Mode      → Deploy labs from scratch or OVA
├─ Student Mode         → Access and exploit labs
├─ Admin Mode           → Team setup, maintenance, snapshots
└─ Automated Mode       → CI/CD silent deployment
```

### Rationale
- **User Role Separation**: Different UX for different personas
- **Security**: Instructor features hidden from students
- **Scalability**: Automated mode enables bulk provisioning
- **Simplicity**: Each mode focuses on one workflow

### Mode Details

#### Instructor Mode (Phases 1-2)
- 5-step wizard for end-to-end setup
- Environment validation
- Flexible deployment configuration
- Real-time progress tracking
- Completion summary with network details

#### Student Mode (Phase 3)
- Lab dashboard showing all 20 labs
- Start/Stop/Reset controls per lab
- One-click RDP connection
- View credentials and exploitation guides
- No deployment capabilities (read-only)

#### Admin Mode (Phase 4)
- VM cloning for team exercises
- Snapshot management (backup/restore)
- Team set creation (isolated networks)
- Maintenance operations (cleanup, updates)
- Audit logging for all operations

#### Automated Mode (Phase 5)
- Command-line interface
- JSON configuration file support
- Silent execution (no UI)
- CI/CD integration (exit codes, logging)
- Examples: GitHub Actions, Jenkins, Azure DevOps

---

## Discussion 4: PowerShell Script Embedding & Execution

**Status**: ✅ DECIDED - Embed scripts as resources, extract at runtime

### Decision
Store PowerShell scripts in .csproj as `<EmbeddedResource>`:
```xml
<EmbeddedResource Include="Resources\Create-VMs.ps1" />
<EmbeddedResource Include="Resources\Deploy-AD.ps1" />
<!-- ... 7 total scripts ... -->
```

Extract and execute via ScriptExecutor.cs at runtime.

### Rationale
- **Distribution**: Single .EXE contains everything
- **Versioning**: Scripts version with application build
- **Audit**: All scripts present and verified at build time
- **Security**: No file-based script injection attacks

### Script Execution Flow
```
User clicks "Next" in Wizard
    ↓
WizardForm calls ScriptExecutor.ExecuteScript()
    ↓
ScriptExecutor extracts script from resources to %TEMP%
    ↓
ScriptExecutor spawns powershell.exe with script
    ↓
Real-time output captured and displayed in UI log
    ↓
Exit code and final status logged
```

### Parameters Passed to Scripts
All scripts support flexible deployment parameters:
- `$LabCount`: Number of labs (5, 10, 15, 20)
- `$MemoryGB`: Per-VM RAM (1-4GB)
- `$IsSequential`: Deployment strategy (true/false)

---

## Discussion 5: VirtualBox Integration Strategy

**Status**: ✅ DECIDED - VBoxManage command-line wrapper

### Design
VirtualBoxService.cs wraps VBoxManage CLI:
```csharp
public bool CreateVM(string vmName, int memoryMB, int cpuCount)
{
    ProcessStartInfo psi = new ProcessStartInfo("VBoxManage", 
        $"createvm --name \"{vmName}\" --ostype Windows2022_64 --register");
    // Execute and capture output
}
```

### Rationale
- **No SDK Dependency**: VBoxManage available on all VirtualBox installations
- **Subprocess Isolation**: VirtualBox operations don't crash .NET app
- **Output Capture**: Parse VBoxManage output for status updates
- **Error Handling**: Non-zero exit codes indicate failures

### Alternative Considered
- VirtualBox SOAP API - requires daemon, adds complexity
- Direct COM automation - Windows-only, brittle
- VirtualBox SDK - language binding maintenance burden

### Supported Operations
- Create VM: `VBoxManage createvm`
- Start VM: `VBoxManage startvm`
- Stop VM: `VBoxManage controlvm poweroff`
- Clone VM: `VBoxManage clonevm`
- Snapshot: `VBoxManage snapshot`

---

## Discussion 6: Lab Configuration: Static vs Dynamic

**Status**: ✅ DECIDED - Static lab-config.json with runtime flexibility

### Design
lab-config.json contains static definitions of all 20 labs:
```json
{
  "labs": [
    {
      "id": "Easy-1",
      "name": "Weak Password Policy",
      "difficulty": "Easy",
      "vmName": "VulnLab-ad-lab-1",
      "ipAddress": "192.168.56.100",
      "rdpPort": 5100,
      "winrmPort": 2100,
      "vulnerabilityType": "Credential Theft"
    },
    // ... 19 more labs ...
  ]
}
```

Flexible deployment allows:
- Deploying subset of labs (5, 10, 15, or 20)
- Adjusting IPs and ports dynamically
- Configurable domain and network ranges

### Rationale
- **Predictability**: Lab IDs and vulnerabilities known upfront
- **Consistency**: Same lab definition across deployments
- **Simplicity**: JSON is human-readable and version-controllable
- **Extensibility**: New labs can be added by editing JSON

---

## Discussion 7: Sequential vs Simultaneous Deployment

**Status**: ✅ DECIDED - Both strategies supported, sequential default

### Sequential Strategy (Default)
```
Deploy VM 1 → Wait 5s → Deploy VM 2 → Wait 5s → ... → Deploy VM 20
RAM Required: 2GB (2 VMs at a time) × 2 = 4GB
Time: ~90 minutes for 20 labs
Suitable for: Laptops, limited RAM systems
```

### Simultaneous Strategy
```
Deploy VMs 1-20 in parallel
RAM Required: 20 VMs × 2GB = 40GB
Time: ~30 minutes for 20 labs
Suitable for: Servers, high-end workstations
```

### Implementation
Create-VMs.ps1 accepts `-IsSequential` parameter:
```powershell
if ($IsSequential -and $counter -lt $LabCount) {
    Start-Sleep -Seconds 5  # Delay between VM creation
}
```

### Rationale
- **Default Sequential**: Most users have limited RAM (10-20GB)
- **Optional Simultaneous**: Power users can choose speed over resources
- **Adaptive**: Same script supports both strategies
- **User Control**: UI slider lets users pick strategy based on hardware

---

## Discussion 8: Error Handling & Recovery

**Status**: ✅ DECIDED - Graceful degradation approach

### Strategy
1. **Validation First**: Check prerequisites before deployment starts
2. **Early Exit**: Stop deployment if critical checks fail
3. **Graceful Degradation**: Non-critical failures don't halt deployment
4. **Logging**: All errors logged with timestamps and context
5. **User Feedback**: Clear error messages, actionable suggestions

### Example
```csharp
// Critical error - stop
if (!validator.ValidateEnvironment()) 
    return false; // Stop deployment

// Non-critical - warn and continue
if (!executor.ExecuteScript("Deploy-IIS.ps1", ""))
    LogMessage("⚠ IIS deployment encountered issues (may continue)");
```

### Error Categories
| Category | Severity | Action |
|----------|----------|--------|
| VirtualBox not installed | Critical | Stop deployment |
| Insufficient disk space | Critical | Stop deployment |
| Insufficient RAM | Critical | Stop deployment |
| VM creation fails | Critical | Stop deployment |
| AD deployment fails | Warning | Continue (recoverable) |
| IIS deployment fails | Warning | Continue (not essential) |
| Validation fails | Warning | Continue (informational) |

---

## Discussion 9: Security Considerations

**Status**: ✅ DECIDED - Defense-in-depth approach

### Decisions
1. **Admin Check**: Application requires Administrator privileges
   - Rationale: VirtualBox/Hyper-V operations require elevated rights
   - User is warned at startup

2. **Default Credentials**: Hardcoded for educational environment
   - `Administrator` / `P@ssw0rd!2024`
   - Rationale: CTF/educational context, not production
   - Can be changed during setup

3. **Network Isolation**: Host-only network (192.168.56.0/24)
   - Rationale: Labs isolated from production networks
   - No internet access by default

4. **Logging**: All operations logged with timestamps
   - Rationale: Audit trail for troubleshooting
   - Log file location configurable

5. **Script Verification**: Scripts embedded at build time
   - Rationale: No runtime script injection attacks
   - Scripts cannot be modified after build

### Not Addressed (Future)
- RBAC for student access control
- Network encryption (host-only is sufficient)
- Credential rotation policies
- Multi-tenancy isolation

---

## Discussion 10: Testing Strategy

**Status**: ✅ DECIDED - Multi-level testing approach

### Unit Testing
- EnvironmentValidator: Correctly identifies missing dependencies
- LabConfig: JSON parsing works correctly
- ScriptExecutor: PowerShell output capture accurate
- VirtualBoxService: VBoxManage command construction correct

### Integration Testing
- Wizard flow: Mode selection → Validation → Config → Deploy → Summary
- Student dashboard: Lab selection → Details → Controls
- Admin utilities: Clone, snapshot, team operations
- Automated mode: JSON config parsing, silent execution

### Deployment Testing
- **Smoke Test**: Deploy 2 Easy labs, verify RDP connectivity
- **Full Test**: Deploy all 20 labs, verify network configuration
- **OVA Import**: Import pre-built template, verify network reconfiguration

### Platforms
- Windows 10 (latest)
- Windows 11
- Windows Server 2019+
- Windows Server 2022 (primary)

---

## Discussion 11: Documentation Strategy

**Status**: ✅ DECIDED - Multi-level documentation

### User Documentation
- **README.md**: Quick start, system requirements, installation
- **QUICKSTART.md**: Step-by-step for first-time users
- **Exploitation Guides**: Per-lab walkthrough (PDF/Markdown)

### Developer Documentation
- **ARCHITECTURE.md**: System design overview
- **DISCUSSIONS.md**: Design rationale (this file)
- **Code Comments**: "Why" not "What" (for non-obvious decisions)

### Operational Documentation
- **Troubleshooting.md**: Common issues and solutions
- **Network Config**: Network topology and port mapping
- **Team Setup Guide**: Creating team sets and credentials

---

## Discussion 12: Future Extensibility

**Status**: 🔄 FUTURE CONSIDERATION - Design for growth

### Planned Extensions
1. **Custom Lab Templates**: Allow adding new 20-lab sets
2. **Advanced Networking**: Multi-lab network scenarios
3. **Cloud Integration**: Deploy to AWS/Azure instead of local VMs
4. **RBAC System**: Role-based access control for teams
5. **Metrics/Analytics**: Exploitation success rates, lab engagement

### Design Decisions for Future
- LabConfig.cs designed to support multiple lab sets
- VirtualBoxService abstracted (could swap for CloudProvider)
- Deployment State tracking enables progress serialization
- Logging system extensible to cloud logging services

---

## Conclusion

VulnLabWizard balances **simplicity** (single .EXE, wizard-based UI) with **flexibility** (multiple deployment strategies, configurable resources). Design prioritizes:

1. **User Experience**: Intuitive multi-mode interface
2. **Accessibility**: Works on consumer-grade hardware (10GB RAM)
3. **Automation**: Supports CI/CD and bulk provisioning
4. **Reliability**: Graceful error handling and recovery
5. **Security**: Defense-in-depth for educational environment

All decisions documented here should be referenced when:
- Adding new features
- Making architectural changes
- Onboarding new contributors
- Debugging unexpected behavior

---

**Last Updated**: August 6, 2026  
**Status**: Phase 1-3 Complete, Phases 4-5 In Progress  
**Maintainer**: Claude Code
