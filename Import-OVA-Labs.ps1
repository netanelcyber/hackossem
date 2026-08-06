# VirtualBox OVA Import Script for Windows Server 2022
# Import all VulnLab AD lab OVA files
# Run as Administrator

param(
    [string]$OVADirectory = ".\lab-vms",
    [string]$VMStoragePath = "C:\VirtualBox VMs"
)

# Require Administrator
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script must run as Administrator" -ForegroundColor Red
    exit 1
}

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🪟 VirtualBox OVA Import for Windows Server 2022" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check VirtualBox
try {
    $version = VBoxManage --version
    Write-Host "✅ VirtualBox: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ VirtualBox not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Labs
$labs = @(
    @{ID = "ad-lab-1"; Name = "Active Directory Basics"},
    @{ID = "ad-lab-2"; Name = "LDAP Enumeration & Exploitation"},
    @{ID = "ad-lab-3"; Name = "Kerberos & ASREProast"},
    @{ID = "ad-lab-4"; Name = "Privilege Escalation in AD"},
    @{ID = "ad-lab-5"; Name = "Golden Ticket & Domain Takeover"}
)

Write-Host "📋 Labs:" -ForegroundColor Cyan
$labs | ForEach-Object { Write-Host "  ✓ $($_.ID): $($_.Name)" }
Write-Host ""

$confirmation = Read-Host "Import all labs? (y/n)"
if ($confirmation -ne 'y') { exit 0 }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📦 Importing..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$counter = 1
foreach ($lab in $labs) {
    $ovaFile = Join-Path $OVADirectory "lab-$($lab.ID).ova"
    $vmName = "VulnLab-$($lab.ID)"

    if (-not (Test-Path $ovaFile)) {
        Write-Host "[$counter/5] ⚠️  Skipping (not found): $ovaFile" -ForegroundColor Yellow
        $counter++
        continue
    }

    Write-Host "[$counter/5] 📤 Importing: $($lab.Name)" -ForegroundColor Cyan

    try {
        VBoxManage import $ovaFile `
            --vsys 0 `
            --vmname $vmName `
            --basefolder $VMStoragePath `
            --group "/VulnLab" | Out-Null

        Write-Host "    ✅ Success" -ForegroundColor Green
    } catch {
        Write-Host "    ❌ Failed: $_" -ForegroundColor Red
    }

    $counter++
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Imported VMs:" -ForegroundColor Cyan
VBoxManage list vms | Select-String "VulnLab"
