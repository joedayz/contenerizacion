#!/bin/bash

# Script para construir y cargar imágenes en Kind usando Podman
# Para macOS/Linux con Podman

set -e

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEMO_DIR"

echo "🔨 Construyendo imágenes con Podman..."

# Construir product-service
echo "📦 Construyendo localhost/product-service:latest..."
podman build -f Dockerfile.product-service -t localhost/product-service:latest .

# Construir order-service
echo "📦 Construyendo localhost/order-service:latest..."
podman build -f Dockerfile.order-service -t localhost/order-service:latest .

echo ""
echo "📥 Cargando imágenes en Kind..."

# Guardar imágenes como tar y cargar en Kind
podman save localhost/product-service:latest -o /tmp/product-service.tar
podman save localhost/order-service:latest -o /tmp/order-service.tar

kind load image-archive /tmp/product-service.tar --name kind-cluster
kind load image-archive /tmp/order-service.tar --name kind-cluster

# Limpiar archivos temporales
rm -f /tmp/product-service.tar /tmp/order-service.tar

echo ""
echo "✅ Imágenes construidas y cargadas en Kind:"
echo "   - localhost/product-service:latest"
echo "   - localhost/order-service:latest"
echo ""
echo "Ahora puedes ejecutar: kubectl apply -f ."
