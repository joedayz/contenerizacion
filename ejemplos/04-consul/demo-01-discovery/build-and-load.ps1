# Script para construir y cargar imágenes en Kind usando Docker Desktop
# Para Windows con PowerShell

$ErrorActionPreference = "Stop"

$DEMO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $DEMO_DIR

Write-Host "🔨 Construyendo imágenes con Docker..." -ForegroundColor Cyan

# Construir product-service
Write-Host "📦 Construyendo localhost/product-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.product-service -t localhost/product-service:latest .

# Construir order-service
Write-Host "📦 Construyendo localhost/order-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.order-service -t localhost/order-service:latest .

Write-Host ""
Write-Host "📥 Cargando imágenes en Kind..." -ForegroundColor Cyan

# Cargar en Kind
kind load docker-image localhost/product-service:latest --name kind-cluster
kind load docker-image localhost/order-service:latest --name kind-cluster

Write-Host ""
Write-Host "✅ Imágenes construidas y cargadas en Kind:" -ForegroundColor Green
Write-Host "   - localhost/product-service:latest"
Write-Host "   - localhost/order-service:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f ." -ForegroundColor Green
