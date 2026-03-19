#!/bin/bash
# Build and load images for Demo 3 (Vault + Consul)

set -e

echo "🔨 Construyendo imágenes con Podman..."

# User Service
echo "📦 Construyendo localhost/user-service:latest..."
podman build -f Dockerfile.user-service -t localhost/user-service:latest .

# API Gateway
echo "📦 Construyendo localhost/api-gateway:latest..."
podman build -f Dockerfile.api-gateway -t localhost/api-gateway:latest .

echo ""
echo "📥 Cargando imágenes en Kind..."

# Save and load user-service
podman save localhost/user-service:latest -o /tmp/user-service.tar
KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive /tmp/user-service.tar --name kind-cluster
rm /tmp/user-service.tar

# Save and load api-gateway
podman save localhost/api-gateway:latest -o /tmp/api-gateway.tar
KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive /tmp/api-gateway.tar --name kind-cluster
rm /tmp/api-gateway.tar

echo ""
echo "✅ Imágenes construidas y cargadas en Kind:"
echo "   - localhost/user-service:latest"
echo "   - localhost/api-gateway:latest"
echo ""
echo "Ahora puedes ejecutar: kubectl apply -f user-service.yaml -f api-gateway.yaml"
