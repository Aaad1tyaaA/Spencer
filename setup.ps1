# Spencer: one-command local install (Windows PowerShell). Needs Docker Desktop.
#
#   .\setup.ps1            # serves http://localhost
#   .\setup.ps1 -Port 8080 # serves http://localhost:8080 (when port 80 is taken)
#
# Creates .env (only if it doesn't exist yet) with fresh random secrets and local settings,
# then downloads and starts Spencer. Safe to run again: an existing .env is kept.
param([int]$Port = 80)
Set-Location $PSScriptRoot

$hasDocker = [bool](Get-Command docker -ErrorAction SilentlyContinue)
if ($hasDocker) { docker compose version *> $null }
if (-not $hasDocker -or $LASTEXITCODE -ne 0) {
    Write-Host 'Docker Desktop is required (and must be running): https://docs.docker.com/desktop/setup/install/windows-install/'
    exit 1
}

function New-Hex([int]$Bytes) {
    $b = New-Object byte[] $Bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
    -join ($b | ForEach-Object { $_.ToString('x2') })
}

if (Test-Path .env) {
    Write-Host 'Keeping your existing .env'
} else {
    $url = if ($Port -eq 80) { 'http://localhost' } else { "http://localhost:$Port" }
    $map = @{
        'SITE_ADDRESS'                  = ':80'
        'SPENCER_JWT_SECRET'            = (New-Hex 32)
        'SPENCER_KEY_ENCRYPTION_SECRET' = (New-Hex 32)
        'POSTGRES_PASSWORD'             = (New-Hex 24)
        'SPENCER_FRONTEND_URL'          = $url
        'SPENCER_ALLOW_REGISTRATION'    = 'true'
        'SPENCER_STRICT_SIGNUP_EMAIL'   = 'false'
    }
    $lines = Get-Content .env.example | ForEach-Object {
        $key = ($_ -split '=', 2)[0]
        if ($map.ContainsKey($key)) { "$key=$($map[$key])" } else { $_ }
    }
    if ($Port -ne 80) { $lines += '', '# Local install on a custom port', "HTTP_PORT=$Port", "HTTPS_PORT=$($Port + 363)" }
    # UTF-8 without a BOM, so Docker Compose reads the first line correctly.
    [System.IO.File]::WriteAllLines((Join-Path (Get-Location) '.env'), $lines)
    Write-Host 'Created .env with new random secrets'
}

Write-Host 'Downloading and starting Spencer (the first download is about 1 GB)...'
docker compose pull
if ($LASTEXITCODE -eq 0) { docker compose up -d }
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Docker could not start Spencer. Is Docker Desktop running? Details are above.'
    exit $LASTEXITCODE
}

$url = ((Get-Content .env | Where-Object { $_ -like 'SPENCER_FRONTEND_URL=*' }) -split '=', 2)[1]
Write-Host -NoNewline 'Waiting for Spencer to be ready'
for ($i = 0; $i -lt 90; $i++) {
    try {
        Invoke-WebRequest "$url/health" -UseBasicParsing -TimeoutSec 3 | Out-Null
        Write-Host "`n`nSpencer is running: $url"
        Write-Host 'Create an account there, then make it admin with:'
        Write-Host '  docker compose exec backend python -m create_admin you@example.com'
        exit 0
    } catch { Write-Host -NoNewline '.'; Start-Sleep -Seconds 2 }
}
Write-Host "`nSpencer didn't answer yet. Check: docker compose ps  and  docker compose logs backend"
exit 1
