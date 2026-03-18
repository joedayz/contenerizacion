#!/bin/bash

# Script para construir y cargar imágenes en Kind usando Podman
# Para macOS/Linux con Podman

set -e

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEMO_DIR"

echo "🔨 Construyendo imágenes con Podman..."

# Construir backend-service
echo "📦 Construyendo localhost/backend-service:latest..."
podman build -f Dockerfile.backend-service -t localhost/backend-service:latest .

# Construir client-service
echo "📦 Construyendo localhost/client-service:latest..."
podman build -f Dockerfile.client-service -t localhost/client-service:latest .

echo ""
echo "📥 Cargando imágenes en Kind..."

# Guardar imágenes como tar y cargar en Kind
podman save localhost/backend-service:latest -o /tmp/backend-service.tar
podman save localhost/client-service:latest -o /tmp/client-service.tar

kind load image-archive /tmp/backend-service.tar --name kind-cluster
kind load image-archive /tmp/client-service.tar --name kind-cluster

# Limpiar archivos temporales
rm -f /tmp/backend-service.tar /tmp/client-service.tar

echo ""
echo "✅ Imágenes construidas y cargadas en Kind:"
echo "   - localhost/backend-service:latest"
echo "   - localhost/client-service:latest"
echo ""
echo "Ahora puedes ejecutar: kubectl apply -f ."
