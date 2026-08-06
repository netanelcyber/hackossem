# Windows Server 2022 Vulnerability Labs - VM Creation Orchestration
# Creates 20 penetration testing training labs with Active Directory and intentional vulnerabilities
# Requires: Administrator privileges, VirtualBox, Windows Server 2022 ISO

#Requires -RunAsAdministrator

param(
    [string]$ConfigFile = "$PSScriptRoot\windows-vulnlab-config.json",
    [string]$Win2022ISO = "C:\ISO\Windows2022.iso",
    [int]$StartLab = 1,
    [int]$EndLab = 20,
    [switch]$SkipNetworkSetup = $false,
    [switch]$DryRun = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Color output
function Write-Success { Write-Host "[✓]" -ForegroundColor Green -NoNewline; Write-Host " $args" }
function Write-Error { Write-Host "[✗]" -ForegroundColor Red -NoNewline; Write-Host " $args" }
function Write-Info { Write-Host "[*]" -ForegroundColor Cyan -NoNewline; Write-Host " $args" }
function Write-Warn { Write-Host "[!]" -ForegroundColor Yellow -NoNewline; Write-Host " $args" }

# Load configuration
Write-Info "Loading configuration from $ConfigFile"
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json
Write-Success "Configuration loaded: $($config.platform)"

# Verify VirtualBox installation
Write-Info "Verifying VirtualBox installation..."
try {
    $vboxVersion = & VBoxManage --version
    Write-Success "VirtualBox version: $vboxVersion"
} catch {
    Write-Error "VirtualBox not found. Please install VirtualBox first."
    exit 1
}

# Verify Windows Server 2022 ISO
Write-Info "Verifying Windows Server 2022 ISO..."
if (-not (Test-Path $Win2022ISO)) {
    Write-Warn "ISO not found at: $Win2022ISO"
    Write-Info "You can specify ISO location with: -Win2022ISO 'C:\path\to\windows2022.iso'"
    # Continue anyway, user may provide ISO later
}

# Create VM storage directory
$vmStoragePath = "C:\VirtualBox VMs\hackossem-ad"
if (-not (Test-Path $vmStoragePath)) {
    Write-Info "Creating VM storage directory: $vmStoragePath"
    New-Item -ItemType Directory -Path $vmStoragePath -Force | Out-Null
    Write-Success "Storage directory created"
}

# Create internal network if not exists
Write-Info "Setting up internal network 'hackossem-ad'..."
try {
    $networks = & VBoxManage list hostonlyifs | Select-String "Name:"
    if (-not ($networks -match "hackossem-ad")) {
        Write-Info "Creating host-only network..."
        & VBoxManage hostonlyif create | Out-Null
        Write-Success "Host-only network created"
    }
} catch {
    Write-Warn "Could not verify internal network: $_"
}

# Function to create individual VM
function New-VulnLabVM {
    param(
        [PSCustomObject]$LabConfig,
        [string]$StoragePath,
        [string]$ISO
    )

    $vmName = $LabConfig.name
    $vmPath = Join-Path $StoragePath $vmName

    Write-Info "Creating VM: $vmName"

    # Check if VM already exists
    $existingVM = & VBoxManage list vms | Select-String "^`"$vmName`""
    if ($existingVM) {
        Write-Warn "VM already exists: $vmName. Skipping creation."
        return $false
    }

    try {
        # Create VM
        & VBoxManage createvm --name $vmName --ostype Windows2022_64 --basefolder $StoragePath --register | Out-Null
        Write-Info "  VM registered: $vmName"

        # Configure hardware
        & VBoxManage modifyvm $vmName --memory ($config.global_config.memory_gb * 1024) --cpus $config.global_config.cpus | Out-Null
        & VBoxManage modifyvm $vmName --vram 128 --graphicscontroller vmsvga | Out-Null

        # Create virtual disk
        $diskPath = Join-Path $vmPath "disk.vdi"
        & VBoxManage createhd --filename $diskPath --size ($config.global_config.disk_gb * 1024) | Out-Null
        Write-Info "  Disk created: $($config.global_config.disk_gb)GB"

        # Create storage controller
        & VBoxManage storagectl $vmName --name "SATA" --add sata --bootdevice dvd | Out-Null
        & VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $diskPath | Out-Null

        # Attach ISO if provided
        if ($ISO -and (Test-Path $ISO)) {
            & VBoxManage storageattach $vmName --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $ISO | Out-Null
            Write-Info "  ISO attached"
        }

        # Configure networking - NAT for internet access
        & VBoxManage modifyvm $vmName --nic1 nat | Out-Null
        & VBoxManage modifyvm $vmName --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" | Out-Null

        # Configure port forwarding for WinRM and RDP
        $winrmPort = $LabConfig.port
        $rdpPort = $LabConfig.rdp_port

        & VBoxManage modifyvm $vmName --natpf1 "WinRM,tcp,,${winrmPort},,5985" | Out-Null
        & VBoxManage modifyvm $vmName --natpf1 "RDP,tcp,,${rdpPort},,3389" | Out-Null
        & VBoxManage modifyvm $vmName --natpf1 "HTTP,tcp,,$($LabConfig.port - 100),,80" | Out-Null
        & VBoxManage modifyvm $vmName --natpf1 "HTTPS,tcp,,$($LabConfig.port - 50),,443" | Out-Null

        Write-Info "  Port forwarding: WinRM=$winrmPort, RDP=$rdpPort"
        Write-Success "VM created: $vmName (IP: $($LabConfig.ip))"
        return $true

    } catch {
        Write-Error "Failed to create VM $vmName : $_"
        return $false
    }
}

# Main execution
Write-Host "`n" + "="*70
Write-Host "Windows Server 2022 Vulnerability Labs - VM Creation" -ForegroundColor Cyan
Write-Host "="*70 + "`n"

$allLabs = @()
$allLabs += $config.easy_tier
$allLabs += $config.medium_tier
$allLabs += $config.hard_tier

# Filter by start/end range
$labsToCreate = $allLabs | Where-Object { [int]$_.id -ge $StartLab -and [int]$_.id -le $EndLab }

Write-Info "Creating $($labsToCreate.Count) vulnerability labs (IDs $StartLab-$EndLab)"
Write-Info "Domain: $($config.global_config.domain)"
Write-Info "Network: $($config.global_config.network)"
Write-Info ""

if ($DryRun) {
    Write-Warn "DRY RUN MODE - No changes will be made"
    Write-Host "`nLabs to be created:"
    $labsToCreate | ForEach-Object {
        Write-Host "  [$($_.id)] $($_.name) - $($_.difficulty) - $($_.vulnerability)"
    }
    exit 0
}

# Create VMs
$successCount = 0
$failCount = 0

foreach ($lab in $labsToCreate) {
    if (New-VulnLabVM -LabConfig $lab -StoragePath $vmStoragePath -ISO $Win2022ISO) {
        $successCount++
    } else {
        $failCount++
    }
    Write-Host ""
}

# Summary
Write-Host "`n" + "="*70
Write-Host "VM Creation Summary" -ForegroundColor Cyan
Write-Host "="*70
Write-Success "$successCount labs created successfully"
if ($failCount -gt 0) {
    Write-Warn "$failCount labs failed to create"
}

Write-Host "`nNext steps:"
Write-Host "1. Boot each VM from ISO and install Windows Server 2022"
Write-Host "2. Run: .\setup-ad-domain.ps1 -LabRange $StartLab,$EndLab"
Write-Host "3. Run: .\inject-vulnerabilities.ps1 -LabRange $StartLab,$EndLab"
Write-Host "4. Run: .\setup-iis-apps.ps1 -LabRange $StartLab,$EndLab"
Write-Host "5. Run: .\validate-vulnerabilities.ps1 to verify all labs"

Write-Host "`nFor more details, see: ..\docs\WINDOWS_VULNLAB_SETUP.md"
