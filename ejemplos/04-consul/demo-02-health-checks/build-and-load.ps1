# Script para construir imagenes con Docker Desktop
# Para Windows con PowerShell

$ErrorActionPreference = "Stop"

$DEMO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $DEMO_DIR

Write-Host "Construyendo imagenes con Docker..." -ForegroundColor Cyan

# Construir backend-service
Write-Host "Construyendo backend-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.backend-service -t backend-service:latest .

# Construir client-service
Write-Host "Construyendo client-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.client-service -t client-service:latest .

Write-Host ""
Write-Host "Imagenes construidas para Docker Desktop:" -ForegroundColor Green
Write-Host "   - backend-service:latest"
Write-Host "   - client-service:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f ." -ForegroundColor Green
