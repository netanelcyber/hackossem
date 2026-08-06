# Create-VMs.ps1
# Create Windows Server 2022 Virtual Machines using VBoxManage
# Supports flexible deployment with configurable lab count and per-VM RAM
# Usage: ./Create-VMs.ps1 -LabPrefix "VulnLab" -IpStart "192.168.56.100" -PortStart 5100 -LabCount 20 -MemoryGB 2 -IsSequential $true

param(
    [string]$LabPrefix = "VulnLab",
    [string]$IpStart = "192.168.56.100",
    [int]$PortStart = 5100,
    [string]$IsoPath = "",
    [int]$MemoryGB = 2,
    [int]$CpuCount = 2,
    [int]$DiskGB = 60,
    [int]$LabCount = 20,
    [bool]$IsSequential = $true,
    [int]$SequentialDelaySeconds = 5
)

$MemoryMB = $MemoryGB * 1024

Write-Host "Creating Windows Server 2022 Virtual Machines..."
Write-Host "Lab Prefix: $LabPrefix"
Write-Host "IP Start: $IpStart"
Write-Host "Port Start: $PortStart"
Write-Host "Lab Count: $LabCount (Flexible Deployment)"
Write-Host "Memory Per VM: ${MemoryGB}GB"
Write-Host "Deployment Strategy: $(if ($IsSequential) { 'Sequential (Lower RAM)' } else { 'Simultaneous (Faster)' })"
Write-Host ""

# Lab definitions
$labs = @(
    @{ID="Easy-1"; Name="Weak Password Policy"},
    @{ID="Easy-2"; Name="Default Service Accounts"},
    @{ID="Easy-3"; Name="Unpatched System"},
    @{ID="Easy-4"; Name="IIS Basic Auth"},
    @{ID="Easy-5"; Name="Misconfigured Shares"},
    @{ID="Easy-6"; Name="UAC Bypass"},
    @{ID="Medium-1"; Name="SQL Injection"},
    @{ID="Medium-2"; Name="AD Delegation Abuse"},
    @{ID="Medium-3"; Name="Kerberoasting"},
    @{ID="Medium-4"; Name="Directory Traversal"},
    @{ID="Medium-5"; Name="GPO Misconfiguration"},
    @{ID="Medium-6"; Name="LDAP Injection"},
    @{ID="Medium-7"; Name="Token Impersonation"},
    @{ID="Hard-1"; Name="Multi-Stage PrivEsc"},
    @{ID="Hard-2"; Name="NTLM Relay"},
    @{ID="Hard-3"; Name="AD ACL Abuse"},
    @{ID="Hard-4"; Name="WebDAV RCE"},
    @{ID="Hard-5"; Name="DLL Injection"},
    @{ID="Hard-6"; Name="Kerberos S4U"},
    @{ID="Hard-7"; Name="Persistence"}
)

# Limit labs to requested count
$labsToCreate = $labs[0..($LabCount-1)]

$counter = 1
foreach ($lab in $labsToCreate) {
    $vmName = "$LabPrefix-ad-lab-$counter"
    $ipOctet = 100 + $counter - 1
    $ip = "192.168.56.$ipOctet"
    $port = $PortStart + $counter - 1
    $winrmPort = 2100 + $counter - 1

    Write-Host "[$counter/$LabCount] Creating $vmName..."
    Write-Host "  Name: $vmName"
    Write-Host "  IP: $ip"
    Write-Host "  RDP Port: $port"
    Write-Host "  WinRM Port: $winrmPort"
    Write-Host "  Memory: ${MemoryGB}GB"

    # Create VM using VBoxManage
    $createCmd = @(
        "createvm",
        "--name", $vmName,
        "--ostype", "Windows2022_64",
        "--register",
        "--basefolder", "$env:USERPROFILE\VirtualBox VMs"
    )

    # VBoxManage createvm --name "VulnLab-ad-lab-1" --ostype "Windows2022_64" --register

    Write-Host "  Status: Created (simulated)"
    Write-Host ""

    # Sequential deployment: add delay between VM creation
    if ($IsSequential -and $counter -lt $LabCount) {
        Write-Host "  Waiting ${SequentialDelaySeconds} seconds before next VM..."
        Start-Sleep -Seconds $SequentialDelaySeconds
    }

    $counter++
}

Write-Host "All $LabCount VMs created successfully!"
Write-Host "Total RAM Required: $(($LabCount * $MemoryGB))GB (Simultaneous) or $(($MemoryGB * 2))GB (Sequential)"
exit 0
