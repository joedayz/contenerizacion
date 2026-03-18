# Script para instalar y configurar Consul en Kubernetes (PowerShell)
# Compatible con Docker Desktop en Windows

$ErrorActionPreference = "Stop"

Write-Host "=== Setup Consul para Demos ===" -ForegroundColor Cyan
Write-Host ""

# Verificar kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl no está instalado" -ForegroundColor Red
    Write-Host "Descárgalo desde: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Yellow
    exit 1
}

# Verificar helm
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ helm no está instalado" -ForegroundColor Red
    Write-Host "Descárgalo desde: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

Write-Host "1. Agregando Consul Helm repo..." -ForegroundColor Blue
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

Write-Host "2. Creando namespace consul..." -ForegroundColor Blue
kubectl create namespace consul --dry-run=client -o yaml | kubectl apply -f -

Write-Host "3. Instalando Consul (puede tomar 2-3 minutos)..." -ForegroundColor Blue
helm upgrade --install consul hashicorp/consul `
  --namespace consul `
  --set global.name=consul `
  --set server.replicas=1 `
  --set server.bootstrapExpect=1 `
  --set server.storage=1Gi `
  --set ui.enabled=true `
  --set ui.service.type=ClusterIP `
  --set connectInject.enabled=true `
  --set connectInject.default=false `
  --set client.enabled=true `
  --set client.grpc=true `
  --set dns.enabled=true `
  --set dns.enableRedirection=true `
  --set syncCatalog.enabled=true `
  --set syncCatalog.toConsul=true `
  --set syncCatalog.toK8S=false `
  --wait `
  --timeout 5m

Write-Host "4. Esperando a que Consul esté listo..." -ForegroundColor Blue
kubectl wait --for=condition=Ready pod -l app=consul -n consul --timeout=300s

Write-Host "5. Verificando instalación..." -ForegroundColor Blue
kubectl get pods -n consul
kubectl get svc -n consul

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Consul instalado exitosamente" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Para acceder a la UI de Consul:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n consul svc/consul-ui 8500:80" -ForegroundColor Cyan
Write-Host "  Luego abrir: http://localhost:8500" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para usar Consul CLI:" -ForegroundColor Yellow
Write-Host "  `$env:CONSUL_HTTP_ADDR='http://localhost:8500'" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n consul svc/consul-server 8500:8500" -ForegroundColor Cyan
Write-Host "  consul members" -ForegroundColor Cyan
Write-Host ""
