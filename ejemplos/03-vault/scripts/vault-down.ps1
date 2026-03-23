# Elimina los recursos de las demos de Vault y desinstala Vault del cluster.
# Para limpiar solo los deployments de demo sin tocar Vault, usa cleanup-demos.ps1
#
# Uso: .\vault-down.ps1

$ErrorActionPreference = "Continue"

Write-Host "=== Vault Teardown - Docker Desktop ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Esto eliminara:" -ForegroundColor Yellow
Write-Host "  - Deployments, Services, PVCs de las demos"
Write-Host "  - Helm release 'vault' y namespace 'vault'"
Write-Host ""

$response = Read-Host "Continuar? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Cancelado." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "1. Eliminando recursos de demos..." -ForegroundColor Yellow
& kubectl delete deployment app-con-vault vault-quarkus-demo expense-service postgres-expense `
    --ignore-not-found 2>$null
& kubectl delete service vault-quarkus-demo expense-service postgres-expense `
    --ignore-not-found 2>$null
& kubectl delete serviceaccount vault-quarkus-demo expense-service `
    --ignore-not-found 2>$null
& kubectl delete pvc postgres-expense-pvc `
    --ignore-not-found 2>$null

Write-Host "2. Desinstalando Vault (Helm)..." -ForegroundColor Yellow
& helm uninstall vault -n vault 2>$null | Out-Null

Write-Host "3. Eliminando namespace vault..." -ForegroundColor Yellow
& kubectl delete namespace vault --ignore-not-found 2>$null | Out-Null

Write-Host ""
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Vault eliminado del cluster" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Para reinstalar y configurar:" -ForegroundColor Yellow
Write-Host "  .\vault-up.ps1" -ForegroundColor Cyan
Write-Host ""
