$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$ready = $false
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    try {
        $health = Invoke-RestMethod 'http://127.0.0.1:8085/api/v1/health' -TimeoutSec 3
        if ($health.status -eq 'ok') { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 1
}
if (-not $ready) { throw 'IRIS no está listo. Arranca primero Docker Compose.' }
$output = docker compose exec -T iris sh -c 'iris session IRIS -U RUGBY < /opt/rugby/test.script' 2>&1
$output | Write-Output
if (($LASTEXITCODE -ne 0) -or -not ($output -match 'ALL TESTS PASSED')) { throw 'Han fallado las pruebas de IRIS.' }
Push-Location rugby-frontend
try {
    npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw 'No se han podido instalar las dependencias.' }
    npm.cmd run build
    if ($LASTEXITCODE -ne 0) { throw 'Ha fallado la compilación del frontend.' }
} finally { Pop-Location }
