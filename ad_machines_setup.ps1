# Active Directory Training Machines - VirtualBox Setup Script
# Creates 10 training VMs joined to the same domain
# Run this on a Windows host with VirtualBox installed

param(
    [string]$VMBasePath = "C:\VirtualBox VMs",
    [string]$DomainName = "training.lab",
    [string]$DomainAdmin = "Administrator",
    [string]$DomainPassword = "P@ssw0rd123!",
    [string]$BaseImagePath = "C:\iso\windows-server-2022.iso"
)

# Configuration for all 10 machines
$machines = @(
    @{ Name = "AD-DC01"; IP = "192.168.100.10"; Role = "DomainController"; IsFirst = $true },
    @{ Name = "AD-WS01"; IP = "192.168.100.20"; Role = "Workstation"; IsFirst = $false },
    @{ Name = "AD-WS02"; IP = "192.168.100.21"; Role = "Workstation"; IsFirst = $false },
    @{ Name = "AD-SRV01"; IP = "192.168.100.30"; Role = "FileServer"; IsFirst = $false },
    @{ Name = "AD-SRV02"; IP = "192.168.100.31"; Role = "FileServer"; IsFirst = $false },
    @{ Name = "AD-WS03"; IP = "192.168.100.22"; Role = "Workstation"; IsFirst = $false },
    @{ Name = "AD-WS04"; IP = "192.168.100.23"; Role = "Workstation"; IsFirst = $false },
    @{ Name = "AD-SQL01"; IP = "192.168.100.40"; Role = "SQLServer"; IsFirst = $false },
    @{ Name = "AD-MAIL01"; IP = "192.168.100.50"; Role = "MailServer"; IsFirst = $false },
    @{ Name = "AD-WEB01"; IP = "192.168.100.60"; Role = "WebServer"; IsFirst = $false }
)

function Create-VirtualBox-VM {
    param(
        [string]$VMName,
        [string]$VMPath,
        [int]$RAM = 2048,
        [int]$CPUs = 2,
        [int]$DiskSize = 50000
    )

    Write-Host "Creating VM: $VMName" -ForegroundColor Cyan

    # Create VM
    VBoxManage createvm --name $VMName --ostype Windows2022_64 --basefolder $VMPath --register

    # Configure VM resources
    VBoxManage modifyvm $VMName --memory $RAM --cpus $CPUs --vram 128 --accelerate3d off
    VBoxManage modifyvm $VMName --nic1 bridged --bridgeadapter1 "Ethernet" --nictype1 82540EM
    VBoxManage modifyvm $VMName --audiocodec ad1980 --audio wasapi

    # Create disk
    $diskPath = "$VMPath\$VMName\$VMName.vdi"
    VBoxManage createmedium disk --filename $diskPath --size $DiskSize --format VDI

    # Attach storage controller and disk
    VBoxManage storagectl $VMName --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach $VMName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $diskPath

    # Attach ISO for installation
    VBoxManage storagectl $VMName --name "IDE Controller" --add ide
    VBoxManage storageattach $VMName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $BaseImagePath

    Write-Host "✓ VM $VMName created successfully" -ForegroundColor Green
}

function Configure-VM-Network {
    param(
        [string]$VMName,
        [string]$IPAddress,
        [string]$Gateway = "192.168.100.1",
        [string]$DNS = "192.168.100.10"
    )

    Write-Host "Configuring network for $VMName ($IPAddress)" -ForegroundColor Yellow

    # These settings will be applied via post-install scripts on the VMs
    Write-Output @{
        VMName = $VMName
        IPAddress = $IPAddress
        Gateway = $Gateway
        DNS = $DNS
    }
}

