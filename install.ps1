# Spencer one-line installer (Windows PowerShell):
#   irm https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.ps1 | iex
# Downloads the install kit into .\spencer and runs its setup (Docker Desktop required).
$ErrorActionPreference = 'Stop'
$dir = if ($env:SPENCER_DIR) { $env:SPENCER_DIR } else { 'spencer' }
New-Item -ItemType Directory -Force $dir | Out-Null
Set-Location $dir
foreach ($f in @('docker-compose.yml', 'Caddyfile', '.env.example', 'setup.sh', 'setup.ps1', 'GUIDE.md', 'LICENSE')) {
    Invoke-WebRequest "https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/$f" -OutFile $f -UseBasicParsing
}
Write-Host "Install kit downloaded to $(Get-Location)"
$ErrorActionPreference = 'Continue'
& powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 @args
