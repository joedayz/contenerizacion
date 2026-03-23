# Script para construir imagenes con Docker Desktop - Demo 3 (Vault + Consul)
# Para Windows con PowerShell

$ErrorActionPreference = "Stop"

$DEMO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $DEMO_DIR

Write-Host "Construyendo imagenes con Docker..." -ForegroundColor Cyan

# User Service
Write-Host "Construyendo user-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.user-service -t user-service:latest .

# API Gateway
Write-Host "Construyendo api-gateway:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.api-gateway -t api-gateway:latest .

Write-Host ""
Write-Host "Imagenes construidas para Docker Desktop:" -ForegroundColor Green
Write-Host "   - user-service:latest"
Write-Host "   - api-gateway:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f user-service.yaml -f api-gateway.yaml" -ForegroundColor Green
