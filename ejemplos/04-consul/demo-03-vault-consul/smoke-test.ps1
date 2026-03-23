# Smoke test rapido para Demo 3 (Vault + Consul)
# Verifica:
# 1) Pods listos (api-gateway y user-service)
# 2) Reinicios inesperados
# 3) Latencia gateway (N requests)
# 4) Estructura JSON esperada en respuesta

param(
    [int]$Requests = 10,
    [int]$TimeoutSec = 6,
    [int]$Port = 18090,
    [int]$MaxAvgLatencyMs = 500,
    [int]$ReadyTimeoutSec = 120
)

$ErrorActionPreference = "Stop"
$demoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $demoDir

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Success,
        [string]$Failure
    )
    if ($Condition) {
        Write-Host "PASS: $Success" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $Failure" -ForegroundColor Red
        throw $Failure
    }
}

Write-Host "Smoke test Demo 3 (Vault + Consul)" -ForegroundColor Yellow
Write-Host "Requests: $Requests | Timeout: ${TimeoutSec}s | Port-forward local: $Port" -ForegroundColor Yellow

Write-Step "Esperando despliegues Ready"
kubectl rollout status deployment/api-gateway --timeout="${ReadyTimeoutSec}s" | Out-Null
kubectl rollout status deployment/user-service --timeout="${ReadyTimeoutSec}s" | Out-Null
Start-Sleep -Seconds 2

Write-Step "Verificando pods objetivo"
$gatewayPods = kubectl get pods -l app=api-gateway -o json | ConvertFrom-Json
$userPods = kubectl get pods -l app=user-service -o json | ConvertFrom-Json

Assert-Condition ($gatewayPods.items.Count -ge 1) "api-gateway desplegado" "No hay pods de api-gateway"
Assert-Condition ($userPods.items.Count -ge 1) "user-service desplegado" "No hay pods de user-service"

$gatewayReady = @($gatewayPods.items | Where-Object {
    $_.status.containerStatuses[0].ready -eq $true
})
$userReady = @($userPods.items | Where-Object {
    ($_.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count -ge 2
})

Assert-Condition ($gatewayReady.Count -ge 1) "api-gateway en Ready" "api-gateway no esta Ready"
Assert-Condition ($userReady.Count -ge 1) "al menos un user-service en 2/2 Ready" "ningun user-service esta 2/2 Ready"

Write-Step "Validando reinicios"
$gatewayRestarts = ($gatewayPods.items | ForEach-Object { $_.status.containerStatuses[0].restartCount } | Measure-Object -Sum).Sum
$userRestarts = ($userPods.items | ForEach-Object { ($_.status.containerStatuses | Measure-Object restartCount -Sum).Sum } | Measure-Object -Sum).Sum

Write-Host "Reinicios api-gateway (acumulado): $gatewayRestarts"
Write-Host "Reinicios user-service (acumulado): $userRestarts"

Assert-Condition ($gatewayRestarts -lt 5) "reinicios de api-gateway dentro de rango" "api-gateway tiene demasiados reinicios"

Write-Step "Levantando port-forward temporal"
$pfJob = Start-Job -ScriptBlock {
    param($LocalPort)
    kubectl port-forward svc/api-gateway "$LocalPort`:8090"
} -ArgumentList $Port

Start-Sleep -Seconds 3

$latencies = @()
$statuses = @()
$sampleBody = $null

try {
    Write-Step "Ejecutando $Requests requests al gateway"
    for ($i = 1; $i -le $Requests; $i++) {
        $status = "ERR"
        $content = $null

        $elapsed = (Measure-Command {
            try {
                $resp = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec $TimeoutSec -UseBasicParsing
                $status = [string]$resp.StatusCode
                $content = $resp.Content
            } catch {
                $status = "ERR"
            }
        }).TotalMilliseconds

        $lat = [math]::Round($elapsed)
        $latencies += $lat
        $statuses += $status

        if ($i -eq 1 -and $content) {
            $sampleBody = $content
        }

        Write-Host ("[{0}] {1} {2}ms" -f $i, $status, $lat)
    }

    $okCount = ($statuses | Where-Object { $_ -eq "200" }).Count
    $avg = [math]::Round((($latencies | Measure-Object -Average).Average), 2)
    $max = ($latencies | Measure-Object -Maximum).Maximum

    Write-Step "Resumen"
    Write-Host "HTTP 200: $okCount/$Requests"
    Write-Host "Latencia promedio: $avg ms"
    Write-Host "Latencia maxima: $max ms"

    Assert-Condition ($okCount -eq $Requests) "todas las requests fueron 200" "hubo requests con error/timeouts"
    Assert-Condition ($avg -le $MaxAvgLatencyMs) "latencia promedio dentro de objetivo ($MaxAvgLatencyMs ms)" "latencia promedio alta"

    Write-Step "Validando estructura JSON"
    Assert-Condition ($null -ne $sampleBody) "se recibio cuerpo de respuesta" "respuesta vacia del gateway"

    $json = $sampleBody | ConvertFrom-Json
    Assert-Condition ($null -ne $json.gateway) "campo gateway presente" "falta campo gateway"
    Assert-Condition ($null -ne $json.userService) "campo userService presente" "falta campo userService"
    Assert-Condition ($null -ne $json.userService.data) "campo userService.data presente" "falta userService.data"

    if ($json.userService.data.error) {
        Write-Host "WARN: userService.data.error = $($json.userService.data.error)" -ForegroundColor Yellow
    } else {
        Write-Host "PASS: userService responde datos via gateway" -ForegroundColor Green
    }

    Write-Host "`nSmoke test completado" -ForegroundColor Green
} finally {
    Write-Step "Cerrando port-forward temporal"
    if ($pfJob) {
        Stop-Job $pfJob -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $pfJob -ErrorAction SilentlyContinue | Out-Null
    }
}
