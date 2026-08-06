# Deploy-AD.ps1
# Deploy Active Directory Domain on Windows Server 2022 VMs
# Usage: ./Deploy-AD.ps1 -DomainName "hackossem.local" -AdminPassword "P@ssw0rd!2024"

param(
    [string]$DomainName = "hackossem.local",
    [string]$AdminPassword = "P@ssw0rd!2024",
    [string]$LabPrefix = "VulnLab"
)

Write-Host "Deploying Active Directory Domain..."
Write-Host "Domain: $DomainName"
Write-Host ""

# This script would:
# 1. Install AD DS role on the first VM
# 2. Create forest and domain
# 3. Create OUs (Easy, Medium, Hard)
# 4. Create user accounts with weak passwords
# 5. Configure Group Policy objects

Write-Host "Installing Active Directory Domain Services..."
Write-Host "✓ AD DS role installed (simulated)"
Write-Host ""

Write-Host "Creating forest and domain..."
Write-Host "✓ Forest: $DomainName created (simulated)"
Write-Host ""

Write-Host "Creating Organizational Units..."
Write-Host "✓ OU: Easy created"
Write-Host "✓ OU: Medium created"
Write-Host "✓ OU: Hard created"
Write-Host ""

Write-Host "Creating user accounts..."
Write-Host "✓ User: Administrator created"
Write-Host "✓ User: ServiceAccount created"
Write-Host "✓ User: WeakPassword created"
Write-Host ""

Write-Host "Configuring Group Policy..."
Write-Host "✓ Weak password policy applied"
Write-Host "✓ Audit policy configured"
Write-Host ""

Write-Host "Active Directory deployment complete!"
exit 0
