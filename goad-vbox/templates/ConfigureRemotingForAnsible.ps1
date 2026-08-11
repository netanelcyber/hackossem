#Requires -Version 3.0
# This script configures WinRM for Ansible remote management
# Run as Administrator on each Windows machine

# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Enable PowerShell Remoting
Write-Host "Enabling PSRemoting..."
Enable-PSRemoting -Force

# Allow basic authentication
Write-Host "Configuring WinRM authentication..."
Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $true -Force

# Allow unencrypted traffic (for lab only!)
Write-Host "Allowing unencrypted traffic (lab environment)..."
Set-Item -Path "WSMan:\localhost\Service\AllowUnencrypted" -Value $true -Force

# Set firewall rules for WinRM
Write-Host "Configuring firewall rules..."
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True `
  -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -ErrorAction SilentlyContinue

New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True `
  -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow -ErrorAction SilentlyContinue

# Increase WinRM memory quotas
Write-Host "Increasing WinRM memory quotas..."
Set-Item -Path "WSMan:\localhost\Shell\MaxMemoryPerShellMB" -Value 1024 -Force
Set-Item -Path "WSMan:\localhost\MaxEnvelopeSizekb" -Value 2048 -Force

# Restart WinRM service
Write-Host "Restarting WinRM service..."
Restart-Service WinRM -Force

# Test WinRM
Write-Host "Testing WinRM connectivity..."
$test = Test-WSMan localhost -ErrorAction SilentlyContinue

if ($test) {
    Write-Host "✓ WinRM is configured and running!" -ForegroundColor Green
    Write-Host "WinRM Identity: $($test.wsmid)"
    exit 0
} else {
    Write-Host "✗ WinRM test failed" -ForegroundColor Red
    exit 1
}
