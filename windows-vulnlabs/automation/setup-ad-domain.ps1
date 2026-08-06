# Active Directory Domain Setup for Windows Vulnerability Labs
# Creates AD forest, domain structure, user accounts, and GPO misconfigurations
# Requires: Administrator privileges on Windows Server 2022

#Requires -RunAsAdministrator

param(
    [string]$ConfigFile = "$PSScriptRoot\windows-vulnlab-config.json",
    [string]$LabRange = "1,20"  # Format: "start,end" or single number
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Success { Write-Host "[✓]" -ForegroundColor Green -NoNewline; Write-Host " $args" }
function Write-Error { Write-Host "[✗]" -ForegroundColor Red -NoNewline; Write-Host " $args" }
function Write-Info { Write-Host "[*]" -ForegroundColor Cyan -NoNewline; Write-Host " $args" }
function Write-Warn { Write-Host "[!]" -ForegroundColor Yellow -NoNewline; Write-Host " $args" }

# Load configuration
$config = Get-Content $ConfigFile | ConvertFrom-Json
$domain = $config.global_config.domain
$netBIOS = "HACKOSSEM"

Write-Host "`n" + "="*70
Write-Host "Active Directory Domain Setup" -ForegroundColor Cyan
Write-Host "="*70 + "`n"

Write-Info "Domain: $domain"
Write-Info "NetBIOS: $netBIOS"

# Check if AD is already installed
Write-Info "Checking if Active Directory is installed..."
$adFeature = Get-WindowsFeature -Name AD-Domain-Services -ErrorAction SilentlyContinue
if (-not $adFeature.Installed) {
    Write-Info "Installing Active Directory Domain Services..."
    Install-WindowsFeature -Name AD-Domain-Services, RSAT-AD-AdminCenter -IncludeManagementTools | Out-Null
    Write-Success "Active Directory installed"
}

# Check if forest already exists
Write-Info "Checking for existing AD forest..."
$adForest = Get-ADForest -ErrorAction SilentlyContinue
if ($adForest) {
    Write-Warn "AD forest already exists: $($adForest.Name)"
    Write-Info "Skipping forest creation. Using existing domain: $domain"
} else {
    Write-Info "Creating AD forest: $domain"
    try {
        Install-ADDSForest -DomainName $domain `
            -DomainNetbiosName $netBIOS `
            -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!Forest" -AsPlainText -Force) `
            -InstallDns `
            -NoRebootOnCompletion `
            -Force | Out-Null

        Write-Success "AD forest created: $domain"
    } catch {
        Write-Warn "Forest creation issue: $_"
    }
}

# Wait for AD to be available
Write-Info "Waiting for Active Directory to be ready..."
$attempts = 0
while ($attempts -lt 30) {
    try {
        $null = Get-ADDomain -ErrorAction Stop
        break
    } catch {
        Start-Sleep -Seconds 2
        $attempts++
    }
}

if ($attempts -ge 30) {
    Write-Error "Active Directory not responding after 60 seconds"
    exit 1
}

Write-Success "Active Directory is ready"

# Create OUs for organization
Write-Info "`nCreating Organizational Units..."
$ous = @("Easy", "Medium", "Hard")

foreach ($ou in $ous) {
    try {
        $ouPath = "OU=$ou,DC=$($netBIOS.ToLower()),DC=local"
        Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop | Out-Null
        Write-Warn "OU already exists: $ou"
    } catch {
        try {
            New-ADOrganizationalUnit -Name $ou -Path "DC=$($netBIOS.ToLower()),DC=local" | Out-Null
            Write-Success "Created OU: $ou"
        } catch {
            Write-Warn "Could not create OU $ou : $_"
        }
    }
}

# Create vulnerable user accounts
Write-Info "`nCreating vulnerable user accounts..."

$vulnerableUsers = @(
    @{ Name = "admin"; Password = "Admin123"; Description = "Weak admin account"; OU = "Easy" },
    @{ Name = "guest"; Password = "Guest"; Description = "Weak guest account"; OU = "Easy" },
    @{ Name = "svc_admin"; Password = "Admin123"; Description = "Service account - high privileges"; OU = "Easy" },
    @{ Name = "svc_iis"; Password = "IIS2022!"; Description = "IIS service account"; OU = "Medium" },
    @{ Name = "domain_user"; Password = "Password123"; Description = "Standard domain user"; OU = "Easy" },
    @{ Name = "kerberoast_target"; Password = "VulnPass2022"; Description = "Kerberoasting target"; OU = "Medium" },
    @{ Name = "asrep_target"; Password = "AsRepPass123"; Description = "AS-REP roasting target"; OU = "Medium" },
    @{ Name = "token_theft"; Password = "TokenTheft123"; Description = "Token impersonation target"; OU = "Medium" },
    @{ Name = "acl_victim"; Password = "ACLVuln123"; Description = "ACL abuse victim"; OU = "Hard" },
    @{ Name = "s4u_service"; Password = "S4UService123"; Description = "Service account for S4U"; OU = "Hard" }
)

foreach ($user in $vulnerableUsers) {
    try {
        $ouPath = "OU=$($user.OU),DC=$($netBIOS.ToLower()),DC=local"
        $userPath = "CN=$($user.Name),$ouPath"

        Get-ADUser -Identity $user.Name -ErrorAction Stop | Out-Null
        Write-Warn "User already exists: $($user.Name)"
    } catch {
        try {
            $pwd = ConvertTo-SecureString $user.Password -AsPlainText -Force
            New-ADUser -Name $user.Name `
                -SamAccountName $user.Name `
                -UserPrincipalName "$($user.Name)@$domain" `
                -AccountPassword $pwd `
                -Enabled $true `
                -Path "OU=$($user.OU),DC=$($netBIOS.ToLower()),DC=local" `
                -Description $user.Description `
                -PasswordNotRequired $false | Out-Null

            Write-Success "Created user: $($user.Name) (OU: $($user.OU))"
        } catch {
            Write-Warn "Could not create user $($user.Name) : $_"
        }
    }
}

# Create service accounts and configure SPNs
Write-Info "`nConfiguring service accounts..."

try {
    $svcAccount = Get-ADUser -Identity "svc_iis" -ErrorAction Stop

    # Set SPN for Kerberoasting
    $spn = "HTTP/iis.hackossem.local"
    Get-ADUser -Identity "svc_iis" -Properties servicePrincipalName | ForEach-Object {
        if (-not $_.servicePrincipalName -contains $spn) {
            Set-ADUser -Identity "svc_iis" -ServicePrincipalNames @{Add=$spn} -ErrorAction SilentlyContinue
            Write-Success "Set SPN for svc_iis: $spn"
        }
    }
} catch {
    Write-Warn "Could not configure SPNs: $_"
}

# Configure Kerberos preauth vulnerability (AS-REP roasting)
Write-Info "`nConfiguring Kerberos vulnerabilities..."
try {
    $asrepUser = Get-ADUser -Identity "asrep_target" -ErrorAction Stop
    Set-ADAccountControl -Identity "asrep_target" -DoesNotRequirePreAuth $true -ErrorAction SilentlyContinue
    Write-Success "Disabled preauth for asrep_target (AS-REP roasting vulnerability)"
} catch {
    Write-Warn "Could not configure AS-REP roasting: $_"
}

# Configure delegation for S4U attacks
Write-Info "`nConfiguring Kerberos delegation vulnerabilities..."
try {
    $s4uService = Get-ADUser -Identity "s4u_service" -ErrorAction Stop
    Set-ADUser -Identity "s4u_service" -TrustedForDelegation $true -ErrorAction SilentlyContinue
    Write-Success "Enabled delegation for s4u_service"
} catch {
    Write-Warn "Could not enable delegation: $_"
}

# Configure weak password policy
Write-Info "`nConfiguring weak domain password policy (Easy tier vulnerability)..."
try {
    $defaultPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop
    Set-ADDefaultDomainPasswordPolicy `
        -Identity "CN=Default Password Policy,CN=Password Settings Container,CN=System,DC=$($netBIOS.ToLower()),DC=local" `
        -MinPasswordLength 4 `
        -MaxPasswordAge 999 `
        -PasswordHistoryCount 1 `
        -LockoutThreshold 0 `
        -ErrorAction SilentlyContinue

    Write-Success "Set weak password policy: min 4 chars, 999-day expiration"
} catch {
    Write-Warn "Could not modify password policy: $_"
}

# Enable WinRM for remote PowerShell access
Write-Info "`nEnabling WinRM for remote management..."
try {
    $winrmService = Get-Service WinRM -ErrorAction SilentlyContinue
    if ($winrmService.Status -ne "Running") {
        Start-Service WinRM
        Write-Success "WinRM service started"
    }

    # Enable all listeners
    & winrm quickconfig -quiet -force 2>&1 | Out-Null
    Write-Success "WinRM configured"
} catch {
    Write-Warn "Could not configure WinRM: $_"
}

# Create Groups for privilege escalation
Write-Info "`nCreating groups for privilege escalation chains..."
try {
    $delegatedAdmins = Get-ADGroup -Identity "Delegated Admins" -ErrorAction SilentlyContinue
} catch {
    try {
        New-ADGroup -Name "Delegated Admins" `
            -GroupScope DomainLocal `
            -Path "CN=Builtin,DC=$($netBIOS.ToLower()),DC=local" `
            -Description "Users who can elevate via delegation" | Out-Null

        Write-Success "Created group: Delegated Admins"
    } catch {
        Write-Warn "Could not create group: $_"
    }
}

Write-Host "`n" + "="*70
Write-Success "Active Directory domain setup complete!"
Write-Host "="*70 + "`n"

Write-Host "Domain Summary:"
Write-Host "  Domain: $domain"
Write-Host "  Forest: $(Get-ADForest -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)"
Write-Host "  Users created: $(Get-ADUser -Filter * -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host ""
Write-Host "Next step: Run .\inject-vulnerabilities.ps1 to add specific security vulnerabilities"
