@echo off
REM Active Directory Training Environment - Quick Setup Batch Script
REM Usage: quick_setup.bat <action>
REM Actions: create, start, stop, status, cleanup

setlocal enabledelayedexpansion
cd /d "%~dp0"

if "%1"=="" (
    echo.
    echo Active Directory Training Environment Manager
    echo =============================================
    echo.
    echo Usage: quick_setup.bat [action]
    echo.
    echo Actions:
    echo   create     Create all 10 VirtualBox VMs
    echo   start      Start all VMs
    echo   stop       Stop all VMs
    echo   status     Show status of all VMs
    echo   cleanup    Delete all VMs
    echo   help       Show this help message
    echo.
    goto end
)

REM Check for PowerShell
where powershell >nul 2>&1
if errorlevel 1 (
    echo PowerShell not found. Please install PowerShell.
    goto end
)

REM Check for VirtualBox
where VBoxManage >nul 2>&1
if errorlevel 1 (
    echo VirtualBox not found. Please install VirtualBox.
    goto end
)

if /i "%1"=="create" (
    echo Creating all Active Directory training VMs...
    powershell -NoProfile -ExecutionPolicy Bypass -File "manage_ad_machines.ps1" -Action CreateAll
    goto end
)

if /i "%1"=="start" (
    echo Starting all VMs...
    powershell -NoProfile -ExecutionPolicy Bypass -File "manage_ad_machines.ps1" -Action StartAll
    goto end
)

if /i "%1"=="stop" (
    echo Stopping all VMs...
    powershell -NoProfile -ExecutionPolicy Bypass -File "manage_ad_machines.ps1" -Action StopAll
    goto end
)

if /i "%1"=="status" (
    echo Checking VM status...
    powershell -NoProfile -ExecutionPolicy Bypass -File "manage_ad_machines.ps1" -Action Status
    goto end
)

if /i "%1"=="cleanup" (
    echo WARNING: This will delete all VMs!
    set /p confirm="Continue? (yes/no): "
    if /i "!confirm!"=="yes" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "manage_ad_machines.ps1" -Action DeleteAll
    ) else (
        echo Cancelled.
    )
    goto end
)

if /i "%1"=="help" (
    call %0
    goto end
)

echo Unknown action: %1
call %0

:end
endlocal
