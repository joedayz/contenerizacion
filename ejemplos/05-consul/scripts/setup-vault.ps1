# Script para instalar y configurar Vault en Kubernetes (PowerShell)
# Compatible con Docker Desktop en Windows

$ErrorActionPreference = "Stop"

Write-Host "=== Setup Vault para Demos ===" -ForegroundColor Cyan
Write-Host ""

# Verificar kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar helm
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ helm no está instalado" -ForegroundColor Red
    exit 1
}

Write-Host "1. Agregando Vault Helm repo..." -ForegroundColor Blue
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

Write-Host "2. Creando namespace vault..." -ForegroundColor Blue
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

Write-Host "3. Instalando Vault en dev mode (puede tomar 1-2 minutos)..." -ForegroundColor Blue
Write-Host "⚠️  NOTA: Dev mode es solo para demos. En producción usa un storage backend real." -ForegroundColor Yellow
helm upgrade --install vault hashicorp/vault `
  --namespace vault `
  --set "server.dev.enabled=true" `
  --set "server.dev.devRootToken=root" `
  --set "injector.enabled=true" `
  --set "injector.replicas=1" `
  --set "ui.enabled=true" `
  --set "ui.serviceType=ClusterIP" `
  --wait `
  --timeout 5m

Write-Host "4. Esperando a que Vault esté listo..." -ForegroundColor Blue
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

Write-Host "5. Verificando instalación..." -ForegroundColor Blue
kubectl get pods -n vault
kubectl get svc -n vault

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Vault instalado exitosamente" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Configuración de dev mode:" -ForegroundColor Yellow
Write-Host "  Root token: root" -ForegroundColor Cyan
Write-Host "  URL interno: http://vault.vault.svc.cluster.local:8200" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para acceder a la UI de Vault:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n vault svc/vault 8200:8200" -ForegroundColor Cyan
Write-Host "  Luego abrir: http://localhost:8200" -ForegroundColor Cyan
Write-Host "  Token: root" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para usar Vault CLI:" -ForegroundColor Yellow
Write-Host "  `$env:VAULT_ADDR='http://localhost:8200'" -ForegroundColor Cyan
Write-Host "  `$env:VAULT_TOKEN='root'" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n vault svc/vault 8200:8200" -ForegroundColor Cyan
Write-Host "  vault status" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  RECUERDA: Este es dev mode. Los datos se pierden al reiniciar." -ForegroundColor Yellow
Write-Host ""
