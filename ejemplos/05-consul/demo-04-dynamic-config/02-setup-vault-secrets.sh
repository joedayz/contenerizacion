#!/bin/bash
# Script para configurar Vault Secrets para la Demo 4

set -e

echo "=== Configurando Vault Secrets para Demo 4 ==="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que Vault está corriendo
echo -e "${YELLOW}1. Verificando Vault...${NC}"
if ! kubectl get pods -n vault | grep -q "vault.*Running"; then
  echo "❌ Vault no está corriendo."
  exit 1
fi
echo -e "${GREEN}✅ Vault está corriendo${NC}"

# Configurar variables de entorno
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN='root'

# Port-forward a Vault
echo -e "${YELLOW}2. Estableciendo port-forward a Vault...${NC}"
kubectl port-forward -n vault svc/vault 8200:8200 &
PF_PID=$!
sleep 3

cleanup() {
  echo -e "${YELLOW}Limpiando port-forward...${NC}"
  kill $PF_PID 2>/dev/null || true
}
trap cleanup EXIT

# Crear secretos de API keys
echo -e "${YELLOW}3. Creando API keys...${NC}"
vault kv put secret/demo04/api-keys \
  weather-api="sk_prod_abc123xyz789" \
  payment-gateway="pk_live_def456uvw012" \
  maps-api="AIzaSyC_maps_key_example" \
  analytics="ga_tracking_id_UA-12345"
echo -e "${GREEN}✅ API keys creados${NC}"

# Crear secretos JWT
echo -e "${YELLOW}4. Creando JWT secrets...${NC}"
vault kv put secret/demo04/jwt \
  secret="super-secret-jwt-key-do-not-share-2024" \
  algorithm="HS256" \
  expiration="3600" \
  issuer="demo-app"
echo -e "${GREEN}✅ JWT secrets creados${NC}"

# Crear secretos de integraciones
echo -e "${YELLOW}5. Creando integration secrets...${NC}"
vault kv put secret/demo04/integrations \
  slack-webhook="https://hooks.slack.com/services/T00/B00/xxx" \
  github-token="ghp_example_token_123456" \
  sendgrid-api-key="SG.example_key_789"
echo -e "${GREEN}✅ Integration secrets creados${NC}"

# Crear policy para config-service
echo -e "${YELLOW}6. Creando policy...${NC}"
vault policy write config-service-policy - <<EOF
# Permiso para leer todos los secretos de demo04
path "secret/data/demo04/*" {
  capabilities = ["read"]
}

# Permiso para listar
path "secret/metadata/demo04/*" {
  capabilities = ["list"]
}
EOF
echo -e "${GREEN}✅ Policy creada${NC}"

# Crear role para Kubernetes auth
echo -e "${YELLOW}7. Creando role...${NC}"
vault write auth/kubernetes/role/config-service-role \
  bound_service_account_names=config-service \
  bound_service_account_namespaces=default \
  policies=config-service-policy \
  ttl=1h
echo -e "${GREEN}✅ Role creado${NC}"

# Verificar
echo -e "${YELLOW}8. Verificando configuración...${NC}"
echo ""
echo "API Keys:"
vault kv get secret/demo04/api-keys
echo ""
echo "JWT Secrets:"
vault kv get secret/demo04/jwt
echo ""
echo "Integrations:"
vault kv get secret/demo04/integrations

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vault Secrets configurados exitosamente${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Ver en UI: http://localhost:8200/ui/vault/secrets/secret/list/demo04/"
echo ""
echo "Próximo paso:"
echo "  kubectl apply -f config-service.yaml"
echo ""
