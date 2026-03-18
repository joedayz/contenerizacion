# Script para configurar Consul KV para Demo 4 (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "=== Configurando Consul KV para Demo 4 ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que Consul esté instalado
$consulPod = & kubectl get pods -n consul -l component=server -o jsonpath='{.items[0].metadata.name}' 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($consulPod)) {
    Write-Host "❌ Consul no está instalado. Ejecuta setup-consul.ps1 primero." -ForegroundColor Red
    exit 1
}

Write-Host "Iniciando port-forward temporal a Consul..." -ForegroundColor Blue
$consulJob = Start-Job -ScriptBlock { & kubectl port-forward -n consul svc/consul-server 8500:8500 }
Start-Sleep -Seconds 3

# Verificar si consul CLI está disponible
$useConsulCLI = $false
if (Get-Command consul -ErrorAction SilentlyContinue) {
    $useConsulCLI = $true
    $env:CONSUL_HTTP_ADDR = "http://localhost:8500"
}

Write-Host "1. Creando configuración de features..." -ForegroundColor Blue
$features = @{
    feature_x = $true
    feature_y = $false
    feature_z = $true
} | ConvertTo-Json

if ($useConsulCLI) {
    & consul kv put demo04/config/features $features
} else {
    Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/config/features" `
        -Method Put -Body $features -ContentType "application/json"
}

Write-Host "2. Creando configuración de rate limiter..." -ForegroundColor Blue
$rateLimit = @{
    requests_per_minute = 100
    burst_size = 20
} | ConvertTo-Json

if ($useConsulCLI) {
    & consul kv put demo04/config/rate_limiter $rateLimit
} else {
    Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/config/rate_limiter" `
        -Method Put -Body $rateLimit -ContentType "application/json"
}

Write-Host "3. Creando configuración de cache..." -ForegroundColor Blue
$cache = @{
    ttl_seconds = 300
    max_size_mb = 50
} | ConvertTo-Json

if ($useConsulCLI) {
    & consul kv put demo04/config/cache $cache
} else {
    Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/config/cache" `
        -Method Put -Body $cache -ContentType "application/json"
}

Write-Host ""
Write-Host "4. Verificando valores creados..." -ForegroundColor Blue
if ($useConsulCLI) {
    & consul kv get -recurse demo04/
} else {
    $keys = Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/?recurse" -Method Get
    $keys | ForEach-Object {
        $key = $_.Key
        $value = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_.Value))
        Write-Host "  $key : $value" -ForegroundColor White
    }
}

# Cleanup
Stop-Job $consulJob -ErrorAction SilentlyContinue
Remove-Job -Job $consulJob -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Consul KV configurado para Demo 4" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Configuración creada en Consul KV:" -ForegroundColor Yellow
Write-Host "  • demo04/config/features - Feature flags" -ForegroundColor White
Write-Host "  • demo04/config/rate_limiter - Límites de rate" -ForegroundColor White
Write-Host "  • demo04/config/cache - Configuración de cache" -ForegroundColor White
Write-Host ""
Write-Host "Para acceder a Consul UI:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n consul svc/consul-ui 8500:80" -ForegroundColor White
Write-Host "  http://localhost:8500/ui/dc1/kv/demo04/" -ForegroundColor White
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Configurar Vault con: .\02-setup-vault-secrets.ps1" -ForegroundColor White
Write-Host "  2. Desplegar servicio: kubectl apply -f config-service.yaml" -ForegroundColor White
Write-Host ""
