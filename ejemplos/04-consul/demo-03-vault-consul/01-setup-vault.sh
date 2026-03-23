#!/bin/bash
# Script para configurar Vault para la Demo 3

set -e

echo "=== Configurando Vault para Demo 3: Vault + Consul ==="

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que Vault está corriendo
echo -e "${YELLOW}1. Verificando Vault...${NC}"
if ! kubectl get pods -n vault | grep -q "vault.*Running"; then
  echo "❌ Vault no está corriendo. Por favor instala Vault primero."
  echo "   Ejecuta: cd ../scripts && ./setup-vault.sh"
  exit 1
fi
echo -e "${GREEN}✅ Vault está corriendo${NC}"

# Configurar variables de entorno para Vault CLI
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_SKIP_VERIFY=true

# Port-forward a Vault en background
echo -e "${YELLOW}2. Estableciendo port-forward a Vault...${NC}"
kubectl port-forward -n vault svc/vault 8200:8200 &
PF_PID=$!
sleep 3

# En dev mode, el token es 'root'
export VAULT_TOKEN='root'

# Función para cleanup
cleanup() {
  echo -e "${YELLOW}Limpiando port-forward...${NC}"
  kill $PF_PID 2>/dev/null || true
}
trap cleanup EXIT

# Verificar conexión
echo -e "${YELLOW}3. Verificando conexión a Vault...${NC}"
if ! vault status > /dev/null 2>&1; then
  echo "❌ No se puede conectar a Vault"
  echo "   Si Vault no está en dev mode, necesitas unseal y configurar el token"
  exit 1
fi
echo -e "${GREEN}✅ Conectado a Vault${NC}"

# Habilitar Kubernetes auth (si no está habilitado)
echo -e "${YELLOW}4. Configurando Kubernetes Auth Method...${NC}"
if ! vault auth list | grep -q "kubernetes/"; then
  vault auth enable kubernetes
  echo -e "${GREEN}✅ Kubernetes auth habilitado${NC}"
else
  echo "ℹ️  Kubernetes auth ya está habilitado"
fi

# Configurar Kubernetes auth
echo -e "${YELLOW}5. Configurando Kubernetes auth con API server...${NC}"
KUBERNETES_HOST="https://kubernetes.default.svc:443"

# Opción A: Si Vault está dentro del cluster
if kubectl get pod -n vault vault-0 > /dev/null 2>&1; then
  SA_TOKEN=$(kubectl exec -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null || echo "")
  if [ -n "$SA_TOKEN" ]; then
    kubectl exec -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > /tmp/vault-ca.crt 2>/dev/null || true
    
    vault write auth/kubernetes/config \
      token_reviewer_jwt="$SA_TOKEN" \
      kubernetes_host="$KUBERNETES_HOST" \
      kubernetes_ca_cert=@/tmp/vault-ca.crt
    
    rm -f /tmp/vault-ca.crt
    echo -e "${GREEN}✅ Kubernetes auth configurado${NC}"
  fi
fi

# Crear secretos de base de datos
echo -e "${YELLOW}6. Creando secretos para PostgreSQL...${NC}"
vault kv put demo03/database \
  username="userdb" \
  password="SecureP@ssw0rd2024" \
  host="postgres-db.service.consul" \
  port="5432" \
  database="userdb"
echo -e "${GREEN}✅ Secretos de BD creados${NC}"

# Crear policy para user-service
echo -e "${YELLOW}7. Creando policy para user-service...${NC}"
vault policy write user-service-policy - <<EOF
# Permiso para leer secretos de base de datos
path "demo03/data/database" {
  capabilities = ["read"]
}

# Permiso para listar secretos (útil para debugging)
path "demo03/metadata/*" {
  capabilities = ["list"]
}
EOF
echo -e "${GREEN}✅ Policy creada${NC}"

# Crear role para Kubernetes auth
echo -e "${YELLOW}8. Creando role para user-service...${NC}"
vault write auth/kubernetes/role/user-service-role \
  bound_service_account_names=user-service \
  bound_service_account_namespaces=default \
  policies=user-service-policy \
  ttl=1h
echo -e "${GREEN}✅ Role creado${NC}"

# Verificar configuración
echo -e "${YELLOW}9. Verificando configuración...${NC}"
echo "   - Secretos:"
vault kv get demo03/database
echo ""
echo "   - Policy:"
vault policy read user-service-policy
echo ""
echo "   - Role:"
vault read auth/kubernetes/role/user-service-role

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vault configurado exitosamente para Demo 3${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. kubectl apply -f postgres.yaml"
echo "  2. kubectl apply -f user-service.yaml"
echo "  3. kubectl apply -f api-gateway.yaml"
echo ""
echo "Para verificar inyección de secretos:"
echo "  POD=\$(kubectl get pods -l app=user-service -o jsonpath='{.items[0].metadata.name}')"
echo "  kubectl logs \$POD -c vault-agent-init"
echo "  kubectl exec \$POD -c user-service -- cat /vault/secrets/database-config.txt"
echo ""
