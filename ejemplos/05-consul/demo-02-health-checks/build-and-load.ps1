# Script para construir y cargar imágenes en Kind usando Docker Desktop
# Para Windows con PowerShell

$ErrorActionPreference = "Stop"

$DEMO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $DEMO_DIR

Write-Host "🔨 Construyendo imágenes con Docker..." -ForegroundColor Cyan

# Construir backend-service
Write-Host "📦 Construyendo localhost/backend-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.backend-service -t localhost/backend-service:latest .

# Construir client-service
Write-Host "📦 Construyendo localhost/client-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.client-service -t localhost/client-service:latest .

Write-Host ""
Write-Host "📥 Cargando imágenes en Kind..." -ForegroundColor Cyan

# Cargar en Kind
kind load docker-image localhost/backend-service:latest --name kind-cluster
kind load docker-image localhost/client-service:latest --name kind-cluster

Write-Host ""
Write-Host "✅ Imágenes construidas y cargadas en Kind:" -ForegroundColor Green
Write-Host "   - localhost/backend-service:latest"
Write-Host "   - localhost/client-service:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f ." -ForegroundColor Green
