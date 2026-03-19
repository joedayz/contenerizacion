# Script para verificar que Consul y Vault están listos para las demos (PowerShell)

$ErrorActionPreference = "Continue"

Write-Host "=== Verificando Setup de Consul y Vault ===" -ForegroundColor Cyan
Write-Host ""

$ERRORS = 0

function Check {
    param([string]$Message, [bool]$Success)
    if ($Success) {
        Write-Host "✅ $Message" -ForegroundColor Green
    } else {
        Write-Host "❌ $Message" -ForegroundColor Red
        $script:ERRORS++
    }
}

Write-Host "1. Verificando Consul..." -ForegroundColor Yellow
$consulNs = & kubectl get namespace consul 2>&1
Check "Namespace consul existe" ($LASTEXITCODE -eq 0)

$consulPod = & kubectl get pods -n consul 2>&1 | Select-String "consul-server.*Running"
Check "Consul server está corriendo" ($null -ne $consulPod)

$consulSvc = & kubectl get svc -n consul 2>&1 | Select-String "consul-server"
Check "Consul service existe" ($null -ne $consulSvc)

$consulUI = & kubectl get svc -n consul 2>&1 | Select-String "consul-ui"
Check "Consul UI service existe" ($null -ne $consulUI)

Write-Host ""
Write-Host "2. Verificando Vault..." -ForegroundColor Yellow
$vaultNs = & kubectl get namespace vault 2>&1
Check "Namespace vault existe" ($LASTEXITCODE -eq 0)

$vaultPod = & kubectl get pods -n vault 2>&1 | Select-String "vault-0.*Running"
Check "Vault server está corriendo" ($null -ne $vaultPod)

$vaultInjector = & kubectl get pods -n vault 2>&1 | Select-String "vault-agent-injector.*Running"
Check "Vault agent injector está corriendo" ($null -ne $vaultInjector)

$vaultSvc = & kubectl get svc -n vault 2>&1 | Select-String "vault"
Check "Vault service existe" ($null -ne $vaultSvc)

Write-Host ""
Write-Host "3. Verificando conectividad..." -ForegroundColor Yellow

# Port-forward temporal para verificar
$consulJob = Start-Job -ScriptBlock { & kubectl port-forward -n consul svc/consul-server 8500:8500 }
Start-Sleep -Seconds 3

$vaultJob = Start-Job -ScriptBlock { & kubectl port-forward -n vault svc/vault 8200:8200 }
Start-Sleep -Seconds 3

# Verificar Consul
try {
    $consulTest = Invoke-WebRequest -Uri "http://localhost:8500/v1/status/leader" -UseBasicParsing -TimeoutSec 5
    Check "Consul API responde" ($consulTest.StatusCode -eq 200)
} catch {
    Check "Consul API responde" $false
}

# Verificar Vault (en dev mode)
try {
    $vaultTest = Invoke-WebRequest -Uri "http://localhost:8200/v1/sys/health" -UseBasicParsing -TimeoutSec 5
    Check "Vault API responde" ($vaultTest.StatusCode -eq 200)
} catch {
    Check "Vault API responde" $false
}

# Cleanup port-forwards
Stop-Job -Job $consulJob -ErrorAction SilentlyContinue
Stop-Job -Job $vaultJob -ErrorAction SilentlyContinue
Remove-Job -Job $consulJob -ErrorAction SilentlyContinue
Remove-Job -Job $vaultJob -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "4. Verificando resources..." -ForegroundColor Yellow
$notRunning = & kubectl get pods --all-namespaces 2>&1 | Select-String "(consul|vault)" | Select-String -NotMatch "Running"
if ($notRunning) {
    Write-Host "❌ Algunos pods no están Running" -ForegroundColor Red
    $notRunning | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    $ERRORS++
} else {
    Write-Host "✅ Todos los pods están Running" -ForegroundColor Green
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
if ($ERRORS -eq 0) {
    Write-Host "✅ Todo está listo para las demos!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Yellow
    Write-Host "  1. Demo 1: cd ../demo-01-discovery; kubectl apply -f ." -ForegroundColor Cyan
    Write-Host "  2. Demo 2: cd ../demo-02-health-checks; kubectl apply -f ." -ForegroundColor Cyan
    Write-Host "  3. Demo 3: cd ../demo-03-vault-consul; .\01-setup-vault.ps1; kubectl apply -f ." -ForegroundColor Cyan
    Write-Host "  4. Demo 4: cd ../demo-04-dynamic-config; .\01-setup-consul-kv.ps1; kubectl apply -f ." -ForegroundColor Cyan
} else {
    Write-Host "❌ Hay $ERRORS errores. Por favor revisa la configuración." -ForegroundColor Red
    Write-Host ""
    Write-Host "Para reinstalar:" -ForegroundColor Yellow
    Write-Host "  .\setup-consul.ps1" -ForegroundColor Cyan
    Write-Host "  .\setup-vault.ps1" -ForegroundColor Cyan
    exit 1
}
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
