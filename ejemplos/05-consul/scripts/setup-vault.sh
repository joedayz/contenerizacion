#!/bin/bash
# Script para instalar y configurar Vault en Kubernetes

set -e

echo "=== Setup Vault para Demos ==="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl no está instalado"
  exit 1
fi

# Verificar helm
if ! command -v helm &> /dev/null; then
  echo "❌ helm no está instalado"
  exit 1
fi

echo -e "${BLUE}1. Agregando Vault Helm repo...${NC}"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo -e "${BLUE}2. Creando namespace vault...${NC}"
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}3. Instalando Vault en dev mode...${NC}"
echo "⚠️  NOTA: Dev mode es solo para demos. En producción usa un storage backend real."
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root" \
  --set "injector.enabled=true" \
  --set "injector.replicas=1" \
  --set "ui.enabled=true" \
  --set "ui.serviceType=ClusterIP" \
  --wait \
  --timeout 5m

echo -e "${BLUE}4. Esperando a que Vault esté listo...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

echo -e "${BLUE}5. Verificando instalación...${NC}"
kubectl get pods -n vault
kubectl get svc -n vault

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vault instalado exitosamente${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Configuración de dev mode:"
echo "  Root token: root"
echo "  URL interno: http://vault.vault.svc.cluster.local:8200"
echo ""
echo "Para acceder a la UI de Vault:"
echo "  kubectl port-forward -n vault svc/vault 8200:8200"
echo "  Luego abrir: http://localhost:8200"
echo "  Token: root"
echo ""
echo "Para usar Vault CLI:"
echo "  export VAULT_ADDR=http://localhost:8200"
echo "  export VAULT_TOKEN=root"
echo "  kubectl port-forward -n vault svc/vault 8200:8200"
echo "  vault status"
echo ""
echo "⚠️  RECUERDA: Este es dev mode. Los datos se pierden al reiniciar."
echo ""
