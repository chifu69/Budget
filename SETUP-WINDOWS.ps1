param(
  [string]$Destination = "actual-budget-local"
)

$ErrorActionPreference = "Stop"

if (Get-Command py -ErrorAction SilentlyContinue) {
  py -3 scripts/bootstrap.py --dest $Destination
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
  python scripts/bootstrap.py --dest $Destination
} else {
  throw "Python 3 no está instalado o no está en PATH."
}

Write-Host ""
Write-Host "Budget Local está preparado en: $Destination" -ForegroundColor Green
Write-Host "Actual Budget usa scripts Unix para el empaquetado completo. En Windows usa Git Bash o WSL para:" -ForegroundColor Yellow
Write-Host "  cd $Destination"
Write-Host "  corepack enable"
Write-Host "  yarn install --immutable"
Write-Host "  yarn start"
Write-Host "  yarn build:browser"
