#!/bin/bash
# Script para configurar Consul KV para la Demo 4

set -e

echo "=== Configurando Consul KV para Demo 4 ==="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que Consul está corriendo
echo -e "${YELLOW}1. Verificando Consul...${NC}"
if ! kubectl get pods -n consul | grep -q "consul.*Running"; then
  echo "❌ Consul no está corriendo."
  exit 1
fi
echo -e "${GREEN}✅ Consul está corriendo${NC}"

# Port-forward a Consul
echo -e "${YELLOW}2. Estableciendo port-forward a Consul...${NC}"
kubectl port-forward -n consul svc/consul-server 8500:8500 &
PF_PID=$!
sleep 3

cleanup() {
  echo -e "${YELLOW}Limpiando port-forward...${NC}"
  kill $PF_PID 2>/dev/null || true
}
trap cleanup EXIT

# Configurar feature flags
echo -e "${YELLOW}3. Configurando feature flags...${NC}"
consul kv put demo04/config/features/new-ui enabled
consul kv put demo04/config/features/analytics disabled
consul kv put demo04/config/features/dark-mode enabled
consul kv put demo04/config/features/beta-features disabled
echo -e "${GREEN}✅ Feature flags configurados${NC}"

# Configurar rate limiting
echo -e "${YELLOW}4. Configurando rate limiting...${NC}"
consul kv put demo04/config/ratelimit/requests-per-second 100
consul kv put demo04/config/ratelimit/burst 20
consul kv put demo04/config/ratelimit/enabled true
echo -e "${GREEN}✅ Rate limiting configurado${NC}"

# Configurar cache
echo -e "${YELLOW}5. Configurando cache...${NC}"
consul kv put demo04/config/cache/ttl 300
consul kv put demo04/config/cache/max-size 1000
consul kv put demo04/config/cache/enabled true
echo -e "${GREEN}✅ Cache configurado${NC}"

# Configurar timeouts
echo -e "${YELLOW}6. Configurando timeouts...${NC}"
consul kv put demo04/config/timeouts/connect 5s
consul kv put demo04/config/timeouts/read 30s
consul kv put demo04/config/timeouts/write 10s
echo -e "${GREEN}✅ Timeouts configurados${NC}"

# Configurar circuit breaker
echo -e "${YELLOW}7. Configurando circuit breaker...${NC}"
consul kv put demo04/config/circuit-breaker/enabled true
consul kv put demo04/config/circuit-breaker/threshold 5
consul kv put demo04/config/circuit-breaker/timeout 30s
echo -e "${GREEN}✅ Circuit breaker configurado${NC}"

# Listar todo
echo -e "${YELLOW}8. Verificando configuración...${NC}"
echo ""
consul kv get -recurse demo04/config/

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Consul KV configurado exitosamente${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Ver en UI: http://localhost:8500/ui/dc1/kv/demo04/config/"
echo ""
echo "Próximo paso:"
echo "  ./02-setup-vault-secrets.sh"
echo ""
