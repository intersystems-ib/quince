param([switch]$ConfirmDeleteAllRugbyData)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (-not $ConfirmDeleteAllRugbyData) { throw 'Esto elimina la partida de rugby. Para confirmarlo usa -ConfirmDeleteAllRugbyData.' }
docker compose down --volumes
if ($LASTEXITCODE -ne 0) { throw 'No se ha podido eliminar el volumen del proyecto.' }
Write-Host 'Partida eliminada. El próximo arranque inicializará los veinte clubes.'

