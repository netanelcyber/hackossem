# utilities.ps1
# Common utility functions used by other PowerShell scripts

function Test-VirtualBoxInstalled {
    try {
        $output = VBoxManage --version
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Get-AvailableDiskSpace {
    $drive = Get-PSDrive C
    return $drive.Free
}

function Get-AvailableMemory {
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    return $computerSystem.TotalPhysicalMemory / 1GB
}

function New-LabVM {
    param(
        [string]$VmName,
        [string]$NetworkName,
        [int]$MemoryMB,
        [int]$CpuCount,
        [int]$DiskGB
    )

    Write-Host "Creating VM: $VmName"
    # Implementation would call VBoxManage
}

function Start-LabVM {
    param([string]$VmName)
    Write-Host "Starting VM: $VmName"
    # Implementation would call VBoxManage startvm
}

function Stop-LabVM {
    param([string]$VmName)
    Write-Host "Stopping VM: $VmName"
    # Implementation would call VBoxManage controlvm poweroff
}

function Test-WinRMAccess {
    param([string]$ComputerName)
    try {
        Test-WSMan -ComputerName $ComputerName -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-RemoteCommand {
    param(
        [string]$ComputerName,
        [scriptblock]$ScriptBlock,
        [string]$Credential
    )

    Invoke-Command -ComputerName $ComputerName `
                   -ScriptBlock $ScriptBlock `
                   -Credential $Credential
}

function New-Snapshot {
    param(
        [string]$VmName,
        [string]$SnapshotName
    )

    Write-Host "Creating snapshot: $SnapshotName for $VmName"
    # Implementation would call VBoxManage snapshot
}

function Restore-Snapshot {
    param(
        [string]$VmName,
        [string]$SnapshotName
    )

    Write-Host "Restoring snapshot: $SnapshotName for $VmName"
    # Implementation would call VBoxManage snapshot restore
}

function Write-Log {
    param(
        [string]$Message,
        [string]$LogPath
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $LogPath
}

Export-ModuleMember -Function @(
    'Test-VirtualBoxInstalled',
    'Get-AvailableDiskSpace',
    'Get-AvailableMemory',
    'New-LabVM',
    'Start-LabVM',
    'Stop-LabVM',
    'Test-WinRMAccess',
    'Invoke-RemoteCommand',
    'New-Snapshot',
    'Restore-Snapshot',
    'Write-Log'
)
