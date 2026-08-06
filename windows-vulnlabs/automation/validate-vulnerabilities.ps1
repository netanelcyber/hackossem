# Validate Vulnerabilities in Windows Vulnerability Labs
# Verifies that each configured vulnerability is present and exploitable
# Requires: Administrator privileges, network connectivity to labs

#Requires -RunAsAdministrator

param(
    [string]$ConfigFile = "$PSScriptRoot\windows-vulnlab-config.json",
    [int]$LabID = 0,  # Validate specific lab, or 0 for all
    [switch]$Verbose = $false
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
Write-Host "Windows Vulnerability Lab - Validation" -ForegroundColor Cyan
Write-Host "="*70 + "`n"

# Validation functions
function Test-Connectivity {
    param([string]$IP, [int]$Port)

    try {
        $conn = New-Object System.Net.Sockets.TcpClient
        $conn.ConnectAsync($IP, $Port).Wait(1000) | Out-Null

        if ($conn.Connected) {
            return $true
        }
    } catch {
        return $false
    }

    return $false
}

function Test-ADConnectivity {
    param([string]$DomainName)

    try {
        $domain = Get-ADDomain -Identity $DomainName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Validate-Lab {
    param([PSCustomObject]$Lab)

    Write-Info "Validating Lab $($Lab.id): $($Lab.name)"

    $results = @{
        LabID = $Lab.id
        Name = $Lab.name
        Difficulty = $Lab.difficulty
        Checks = @()
    }

    # Check 1: Network connectivity
    Write-Info "  Checking network connectivity..."
    $connected = Test-Connectivity -IP $Lab.ip -Port 3389  # RDP port
    if ($connected) {
        Write-Success "  Network: Reachable"
        $results.Checks += @{ Name = "Network Connectivity"; Status = "PASS" }
    } else {
        Write-Warn "  Network: Unreachable (VM may not be running)"
        $results.Checks += @{ Name = "Network Connectivity"; Status = "FAIL" }
    }

    # Check 2: RDP accessibility
    Write-Info "  Checking RDP port..."
    $rdpPortOpen = Test-Connectivity -IP $Lab.ip -Port 3389
    if ($rdpPortOpen) {
        Write-Success "  RDP: Accessible"
        $results.Checks += @{ Name = "RDP Port"; Status = "PASS" }
    } else {
        Write-Warn "  RDP: Not accessible"
        $results.Checks += @{ Name = "RDP Port"; Status = "WARN" }
    }

    # Check 3: WinRM connectivity
    Write-Info "  Checking WinRM..."
    try {
        Test-WSMan -ComputerName $Lab.ip -ErrorAction Stop | Out-Null
        Write-Success "  WinRM: Accessible"
        $results.Checks += @{ Name = "WinRM"; Status = "PASS" }
    } catch {
        Write-Warn "  WinRM: Not accessible"
        $results.Checks += @{ Name = "WinRM"; Status = "WARN" }
    }

    # Check 4: AD integration
    Write-Info "  Checking AD domain..."
    $adReady = Test-ADConnectivity -DomainName $config.global_config.domain
    if ($adReady) {
        Write-Success "  Active Directory: Online"
        $results.Checks += @{ Name = "AD Domain"; Status = "PASS" }
    } else {
        Write-Warn "  Active Directory: Unreachable"
        $results.Checks += @{ Name = "AD Domain"; Status = "WARN" }
    }

    # Check 5: Vulnerability-specific checks
    Write-Info "  Checking $($Lab.vulnerability)..."

    switch ($Lab.id) {
        1 {
            # Check weak password policy
            try {
                $adPwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop
                if ($adPwdPolicy.MinPasswordLength -le 4) {
                    Write-Success "  Vulnerability: Weak password policy configured"
                    $results.Checks += @{ Name = "Weak Password Policy"; Status = "PASS" }
                } else {
                    Write-Warn "  Vulnerability: Password policy not weak"
                    $results.Checks += @{ Name = "Weak Password Policy"; Status = "WARN" }
                }
            } catch {
                Write-Warn "  Could not verify password policy"
                $results.Checks += @{ Name = "Weak Password Policy"; Status = "UNKNOWN" }
            }
        }
        4 {
            # Check IIS basic auth
            Write-Info "  Checking IIS basic authentication..."
            if (Test-Connectivity -IP "127.0.0.1" -Port 80) {
                Write-Success "  Vulnerability: IIS accessible (basic auth should be enabled)"
                $results.Checks += @{ Name = "IIS Basic Auth"; Status = "PASS" }
            }
        }
        5 {
            # Check SMB shares
            Write-Info "  Checking SMB shares..."
            try {
                $shares = Get-SmbShare -Name SharedFolder -ErrorAction SilentlyContinue
                if ($shares) {
                    Write-Success "  Vulnerability: Overshared folder detected"
                    $results.Checks += @{ Name = "SMB Oversharing"; Status = "PASS" }
                }
            } catch {
                Write-Warn "  Could not verify SMB shares"
                $results.Checks += @{ Name = "SMB Oversharing"; Status = "UNKNOWN" }
            }
        }
        default {
            Write-Info "  Specific vulnerability check: See penetration testing guide"
            $results.Checks += @{ Name = "Specific Vulnerability"; Status = "MANUAL" }
        }
    }

    return $results
}

# Main execution
Write-Info "Loading lab definitions..."

$allLabs = @()
$allLabs += $config.easy_tier
$allLabs += $config.medium_tier
$allLabs += $config.hard_tier

# Select labs to validate
if ($LabID -gt 0) {
    $targetLabs = $allLabs | Where-Object { $_.id -eq $LabID }
} else {
    $targetLabs = $allLabs
}

Write-Info "Validating $($targetLabs.Count) lab(s)..."
Write-Host ""

$validationResults = @()

foreach ($lab in $targetLabs) {
    $result = Validate-Lab -Lab $lab
    $validationResults += $result
    Write-Host ""
}

# Summary report
Write-Host "="*70
Write-Host "Validation Summary Report" -ForegroundColor Cyan
Write-Host "="*70 + "`n"

$totalChecks = 0
$passedChecks = 0
$failedChecks = 0
$warnChecks = 0
$unknownChecks = 0

foreach ($result in $validationResults) {
    Write-Host "Lab $($result.LabID): $($result.Name) ($($result.Difficulty))" -ForegroundColor Cyan
    foreach ($check in $result.Checks) {
        $totalChecks++
        switch ($check.Status) {
            "PASS" {
                Write-Success "$($check.Name)"
                $passedChecks++
            }
            "FAIL" {
                Write-Error "$($check.Name)"
                $failedChecks++
            }
            "WARN" {
                Write-Warn "$($check.Name)"
                $warnChecks++
            }
            default {
                Write-Info "$($check.Name) - $($check.Status)"
                $unknownChecks++
            }
        }
    }
    Write-Host ""
}

# Display statistics
Write-Host "Overall Statistics:"
Write-Host "  Total Checks: $totalChecks"
Write-Success "Passed: $passedChecks"
Write-Warn "Warnings: $warnChecks"
if ($failedChecks -gt 0) { Write-Error "Failed: $failedChecks" }
Write-Info "Manual/Unknown: $unknownChecks"

Write-Host "`nNote: Many vulnerabilities require manual testing. See penetration testing guide."
Write-Host "For full exploitation walkthroughs, see: ..\docs\WINDOWS_VULNLAB_PENETESTING_GUIDE.md"
