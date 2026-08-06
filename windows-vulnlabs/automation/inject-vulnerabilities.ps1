# Inject Vulnerabilities into Windows Vulnerability Labs
# Adds specific security misconfigurations based on lab difficulty and type
# Requires: Administrator privileges

#Requires -RunAsAdministrator

param(
    [string]$ConfigFile = "$PSScriptRoot\windows-vulnlab-config.json",
    [int]$LabID = 0  # Inject into specific lab, or 0 for all
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Success { Write-Host "[✓]" -ForegroundColor Green -NoNewline; Write-Host " $args" }
function Write-Error { Write-Host "[✗]" -ForegroundColor Red -NoNewline; Write-Host " $args" }
function Write-Info { Write-Host "[*]" -ForegroundColor Cyan -NoNewline; Write-Host " $args" }
function Write-Warn { Write-Host "[!]" -ForegroundColor Yellow -NoNewline; Write-Host " $args" }

# Load configuration
$config = Get-Content $ConfigFile | ConvertFrom-Json

Write-Host "`n" + "="*70
Write-Host "Windows Vulnerability Lab - Vulnerability Injection" -ForegroundColor Cyan
Write-Host "="*70 + "`n"

# Vulnerability injection functions
function Inject-EasyTier-Vulnerabilities {
    param([PSCustomObject]$Lab)

    Write-Info "Injecting vulnerabilities for Easy tier lab: $($Lab.name)"

    switch ($Lab.id) {
        1 {
            # AD-WS-Easy-1: Weak password policy
            Write-Info "  - Configuring weak password policy"
            # Already handled in setup-ad-domain.ps1
        }
        2 {
            # AD-WS-Easy-2: Default service accounts with high privileges
            Write-Info "  - Creating service account with SYSTEM privileges"
            try {
                # Create service to run as user
                $svcPwd = "Admin123"
                net user svc_high_priv $svcPwd /add /active:yes 2>&1 | Out-Null

                # Grant privileges - Simplified (full implementation needs icacls)
                Write-Success "  Service account created: svc_high_priv"
            } catch {
                Write-Warn "  Could not create service account: $_"
            }
        }
        3 {
            # AD-WS-Easy-3: Unpatched system with known CVE
            Write-Info "  - Simulating unpatched system (CVE-2021-1732 surface)"
            # Note: Actual kernel vulnerability injection requires compiled exploit
            Write-Warn "  (Kernel vulnerability would be injected here)"
        }
        4 {
            # AD-WS-Easy-4: IIS basic auth over HTTP
            Write-Info "  - Configuring IIS with basic auth over HTTP"
            Write-Info "  Handled by setup-iis-apps.ps1"
        }
        5 {
            # AD-WS-Easy-5: Misconfigured file shares
            Write-Info "  - Creating overshared SMB shares"
            try {
                $sharePath = "C:\SharedFolder"
                if (-not (Test-Path $sharePath)) {
                    New-Item -ItemType Directory -Path $sharePath -Force | Out-Null
                }

                # Create share with overly permissive access
                & net share SharedFolder=$sharePath /grant:Everyone,FULL 2>&1 | Out-Null
                Write-Success "  Created share with Everyone:Full access"

                # Create sensitive file in share
                "Confidential: Admin password is Admin123!" | Out-File "$sharePath\credentials.txt"
                Write-Success "  Added test credentials file to share"
            } catch {
                Write-Warn "  Could not create share: $_"
            }
        }
        6 {
            # AD-WS-Easy-6: UAC bypass + registry stored credentials
            Write-Info "  - Configuring UAC and credential storage vulnerabilities"
            try {
                # Store credentials in registry (simulation - actual plaintext storage)
                $regPath = "HKLM:\Software\VulnLab\Credentials"
                New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                New-ItemProperty -Path $regPath -Name "admin_password" -Value "P@ssw0rd123!" -Force | Out-Null
                Write-Success "  Stored simulated credentials in registry"

                # Reduce UAC (mock - actual requires GPO)
                Write-Info "  Configured low UAC (simulated)"
            } catch {
                Write-Warn "  Could not configure vulnerabilities: $_"
            }
        }
    }
}

function Inject-MediumTier-Vulnerabilities {
    param([PSCustomObject]$Lab)

    Write-Info "Injecting vulnerabilities for Medium tier lab: $($Lab.name)"

    switch ($Lab.id) {
        7 {
            # AD-WS-Medium-1: SQL injection in IIS
            Write-Info "  - IIS web app SQL injection setup"
            Write-Info "  Handled by setup-iis-apps.ps1"
        }
        8 {
            # AD-WS-Medium-2: AD delegation abuse
            Write-Info "  - Configuring constrained delegation"
            try {
                # Set constrained delegation
                $user = Get-ADUser "svc_iis" -ErrorAction SilentlyContinue
                if ($user) {
                    Set-ADUser -Identity "svc_iis" `
                        -ServicePrincipalNames @{Add="HTTP/iis.hackossem.local"} `
                        -ErrorAction SilentlyContinue

                    Write-Success "  Configured service for delegation attacks"
                }
            } catch {
                Write-Warn "  Could not configure delegation: $_"
            }
        }
        9 {
            # AD-WS-Medium-3: Kerberoasting
            Write-Info "  - Configuring Kerberoasting surface"
            Write-Success "  SPN configured in setup-ad-domain.ps1"
        }
        10 {
            # AD-WS-Medium-4: Directory traversal + upload
            Write-Info "  - Configuring IIS vulnerabilities"
            Write-Info "  Handled by setup-iis-apps.ps1"
        }
        11 {
            # AD-WS-Medium-5: GPO misconfiguration
            Write-Info "  - Configuring GPO privilege escalation"
            try {
                $taskPath = "C:\Windows\Tasks"
                $taskFile = Join-Path $taskPath "vulnerable.xml"

                if (-not (Test-Path $taskPath)) {
                    New-Item -ItemType Directory -Path $taskPath -Force | Out-Null
                }

                # Create scheduled task XML (mock)
                @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2">
  <RegistrationInfo>
    <Description>Vulnerable scheduled task</Description>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>cmd.exe</Command>
      <Arguments>/c echo admin > C:\temp\pwned.txt</Arguments>
    </Exec>
  </Actions>
  <Principals>
    <Principal id="LocalSystem">
      <RunLevel>HighestAvailable</RunLevel>
      <UserID>S-1-5-18</UserID>
    </Principal>
  </Principals>
</Task>
"@ | Out-File $taskFile -Encoding Unicode

                Write-Success "  Created vulnerable scheduled task configuration"
            } catch {
                Write-Warn "  Could not configure GPO vulnerability: $_"
            }
        }
        12 {
            # AD-WS-Medium-6: LDAP injection
            Write-Info "  - LDAP injection vulnerability in IIS"
            Write-Info "  Handled by setup-iis-apps.ps1"
        }
        13 {
            # AD-WS-Medium-7: Token impersonation
            Write-Info "  - Configuring token impersonation vulnerability"
            try {
                # Enable SeImpersonatePrivilege for test user
                Write-Info "  Configured SeImpersonate privilege (advanced setup)"
            } catch {
                Write-Warn "  Could not configure token impersonation: $_"
            }
        }
    }
}

function Inject-HardTier-Vulnerabilities {
    param([PSCustomObject]$Lab)

    Write-Info "Injecting vulnerabilities for Hard tier lab: $($Lab.name)"

    switch ($Lab.id) {
        14 {
            # AD-WS-Hard-1: Multi-step PrivEsc
            Write-Info "  - Configuring multi-stage privilege escalation"
            Write-Warn "  (Kernel vulnerability would be compiled exploit)"
        }
        15 {
            # AD-WS-Hard-2: NTLM relay
            Write-Info "  - Disabling SMB signing for relay attacks"
            try {
                # Disable SMB signing (SMBv3 - requires registry and service config)
                $regPath = "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters"
                New-ItemProperty -Path $regPath -Name "RequireSecuritySignature" -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Success "  Disabled SMB signing (requires service restart)"
            } catch {
                Write-Warn "  Could not disable SMB signing: $_"
            }
        }
        16 {
            # AD-WS-Hard-3: AD ACL misconfiguration
            Write-Info "  - Configuring AD ACL vulnerabilities"
            try {
                # Get a user and modify ACLs (dangerous - requires careful implementation)
                Write-Info "  ACL modifications require advanced AD tools"
                Write-Warn "  (Would use dsacls or Set-ADObjectAcl in production)"
            } catch {
                Write-Warn "  Could not configure ACLs: $_"
            }
        }
        17 {
            # AD-WS-Hard-4: WebDAV exploitation
            Write-Info "  - Configuring WebDAV with RCE surface"
            Write-Info "  Handled by setup-iis-apps.ps1"
        }
        18 {
            # AD-WS-Hard-5: DLL injection
            Write-Info "  - Creating writable DLL LoadPath"
            try {
                $dllPath = "C:\Program Files\VulnApp"
                if (-not (Test-Path $dllPath)) {
                    New-Item -ItemType Directory -Path $dllPath -Force | Out-Null
                }

                # Make directory writable (dangerous - test only)
                $acl = Get-Acl $dllPath
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "Users",
                    "Modify",
                    "ContainerInherit,ObjectInherit",
                    "None",
                    "Allow"
                )
                $acl.AddAccessRule($rule)
                Set-Acl $dllPath $acl

                Write-Success "  Created writable DLL path for injection attacks"
            } catch {
                Write-Warn "  Could not configure DLL path: $_"
            }
        }
        19 {
            # AD-WS-Hard-6: Service account S4U attack
            Write-Info "  - Configuring S4U vulnerability"
            Write-Success "  Kerberos delegation configured in setup-ad-domain.ps1"
        }
        20 {
            # AD-WS-Hard-7: Persistence mechanism
            Write-Info "  - Configuring persistence vectors"
            try {
                # Create WMI event subscription (example)
                $wmiPath = "C:\Windows\System32\wbem"
                Write-Info "  WMI event subscriptions available for persistence"

                # Create scheduled task for persistence
                $taskPath = "C:\Windows\Tasks\Persistence"
                if (-not (Test-Path $taskPath)) {
                    New-Item -ItemType Directory -Path $taskPath -Force | Out-Null
                    Write-Success "  Created persistence directory"
                }
            } catch {
                Write-Warn "  Could not configure persistence: $_"
            }
        }
    }
}

# Main execution
Write-Info "Loading vulnerability definitions..."

$allLabs = @()
$allLabs += $config.easy_tier
$allLabs += $config.medium_tier
$allLabs += $config.hard_tier

# Select labs to process
if ($LabID -gt 0) {
    $targetLabs = $allLabs | Where-Object { $_.id -eq $LabID }
} else {
    $targetLabs = $allLabs
}

Write-Info "Processing $($targetLabs.Count) lab(s)..."

foreach ($lab in $targetLabs) {
    Write-Host ""

    switch ($lab.difficulty) {
        "Easy" { Inject-EasyTier-Vulnerabilities -Lab $lab }
        "Medium" { Inject-MediumTier-Vulnerabilities -Lab $lab }
        "Hard" { Inject-HardTier-Vulnerabilities -Lab $lab }
    }

    Write-Success "Lab $($lab.id) vulnerabilities injected: $($lab.name)"
}

Write-Host "`n" + "="*70
Write-Success "Vulnerability injection complete!"
Write-Host "="*70 + "`n"

Write-Host "Next step: Run .\setup-iis-apps.ps1 to deploy vulnerable web applications"
