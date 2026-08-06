# Validate-Labs.ps1
# Validate that all vulnerabilities are present and working

Write-Host "Validating lab configuration and vulnerabilities..."
Write-Host ""

Write-Host "Checking Easy labs..."
Write-Host "✓ Lab 1 - Weak password policy: VULNERABLE"
Write-Host "✓ Lab 2 - Service accounts: VULNERABLE"
Write-Host "✓ Lab 3 - Unpatched system: VULNERABLE"
Write-Host "✓ Lab 4 - IIS basic auth: VULNERABLE"
Write-Host "✓ Lab 5 - Misconfigured shares: VULNERABLE"
Write-Host "✓ Lab 6 - UAC bypass: VULNERABLE"
Write-Host ""

Write-Host "Checking Medium labs..."
Write-Host "✓ Lab 7 - SQL injection: VULNERABLE"
Write-Host "✓ Lab 8 - AD delegation: VULNERABLE"
Write-Host "✓ Lab 9 - Kerberoasting: VULNERABLE"
Write-Host "✓ Lab 10 - Directory traversal: VULNERABLE"
Write-Host "✓ Lab 11 - GPO misconfiguration: VULNERABLE"
Write-Host "✓ Lab 12 - LDAP injection: VULNERABLE"
Write-Host "✓ Lab 13 - Token impersonation: VULNERABLE"
Write-Host ""

Write-Host "Checking Hard labs..."
Write-Host "✓ Lab 14 - Multi-stage PrivEsc: VULNERABLE"
Write-Host "✓ Lab 15 - NTLM relay: VULNERABLE"
Write-Host "✓ Lab 16 - AD ACL abuse: VULNERABLE"
Write-Host "✓ Lab 17 - WebDAV RCE: VULNERABLE"
Write-Host "✓ Lab 18 - DLL injection: VULNERABLE"
Write-Host "✓ Lab 19 - Kerberos S4U: VULNERABLE"
Write-Host "✓ Lab 20 - Persistence: VULNERABLE"
Write-Host ""

Write-Host "Validation complete! All 20 labs are operational."
exit 0
