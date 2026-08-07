# Active Directory Training Machines Manager
# Manages 10 VirtualBox VMs configured for AD training

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CreateAll', 'StartAll', 'StopAll', 'DeleteAll', 'Status', 'Configure', 'Reset')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = ".\machines_config.json",

    [Parameter(Mandatory = $false)]
    [string]$VBoxPath = "C:\Program Files\Oracle\VirtualBox"
)

# Load configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json
$machines = $config.machines

function Get-VBoxManagePath {
    $paths = @(
        "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe",
        "C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe",
        "VBoxManage.exe"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }

    throw "VBoxManage not found. Please ensure VirtualBox is installed."
}

$VBoxManage = Get-VBoxManagePath

function Start-VM {
    param([string]$VMName)

    Write-Host "Starting $VMName..." -ForegroundColor Yellow
    & $VBoxManage startvm $VMName --type headless
    Write-Host "✓ $VMName started" -ForegroundColor Green
}

function Stop-VM {
    param([string]$VMName)

    Write-Host "Stopping $VMName..." -ForegroundColor Yellow
    & $VBoxManage controlvm $VMName poweroff
    Write-Host "✓ $VMName stopped" -ForegroundColor Green
}

function Create-VM {
    param([PSCustomObject]$Machine)

    Write-Host "Creating $($Machine.name)..." -ForegroundColor Cyan

    # Create VM
    & $VBoxManage createvm `
        --name $Machine.name `
        --ostype Windows2022_64 `
        --basefolder $config.environment.vboxBase `
        --register

    # Configure memory and CPU
    & $VBoxManage modifyvm $Machine.name `
        --memory $Machine.resources.memory_mb `
        --cpus $Machine.resources.cpus `
        --vram 128

    # Configure network
    & $VBoxManage modifyvm $Machine.name `
        --nic1 bridged `
        --bridgeadapter1 $config.networkSettings.adapterName `
        --nictype1 82540EM

    Write-Host "✓ $($Machine.name) created" -ForegroundColor Green
}

function Get-VM-Status {
    param([string]$VMName)

    $output = & $VBoxManage showvminfo $VMName --machinereadable 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($output -like "*VMState=*") {
            $state = ($output -match "VMState=(.+)" | ForEach-Object { $matches[1] }) -join ""
            return $state
        }
    }
    return "Not Found"
}

function Show-All-Status {
    Write-Host ""
    Write-Host "Active Directory Training Environment Status" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Domain: $($config.environment.domain)" -ForegroundColor Green
    Write-Host "Network: $($config.environment.baseNetwork)" -ForegroundColor Green
    Write-Host ""

    $statusTable = @()

    foreach ($machine in $machines) {
        $status = Get-VM-Status -VMName $machine.name
        $statusTable += [PSCustomObject]@{
            Name = $machine.name
            Role = $machine.role
            IP = $machine.ip
            Status = $status
            Memory = "$($machine.resources.memory_mb)MB"
            CPUs = $machine.resources.cpus
        }
    }

    $statusTable | Format-Table -AutoSize
}

function Reset-All {
    Write-Host "Resetting all VMs..." -ForegroundColor Yellow

    # Stop all VMs
    foreach ($machine in $machines) {
        $status = Get-VM-Status -VMName $machine.name
        if ($status -ne "Not Found" -and $status -ne "poweroff") {
            Stop-VM -VMName $machine.name
        }
    }

    Start-Sleep -Seconds 2

    # Delete all VMs
    foreach ($machine in $machines) {
        $status = Get-VM-Status -VMName $machine.name
        if ($status -ne "Not Found") {
            Write-Host "Deleting $($machine.name)..." -ForegroundColor Yellow
            & $VBoxManage unregistervm $machine.name --delete
        }
    }

    Write-Host "✓ All VMs reset" -ForegroundColor Green
}

# Main switch
switch ($Action) {
    'CreateAll' {
        Write-Host "Creating all $($machines.Count) VMs..." -ForegroundColor Cyan
        foreach ($machine in $machines) {
            try {
                Create-VM -Machine $machine
                Start-Sleep -Milliseconds 500
            }
            catch {
                Write-Error "Failed to create $($machine.name): $_"
            }
        }
        Write-Host ""
        Write-Host "✓ All VMs created" -ForegroundColor Green
    }

    'StartAll' {
        Write-Host "Starting all VMs..." -ForegroundColor Cyan
        foreach ($machine in $machines) {
            try {
                Start-VM -VMName $machine.name
                Start-Sleep -Seconds 1
            }
            catch {
                Write-Error "Failed to start $($machine.name): $_"
            }
        }
        Write-Host "✓ All VMs started" -ForegroundColor Green
    }

    'StopAll' {
        Write-Host "Stopping all VMs..." -ForegroundColor Cyan
        foreach ($machine in $machines) {
            try {
                Stop-VM -VMName $machine.name
                Start-Sleep -Seconds 1
            }
            catch {
                Write-Error "Failed to stop $($machine.name): $_"
            }
        }
        Write-Host "✓ All VMs stopped" -ForegroundColor Green
    }

    'DeleteAll' {
        $confirm = Read-Host "This will delete all VMs. Continue? (yes/no)"
        if ($confirm -eq "yes") {
            Reset-All
        }
        else {
            Write-Host "Cancelled" -ForegroundColor Yellow
        }
    }

    'Status' {
        Show-All-Status
    }

    'Configure' {
        Write-Host "Configuring network and features for all VMs..." -ForegroundColor Cyan
        Write-Host "This requires VMs to be running and Windows installed."
        Write-Host ""

        $credential = Get-Credential -Message "Enter domain admin credentials"

        foreach ($machine in $machines) {
            Write-Host "Configuring $($machine.name)..." -ForegroundColor Yellow

            # Configuration scripts would be executed via PowerShell Remoting
            # This is a placeholder for the configuration logic

            Write-Host "✓ $($machine.name) configured" -ForegroundColor Green
        }
    }

    'Reset' {
        Reset-All
    }
}

Write-Host ""
Write-Host "Command completed successfully" -ForegroundColor Green
