# Script para construir imagenes con Docker Desktop
# Para Windows con PowerShell

$ErrorActionPreference = "Stop"

$DEMO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $DEMO_DIR

Write-Host "Construyendo imagenes con Docker..." -ForegroundColor Cyan

# Construir product-service
Write-Host "Construyendo product-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.product-service -t product-service:latest .

# Construir order-service
Write-Host "Construyendo order-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.order-service -t order-service:latest .

Write-Host ""
Write-Host "Imagenes construidas para Docker Desktop:" -ForegroundColor Green
Write-Host "   - product-service:latest"
Write-Host "   - order-service:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f ." -ForegroundColor Green
