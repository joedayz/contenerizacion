# Script para limpiar todos los recursos de las demos (PowerShell)

$ErrorActionPreference = "Continue"

Write-Host "=== Limpieza de Demos Consul + Vault ===" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "¿Estás seguro que quieres eliminar todos los recursos de las demos? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Cancelado." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "1. Limpiando Demo 1 (Service Discovery)..." -ForegroundColor Yellow
& kubectl delete -f ../demo-01-discovery/ --ignore-not-found=true

Write-Host "2. Limpiando Demo 2 (Health Checks)..." -ForegroundColor Yellow
& kubectl delete -f ../demo-02-health-checks/ --ignore-not-found=true

Write-Host "3. Limpiando Demo 3 (Vault + Consul)..." -ForegroundColor Yellow
& kubectl delete -f ../demo-03-vault-consul/ --ignore-not-found=true
& kubectl delete sa user-service --ignore-not-found=true

Write-Host "4. Limpiando Demo 4 (Dynamic Config)..." -ForegroundColor Yellow
& kubectl delete -f ../demo-04-dynamic-config/config-service.yaml --ignore-not-found=true 2>$null
& kubectl delete sa config-service --ignore-not-found=true

Write-Host "5. Limpiando Consul KV..." -ForegroundColor Yellow
# Port-forward temporal
$consulJob = Start-Job -ScriptBlock { & kubectl port-forward -n consul svc/consul-server 8500:8500 }
Start-Sleep -Seconds 3

if (Get-Command consul -ErrorAction SilentlyContinue) {
    $env:CONSUL_HTTP_ADDR = "http://localhost:8500"
    & consul kv delete -recurse demo04/ 2>$null | Out-Null
    & consul kv delete -recurse demo03/ 2>$null | Out-Null
}

Stop-Job -Job $consulJob -ErrorAction SilentlyContinue
Remove-Job -Job $consulJob -ErrorAction SilentlyContinue

Write-Host ""
$response = Read-Host "¿Desinstalar también Consul y Vault? (y/N)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "6. Desinstalando Consul..." -ForegroundColor Yellow
    & helm uninstall consul -n consul 2>&1 | Out-Null
    & kubectl delete namespace consul --ignore-not-found=true
    
    Write-Host "7. Desinstalando Vault..." -ForegroundColor Yellow
    & helm uninstall vault -n vault 2>&1 | Out-Null
    & kubectl delete namespace vault --ignore-not-found=true
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Limpieza completada" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Para reinstalar desde cero:" -ForegroundColor Yellow
Write-Host "  .\setup-consul.ps1" -ForegroundColor Cyan
Write-Host "  .\setup-vault.ps1" -ForegroundColor Cyan
Write-Host "  .\verify-setup.ps1" -ForegroundColor Cyan
Write-Host ""
