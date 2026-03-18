#!/bin/bash
# Script para verificar que Consul y Vault están listos para las demos

set -e

echo "=== Verificando Setup de Consul y Vault ==="

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Función para verificar
check() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ $1${NC}"
  else
    echo -e "${RED}❌ $1${NC}"
    ERRORS=$((ERRORS + 1))
  fi
}

echo ""
echo "1. Verificando Consul..."
kubectl get namespace consul > /dev/null 2>&1
check "Namespace consul existe"

kubectl get pods -n consul | grep -q "consul-server.*Running" > /dev/null 2>&1
check "Consul server está corriendo"

kubectl get svc -n consul | grep -q "consul-server" > /dev/null 2>&1
check "Consul service existe"

kubectl get svc -n consul | grep -q "consul-ui" > /dev/null 2>&1
check "Consul UI service existe"

echo ""
echo "2. Verificando Vault..."
kubectl get namespace vault > /dev/null 2>&1
check "Namespace vault existe"

kubectl get pods -n vault | grep -q "vault-0.*Running" > /dev/null 2>&1
check "Vault server está corriendo"

kubectl get pods -n vault | grep -q "vault-agent-injector.*Running" > /dev/null 2>&1
check "Vault agent injector está corriendo"

kubectl get svc -n vault | grep -q "vault" > /dev/null 2>&1
check "Vault service existe"

echo ""
echo "3. Verificando conectividad..."

# Port-forward temporal para verificar
kubectl port-forward -n consul svc/consul-server 8500:8500 &
PF_CONSUL=$!
sleep 2

kubectl port-forward -n vault svc/vault 8200:8200 &
PF_VAULT=$!
sleep 2

# Verificar Consul
curl -sf http://localhost:8500/v1/status/leader > /dev/null 2>&1
check "Consul API responde"

# Verificar Vault (en dev mode)
curl -sf http://localhost:8200/v1/sys/health > /dev/null 2>&1
check "Vault API responde"

# Cleanup port-forwards
kill $PF_CONSUL $PF_VAULT 2>/dev/null

echo ""
echo "4. Verificando resources..."
kubectl get pods --all-namespaces | grep -E "(consul|vault)" | grep -v Running && ERRORS=$((ERRORS + 1)) || echo -e "${GREEN}✅ Todos los pods están Running${NC}"

echo ""
echo "════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ Todo está listo para las demos!${NC}"
  echo ""
  echo "Próximos pasos:"
  echo "  1. Demo 1: cd demo-01-discovery && kubectl apply -f ."
  echo "  2. Demo 2: cd demo-02-health-checks && kubectl apply -f ."
  echo "  3. Demo 3: cd demo-03-vault-consul && ./01-setup-vault.sh && kubectl apply -f ."
  echo "  4. Demo 4: cd demo-04-dynamic-config && ./01-setup-consul-kv.sh && kubectl apply -f ."
else
  echo -e "${RED}❌ Hay $ERRORS errores. Por favor revisa la configuración.${NC}"
  echo ""
  echo "Para reinstalar:"
  echo "  ./setup-consul.sh"
  echo "  ./setup-vault.sh"
  exit 1
fi
echo "════════════════════════════════════════════════════════"
echo ""
