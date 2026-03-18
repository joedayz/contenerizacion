# Build and load images for Demo 3 (Vault + Consul) - PowerShell version

Write-Host "🔨 Construyendo imágenes con Docker..." -ForegroundColor Cyan

# User Service
Write-Host "📦 Construyendo localhost/user-service:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.user-service -t localhost/user-service:latest .

# API Gateway
Write-Host "📦 Construyendo localhost/api-gateway:latest..." -ForegroundColor Yellow
docker build -f Dockerfile.api-gateway -t localhost/api-gateway:latest .

Write-Host ""
Write-Host "📥 Cargando imágenes en Kind..." -ForegroundColor Cyan

kind load docker-image localhost/user-service:latest --name kind-cluster
kind load docker-image localhost/api-gateway:latest --name kind-cluster

Write-Host ""
Write-Host "✅ Imágenes construidas y cargadas en Kind:" -ForegroundColor Green
Write-Host "   - localhost/user-service:latest"
Write-Host "   - localhost/api-gateway:latest"
Write-Host ""
Write-Host "Ahora puedes ejecutar: kubectl apply -f user-service.yaml -f api-gateway.yaml"
