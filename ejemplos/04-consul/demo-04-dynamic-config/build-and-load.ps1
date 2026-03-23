# Script para construir imagenes con Docker Desktop - Demo 4 (Dynamic Config)
# Para Windows con PowerShell

$ErrorActionPreference = "Stop"

$DEMO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $DEMO_DIR

Write-Host "Construyendo imagenes con Docker..." -ForegroundColor Cyan

# Config Service
Write-Host "Construyendo config-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.config-service -t config-service:latest .

Write-Host ""
Write-Host "Imagenes construidas para Docker Desktop:" -ForegroundColor Green
Write-Host "   - config-service:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f config-service.yaml" -ForegroundColor Green
