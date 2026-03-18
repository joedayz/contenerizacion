# Script para exponer las UIs de Consul y Vault localmente (PowerShell)

Write-Host "=== Exponiendo UIs de Consul y Vault ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Iniciando port-forwards..." -ForegroundColor Blue
Write-Host ""

# Port-forward Consul UI
Write-Host "Consul UI: http://localhost:8500" -ForegroundColor Yellow
$consulJob = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-ui 8500:80 }

# Pequeña pausa para que inicie
Start-Sleep -Seconds 1

# Port-forward Vault UI
Write-Host "Vault UI:  http://localhost:8200" -ForegroundColor Yellow
Write-Host "Vault Token: root" -ForegroundColor Yellow
$vaultJob = Start-Job -ScriptBlock { kubectl port-forward -n vault svc/vault 8200:8200 }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "UIs expuestas exitosamente" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Accede a:" -ForegroundColor Cyan
Write-Host "  • Consul UI: http://localhost:8500" -ForegroundColor White
Write-Host "  • Vault UI:  http://localhost:8200 (token: root)" -ForegroundColor White
Write-Host ""
Write-Host "Presiona Ctrl+C para detener los port-forwards" -ForegroundColor Yellow
Write-Host ""

# Mantener el script corriendo y monitorear los jobs
try {
    while ($true) {
        Start-Sleep -Seconds 5
        
        # Verificar si los jobs siguen corriendo
        $consulState = Get-Job -Id $consulJob.Id -ErrorAction SilentlyContinue
        $vaultState = Get-Job -Id $vaultJob.Id -ErrorAction SilentlyContinue
        
        if ($consulState.State -eq "Failed" -or $vaultState.State -eq "Failed") {
            Write-Host "❌ Un port-forward falló. Verifica que Consul y Vault estén corriendo." -ForegroundColor Red
            break
        }
    }
} finally {
    Write-Host ""
    Write-Host "Deteniendo port-forwards..." -ForegroundColor Yellow
    Stop-Job -Job $consulJob -ErrorAction SilentlyContinue
    Stop-Job -Job $vaultJob -ErrorAction SilentlyContinue
    Remove-Job -Job $consulJob -ErrorAction SilentlyContinue
    Remove-Job -Job $vaultJob -ErrorAction SilentlyContinue
    Write-Host "¡Adiós!" -ForegroundColor Green
}
