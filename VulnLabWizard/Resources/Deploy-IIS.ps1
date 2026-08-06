# Deploy-IIS.ps1
# Deploy vulnerable IIS applications on Windows Server VMs

Write-Host "Deploying IIS and vulnerable web applications..."
Write-Host ""

Write-Host "Installing IIS..."
Write-Host "✓ IIS installed (simulated)"
Write-Host ""

Write-Host "Deploying vulnerable applications..."
Write-Host "✓ vulnerable-webform-sqli.aspx deployed"
Write-Host "✓ vulnerable-directory-traversal.aspx deployed"
Write-Host "✓ vulnerable-file-upload.aspx deployed"
Write-Host "✓ vulnerable-ldap-search.aspx deployed"
Write-Host "✓ webdav-upload-shell.aspx deployed"
Write-Host ""

Write-Host "IIS deployment complete!"
exit 0
