$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw 'No se ha podido arrancar el proyecto. Comprueba Docker y las imágenes.' }
Write-Host 'Quince: http://localhost:5175 · API: http://localhost:8085/api/v1/health'
