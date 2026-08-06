# VirtualBox VM Management Script for Windows Server 2022
# Interactive menu-driven VM management

function Show-Menu {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🖥️  VirtualBox VM Management (Windows Server 2022)" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "VMs:" -ForegroundColor Green
    Write-Host "  1 - Lab 1: Active Directory Basics"
    Write-Host "  2 - Lab 2: LDAP Enumeration"
    Write-Host "  3 - Lab 3: Kerberos ASREProast"
    Write-Host "  4 - Lab 4: Privilege Escalation"
    Write-Host "  5 - Lab 5: Golden Ticket"
    Write-Host ""
    Write-Host "Operations:" -ForegroundColor Cyan
    Write-Host "  s - Start selected VM"
    Write-Host "  h - Stop selected VM"
    Write-Host "  i - VM Info"
    Write-Host ""
    Write-Host "Batch Operations:" -ForegroundColor Yellow
    Write-Host "  A - Start ALL Labs"
    Write-Host "  H - Halt ALL Labs"
    Write-Host "  L - List All VMs"
    Write-Host "  M - Monitor Status"
    Write-Host ""
    Write-Host "GUI:" -ForegroundColor Magenta
    Write-Host "  G - Open VirtualBox GUI"
    Write-Host ""
    Write-Host "  0 - Exit"
    Write-Host ""
}

function Start-LabVM {
    param([int]$LabNum)
    $vmName = "VulnLab-ad-lab-$LabNum"
    Write-Host "🚀 Starting $vmName..." -ForegroundColor Green
    try {
        VBoxManage startvm $vmName --type headless
        Start-Sleep -Seconds 3
        Write-Host "✅ Started" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed: $_" -ForegroundColor Red
    }
}

function Stop-LabVM {
    param([int]$LabNum)
    $vmName = "VulnLab-ad-lab-$LabNum"
    Write-Host "🛑 Stopping $vmName..." -ForegroundColor Yellow
    try {
        VBoxManage controlvm $vmName poweroff
        Write-Host "✅ Stopped" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed: $_" -ForegroundColor Red
    }
}

function Show-VMInfo {
    param([int]$LabNum)
    $vmName = "VulnLab-ad-lab-$LabNum"
    Write-Host ""
    Write-Host "Info: $vmName" -ForegroundColor Cyan
    try {
        VBoxManage showvminfo $vmName --compact
    } catch {
        Write-Host "❌ VM not found" -ForegroundColor Red
    }
    Write-Host ""
}

function Start-AllVMs {
    Write-Host "🚀 Starting all labs..." -ForegroundColor Green
    1..5 | ForEach-Object {
        Write-Host "  Starting Lab $_..."
        VBoxManage startvm "VulnLab-ad-lab-$_" --type headless 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
    Write-Host "✅ All labs started" -ForegroundColor Green
}

function Stop-AllVMs {
    Write-Host "🛑 Stopping all labs..." -ForegroundColor Yellow
    1..5 | ForEach-Object {
        Write-Host "  Stopping Lab $_..."
        VBoxManage controlvm "VulnLab-ad-lab-$_" poweroff 2>&1 | Out-Null
    }
    Write-Host "✅ All labs stopped" -ForegroundColor Green
}

function List-AllVMs {
    Write-Host ""
    Write-Host "Registered VMs:" -ForegroundColor Cyan
    VBoxManage list vms | Select-String "VulnLab"
    Write-Host ""
}

function Monitor-Status {
    Write-Host ""
    Write-Host "Status:" -ForegroundColor Cyan
    1..5 | ForEach-Object {
        $vmName = "VulnLab-ad-lab-$_"
        if (VBoxManage list runningvms | Select-String $vmName) {
            Write-Host "  🟢 Lab $_ - Running"
        } else {
            Write-Host "  🔴 Lab $_ - Stopped"
        }
    }
    Write-Host ""
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option"

    switch ($choice) {
        {$_ -in "1","2","3","4","5"} {
            $lab = [int]$_
            $op = Read-Host "  (s)tart, (h)alt, or (i)nfo?"
            switch ($op.ToLower()) {
                "s" { Start-LabVM $lab }
                "h" { Stop-LabVM $lab }
                "i" { Show-VMInfo $lab }
            }
        }
        "s" {
            $lab = [int](Read-Host "Lab number (1-5)")
            Start-LabVM $lab
        }
        "h" {
            $lab = [int](Read-Host "Lab number (1-5)")
            Stop-LabVM $lab
        }
        "i" {
            $lab = [int](Read-Host "Lab number (1-5)")
            Show-VMInfo $lab
        }
        "A" { Start-AllVMs }
        "H" { Stop-AllVMs }
        "L" { List-AllVMs }
        "M" { Monitor-Status }
        "G" {
            Write-Host "Opening VirtualBox..." -ForegroundColor Cyan
            Start-Process "VirtualBox"
        }
        "0" {
            Write-Host "Goodbye! 👋" -ForegroundColor Cyan
            exit 0
        }
        default { Write-Host "Invalid option" -ForegroundColor Red }
    }

    Read-Host "Press Enter to continue"
} while ($true)
