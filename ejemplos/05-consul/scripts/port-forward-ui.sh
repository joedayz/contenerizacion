#!/bin/bash
# Script para exponer las UIs de Consul y Vault localmente

echo "=== Exponiendo UIs de Consul y Vault ==="

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Iniciando port-forwards...${NC}"
echo ""

# Port-forward Consul UI
echo -e "${YELLOW}Consul UI:${NC} http://localhost:8500"
kubectl port-forward -n consul svc/consul-ui 8500:80 &
CONSUL_PF=$!

# Port-forward Vault UI
echo -e "${YELLOW}Vault UI:${NC} http://localhost:8200"
echo -e "${YELLOW}Vault Token:${NC} root"
kubectl port-forward -n vault svc/vault 8200:8200 &
VAULT_PF=$!

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}UIs expuestas exitosamente${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Accede a:"
echo "  • Consul UI: http://localhost:8500"
echo "  • Vault UI:  http://localhost:8200 (token: root)"
echo ""
echo "Presiona Ctrl+C para detener los port-forwards"
echo ""

# Función de cleanup
cleanup() {
  echo ""
  echo "Deteniendo port-forwards..."
  kill $CONSUL_PF $VAULT_PF 2>/dev/null
  echo "¡Adiós!"
  exit 0
}

trap cleanup SIGINT SIGTERM

# Mantener el script corriendo
wait
