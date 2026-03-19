#!/bin/bash
# Elimina los recursos de las demos de Vault y desinstala Vault del clúster.
# Para limpiar solo los deployments de demo sin tocar Vault, usa cleanup-demos.sh
#
# Uso: ./vault-down.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
RED='\033[0;31m'

echo "=== Vault Teardown — Docker Desktop ==="
echo ""
echo -e "${YELLOW}Esto eliminará:${NC}"
echo "  • Deployments, Services, PVCs de las demos"
echo "  • Helm release 'vault' y namespace 'vault'"
echo ""

read -p "¿Continuar? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelado."
  exit 0
fi

echo ""
echo -e "${YELLOW}1. Eliminando recursos de demos...${NC}"
kubectl delete deployment app-con-vault vault-quarkus-demo expense-service postgres-expense \
  --ignore-not-found 2>/dev/null || true
kubectl delete service vault-quarkus-demo expense-service postgres-expense \
  --ignore-not-found 2>/dev/null || true
kubectl delete serviceaccount vault-quarkus-demo expense-service \
  --ignore-not-found 2>/dev/null || true
kubectl delete pvc postgres-expense-pvc \
  --ignore-not-found 2>/dev/null || true

echo -e "${YELLOW}2. Desinstalando Vault (Helm)...${NC}"
helm uninstall vault -n vault 2>/dev/null || true

echo -e "${YELLOW}3. Eliminando namespace vault...${NC}"
kubectl delete namespace vault --ignore-not-found 2>/dev/null || true

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vault eliminado del clúster${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Para reinstalar y configurar:"
echo "  ./vault-up.sh"
echo ""
