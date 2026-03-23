#!/bin/bash
# Instala Vault en Kubernetes (Docker Desktop) y lo configura completamente:
#   - Helm install en dev mode con Vault Agent Injector
#   - Kubernetes auth method
#   - Secretos de ejemplo (mi-app/db, expense/db)
#   - Políticas y roles para los deployments de demo
#
# Uso: ./vault-up.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Vault Setup — Docker Desktop ==="
echo ""

# ── Prerrequisitos ────────────────────────────────────────────────────────────
if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}❌ kubectl no está instalado${NC}"
  exit 1
fi

if ! command -v helm &> /dev/null; then
  echo -e "${RED}❌ helm no está instalado${NC}"
  exit 1
fi

# ── 1. Instalar Vault via Helm ────────────────────────────────────────────────
echo -e "${BLUE}1. Agregando Vault Helm repo...${NC}"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo -e "${BLUE}2. Creando namespace vault...${NC}"
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}3. Instalando Vault en dev mode (puede tardar 2-3 min)...${NC}"
echo -e "${YELLOW}   ⚠️  Dev mode: los datos se pierden si el pod se reinicia${NC}"
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root" \
  --set "server.dataStorage.enabled=false" \
  --set "server.service.type=ClusterIP" \
  --set "server.readinessProbe.enabled=false" \
  --set "server.livenessProbe.enabled=false" \
  --set "injector.enabled=true" \
  --set "injector.replicas=1" \
  --set "ui.enabled=true" \
  --set "ui.serviceType=ClusterIP" \
  --wait \
  --timeout 5m

echo -e "${BLUE}4. Esperando a que Vault esté listo...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

# ── 2. Configurar Vault via kubectl exec ──────────────────────────────────────
VAULT_POD="vault-0"
VAULT_NS="vault"

echo ""
echo -e "${BLUE}5. Habilitando Kubernetes auth method...${NC}"
kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault auth enable kubernetes 2>/dev/null \
  || echo "   (ya estaba habilitado)"

echo -e "${BLUE}6. Configurando Kubernetes auth...${NC}"
SA_TOKEN=$(kubectl exec -n "$VAULT_NS" "$VAULT_POD" \
  -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CA_CERT=$(kubectl exec -n "$VAULT_NS" "$VAULT_POD" \
  -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)

kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_TOKEN" \
  kubernetes_host="https://kubernetes.default.svc:443" \
  kubernetes_ca_cert="$CA_CERT"

echo -e "${BLUE}7. Creando secretos de ejemplo...${NC}"
kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- \
  vault kv put secret/mi-app/db username="appuser" password="changeme"

kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- \
  vault kv put secret/expense/db \
    username="expense_user" \
    password="S3cret!Vault" \
    url="jdbc:postgresql://postgres-expense:5432/expensedb"

echo -e "${BLUE}8. Creando políticas...${NC}"
kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault policy write mi-app-policy - <<'EOF'
path "secret/data/mi-app/db" {
  capabilities = ["read"]
}
EOF

kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault policy write expense-policy - <<'EOF'
path "secret/data/expense/db" {
  capabilities = ["read"]
}
EOF

echo -e "${BLUE}9. Creando roles de Kubernetes auth...${NC}"
kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault write auth/kubernetes/role/app-con-vault-role \
  bound_service_account_names=default \
  bound_service_account_namespaces=default \
  policies=mi-app-policy \
  ttl=1h

kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault write auth/kubernetes/role/vault-quarkus-demo-role \
  bound_service_account_names=vault-quarkus-demo \
  bound_service_account_namespaces=default \
  policies=mi-app-policy \
  ttl=1h

kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- vault write auth/kubernetes/role/expense-service-role \
  bound_service_account_names=expense-service \
  bound_service_account_namespaces=default \
  policies=expense-policy \
  ttl=1h

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vault listo para usar${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "  Root token : root"
echo "  URL interno: http://vault.vault.svc.cluster.local:8200"
echo ""
echo -e "${YELLOW}Para abrir la UI:${NC}"
echo "  kubectl port-forward -n vault svc/vault 8200:8200"
echo "  http://localhost:8200  (token: root)"
echo ""
echo -e "${YELLOW}Para usar vault CLI:${NC}"
echo "  kubectl port-forward -n vault svc/vault 8200:8200 &"
echo "  export VAULT_ADDR=http://localhost:8200"
echo "  export VAULT_TOKEN=root"
echo "  vault status"
echo ""
echo -e "${YELLOW}Para eliminar Vault:${NC}"
echo "  ./vault-down.sh"
echo ""
