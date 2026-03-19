#!/bin/bash
# Script para limpiar todos los recursos de las demos

set -e

echo "=== Limpieza de Demos Consul + Vault ==="

# Colores
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

read -p "¿Estás seguro que quieres eliminar todos los recursos de las demos? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelado."
  exit 0
fi

echo ""
echo -e "${YELLOW}1. Limpiando Demo 1 (Service Discovery)...${NC}"
kubectl delete -f ../demo-01-discovery/ --ignore-not-found=true

echo -e "${YELLOW}2. Limpiando Demo 2 (Health Checks)...${NC}"
kubectl delete -f ../demo-02-health-checks/ --ignore-not-found=true

echo -e "${YELLOW}3. Limpiando Demo 3 (Vault + Consul)...${NC}"
kubectl delete -f ../demo-03-vault-consul/ --ignore-not-found=true
kubectl delete sa user-service --ignore-not-found=true

echo -e "${YELLOW}4. Limpiando Demo 4 (Dynamic Config)...${NC}"
kubectl delete -f ../demo-04-dynamic-config/config-service.yaml --ignore-not-found=true 2>/dev/null || true
kubectl delete sa config-service --ignore-not-found=true

echo -e "${YELLOW}5. Limpiando Consul KV...${NC}"
# Port-forward temporal
kubectl port-forward -n consul svc/consul-server 8500:8500 &
PF_PID=$!
sleep 2

if command -v consul &> /dev/null; then
  export CONSUL_HTTP_ADDR=http://localhost:8500
  consul kv delete -recurse demo04/ 2>/dev/null || true
  consul kv delete -recurse demo03/ 2>/dev/null || true
fi

kill $PF_PID 2>/dev/null || true

echo ""
read -p "¿Desinstalar también Consul y Vault? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}6. Desinstalando Consul...${NC}"
  helm uninstall consul -n consul || true
  kubectl delete namespace consul --ignore-not-found=true
  
  echo -e "${YELLOW}7. Desinstalando Vault...${NC}"
  helm uninstall vault -n vault || true
  kubectl delete namespace vault --ignore-not-found=true
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Para reinstalar desde cero:"
echo "  ./setup-consul.sh"
echo "  ./setup-vault.sh"
echo "  ./verify-setup.sh"
echo ""
