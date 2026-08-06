# Setup IIS and Deploy Vulnerable Web Applications
# Deploys ASP.NET vulnerable applications for penetration testing training
# Requires: IIS installed, Administrator privileges

#Requires -RunAsAdministrator

param(
    [string]$ConfigFile = "$PSScriptRoot\windows-vulnlab-config.json",
    [string]$AppsSourcePath = "$PSScriptRoot\..\iis-apps"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Success { Write-Host "[✓]" -ForegroundColor Green -NoNewline; Write-Host " $args" }
function Write-Error { Write-Host "[✗]" -ForegroundColor Red -NoNewline; Write-Host " $args" }
function Write-Info { Write-Host "[*]" -ForegroundColor Cyan -NoNewline; Write-Host " $args" }
function Write-Warn { Write-Host "[!]" -ForegroundColor Yellow -NoNewline; Write-Host " $args" }

# Load configuration
$config = Get-Content $ConfigFile | ConvertFrom-Json

Write-Host "`n" + "="*70
Write-Host "IIS Vulnerable Applications Setup" -ForegroundColor Cyan
Write-Host "="*70 + "`n"

# Install IIS if not present
Write-Info "Checking IIS installation..."
$iisFeature = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue
if (-not $iisFeature.Installed) {
    Write-Info "Installing IIS with ASP.NET support..."
    Install-WindowsFeature -Name Web-Server, Web-Asp-Net45, Web-Mgmt-Console -IncludeManagementTools | Out-Null
    Write-Success "IIS installed"
} else {
    Write-Success "IIS already installed"
}

# Create root directory for web applications
$wwwPath = "C:\inetpub\wwwroot"
$vulnAppsPath = Join-Path $wwwPath "VulnApps"

if (-not (Test-Path $vulnAppsPath)) {
    New-Item -ItemType Directory -Path $vulnAppsPath -Force | Out-Null
    Write-Success "Created vulnerable apps directory: $vulnAppsPath"
}

# Function to create vulnerable application directory
function New-VulnerableApp {
    param(
        [string]$AppName,
        [string]$Description,
        [string]$VulnerabilityType,
        [int]$Port = 80
    )

    $appPath = Join-Path $vulnAppsPath $AppName

    Write-Info "Creating $AppName ($VulnerabilityType)..."

    if (-not (Test-Path $appPath)) {
        New-Item -ItemType Directory -Path $appPath -Force | Out-Null
    }

    # Create basic web.config for each app
    $webConfigPath = Join-Path $appPath "web.config"
    @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <security>
      <authentication>
        <basicAuthentication enabled="true" />
        <anonymousAuthentication enabled="false" />
      </authentication>
    </security>
  </system.webServer>
  <appSettings>
    <add key="app_name" value="$AppName" />
    <add key="vulnerability" value="$VulnerabilityType" />
  </appSettings>
</configuration>
"@ | Out-File $webConfigPath -Encoding UTF8

    Write-Success "Created $AppName at $appPath"
    return $appPath
}

# Create vulnerable applications
$vulnApps = @(
    @{ Name = "SQLi"; Type = "SQL Injection"; Desc = "Login form with time-based blind SQLi" },
    @{ Name = "DirectoryTraversal"; Type = "Directory Traversal"; Desc = "File viewer vulnerable to path traversal" },
    @{ Name = "FileUpload"; Type = "File Upload"; Desc = "File upload accepting dangerous extensions" },
    @{ Name = "LDAPi"; Type = "LDAP Injection"; Desc = "LDAP query builder vulnerable to injection" },
    @{ Name = "WebDAV"; Type = "WebDAV + RCE"; Desc = "WebDAV with writable directories" }
)

Write-Info "`nDeploying vulnerable web applications..."
foreach ($app in $vulnApps) {
    New-VulnerableApp -AppName $app.Name -Description $app.Desc -VulnerabilityType $app.Type
}

# Create a default page listing all apps
Write-Info "Creating default application list page..."
$indexPath = Join-Path $wwwPath "default.htm"

$indexContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>HackOSSEM Vulnerable Applications Lab</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        h1 { color: #d32f2f; }
        .app { border: 1px solid #ccc; padding: 15px; margin: 10px 0; }
        .app a { color: #1976d2; text-decoration: none; font-weight: bold; }
        .app a:hover { text-decoration: underline; }
        .vuln { color: #f57c00; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>HackOSSEM Vulnerable Applications Lab</h1>
    <p>Training platform for penetration testing and security research</p>

    <h2>Vulnerable Applications</h2>
"@

foreach ($app in $vulnApps) {
    $indexContent += @"
    <div class="app">
        <a href="/VulnApps/$($app.Name)/">/VulnApps/$($app.Name)/</a>
        <div class="vuln">$($app.Type) - $($app.Desc)</div>
    </div>
"@
}

$indexContent += @"
    <hr>
    <p><small>For exploitation guides, see: docs/WINDOWS_VULNLAB_PENETESTING_GUIDE.md</small></p>
</body>
</html>
"@

$indexContent | Out-File $indexPath -Encoding UTF8
Write-Success "Created default application list page"

# Configure IIS application pools and websites
Write-Info "`nConfiguring IIS application pools..."

$appPoolName = "VulnApps"
try {
    $pool = Get-IISAppPool -Name $appPoolName -ErrorAction SilentlyContinue
    if (-not $pool) {
        New-WebAppPool -Name $appPoolName | Out-Null
        Write-Success "Created app pool: $appPoolName"
    } else {
        Write-Warn "App pool already exists: $appPoolName"
    }
} catch {
    Write-Warn "Could not create app pool: $_"
}

# Create individual IIS websites for each app
Write-Info "`nConfiguring IIS websites..."
foreach ($app in $vulnApps) {
    $siteName = "VulnApp-$($app.Name)"
    $sitePath = Join-Path $vulnAppsPath $app.Name

    try {
        $site = Get-Website -Name $siteName -ErrorAction SilentlyContinue
        if (-not $site) {
            # Find available port
            $portOffset = $vulnApps.IndexOf($app)
            $port = 8000 + $portOffset

            New-Website -Name $siteName `
                -PhysicalPath $sitePath `
                -Port $port `
                -ApplicationPool $appPoolName | Out-Null

            Write-Success "Created IIS site: $siteName (port $port)"
        } else {
            Write-Warn "Website already exists: $siteName"
        }
    } catch {
        Write-Warn "Could not create website $siteName : $_"
    }
}

# Enable specific features for vulnerabilities
Write-Info "`nEnabling vulnerable features..."

# Enable WebDAV for WebDAV app
try {
    Add-WindowsFeature -Name Web-DAV-Publishing -ErrorAction SilentlyContinue | Out-Null
    Write-Success "WebDAV publishing enabled"
} catch {
    Write-Warn "Could not enable WebDAV: $_"
}

# Create default credentials file for testing
Write-Info "`nCreating test credentials file..."
$credsPath = Join-Path $wwwPath "test-credentials.txt"
@"
Testing Credentials for Vulnerable Applications

Admin Accounts:
  Username: admin
  Password: Admin123

Database Accounts:
  Username: sa
  Password: SqlPass2022!

Application Accounts:
  Username: app_user
  Password: AppUser2022

Note: These are intentional test credentials for lab environments only.
"@ | Out-File $credsPath -Encoding UTF8
Write-Success "Created test credentials file"

# Display access URLs
Write-Host "`n" + "="*70
Write-Success "IIS vulnerable applications setup complete!"
Write-Host "="*70 + "`n"

Write-Host "Access URLs:"
Write-Host "  Default page: http://localhost/default.htm"
Write-Host "  SQLi lab: http://localhost:8000/SQLi/"
Write-Host "  Directory Traversal: http://localhost:8001/DirectoryTraversal/"
Write-Host "  File Upload: http://localhost:8002/FileUpload/"
Write-Host "  LDAP Injection: http://localhost:8003/LDAPi/"
Write-Host "  WebDAV: http://localhost:8004/WebDAV/"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Deploy actual vulnerable ASP.NET applications to each directory"
Write-Host "2. Run .\validate-vulnerabilities.ps1 to verify all systems"
Write-Host "3. See docs/WINDOWS_VULNLAB_PENETESTING_GUIDE.md for exploitation guides"