function Create-Setup-Script {
    param(
        [PSCustomObject]$MachineConfig
    )

    $scriptContent = @"
# Post-installation configuration script for $($MachineConfig.Name)
# This runs inside the VM after OS installation

# Configure network
`$IPv4Address = '$($MachineConfig.IP)'
`$Gateway = '192.168.100.1'
`$DNS = '192.168.100.10'
`$DomainName = '$DomainName'

# Set static IP
New-NetIPAddress -IPAddress `$IPv4Address -PrefixLength 24 -DefaultGateway `$Gateway -InterfaceIndex (Get-NetAdapter).InterfaceIndex -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -ServerAddresses `$DNS -ErrorAction SilentlyContinue

# Configure hostname
Rename-Computer -NewName '$($MachineConfig.Name)' -Force

# Role-specific configuration
switch ('$($MachineConfig.Role)') {
    'DomainController' {
        # Install AD DS
        Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

        # Create forest
        `$safeModePassword = ConvertTo-SecureString '$DomainPassword' -AsPlainText -Force
        Install-ADDSForest -DomainName `$DomainName -SafeModeAdministratorPassword `$safeModePassword -Force
    }

    'Workstation' {
        # Join domain
        `$credential = New-Object System.Management.Automation.PSCredential('$DomainName\$DomainAdmin', (ConvertTo-SecureString '$DomainPassword' -AsPlainText -Force))
        Add-Computer -DomainName `$DomainName -Credential `$credential -Force
    }

    'FileServer' {
        # Install File Server role
        Install-WindowsFeature File-Services, FS-FileServer -IncludeManagementTools

        # Join domain
        `$credential = New-Object System.Management.Automation.PSCredential('$DomainName\$DomainAdmin', (ConvertTo-SecureString '$DomainPassword' -AsPlainText -Force))
        Add-Computer -DomainName `$DomainName -Credential `$credential -Force
    }

    'SQLServer' {
        # Install SQL Server prerequisites
        Install-WindowsFeature NET-Framework-45-Core -IncludeAllSubFeatures

        # Join domain
        `$credential = New-Object System.Management.Automation.PSCredential('$DomainName\$DomainAdmin', (ConvertTo-SecureString '$DomainPassword' -AsPlainText -Force))
        Add-Computer -DomainName `$DomainName -Credential `$credential -Force
    }

    'MailServer' {
        # Install Mail Server prerequisites
        Install-WindowsFeature RSAT-AD-Tools

        # Join domain
        `$credential = New-Object System.Management.Automation.PSCredential('$DomainName\$DomainAdmin', (ConvertTo-SecureString '$DomainPassword' -AsPlainText -Force))
        Add-Computer -DomainName `$DomainName -Credential `$credential -Force
    }

    'WebServer' {
        # Install IIS
        Install-WindowsFeature Web-Server, Web-Asp-Net45 -IncludeManagementTools

        # Join domain
        `$credential = New-Object System.Management.Automation.PSCredential('$DomainName\$DomainAdmin', (ConvertTo-SecureString '$DomainPassword' -AsPlainText -Force))
        Add-Computer -DomainName `$DomainName -Credential `$credential -Force
    }
}

# Restart computer
Restart-Computer -Force
"@

    return $scriptContent
}

# Main execution
Write-Host "Active Directory Training Environment Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Domain: $DomainName"
Write-Host "Machines to create: $($machines.Count)"
Write-Host ""

foreach ($machine in $machines) {
    try {
        Create-VirtualBox-VM -VMName $machine.Name -VMPath $VMBasePath
        Configure-VM-Network -VMName $machine.Name -IPAddress $machine.IP

        # Create setup script for the VM
        $setupScript = Create-Setup-Script -MachineConfig $machine
        $scriptPath = "$VMBasePath\$($machine.Name)\setup.ps1"
        Set-Content -Path $scriptPath -Value $setupScript

        Write-Host ""
    }
    catch {
        Write-Error "Failed to create $($machine.Name): $_"
    }
}

Write-Host ""
Write-Host "✓ Setup complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start each VM in VirtualBox"
Write-Host "2. Complete Windows Server installation"
Write-Host "3. Run the generated setup.ps1 script from C:\setup.ps1"
Write-Host "4. VMs will be configured and joined to the domain automatically"
