# Instala Vault en Kubernetes (Docker Desktop) y lo configura completamente:
#   - Helm install en dev mode con Vault Agent Injector
#   - Kubernetes auth method
#   - Secretos de ejemplo (mi-app/db, expense/db)
#   - Políticas y roles para los deployments de demo
#
# Uso: .\vault-up.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Vault Setup — Docker Desktop ===" -ForegroundColor Cyan
Write-Host ""

# ── Prerrequisitos ────────────────────────────────────────────────────────────
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl no está instalado" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ helm no está instalado" -ForegroundColor Red
    exit 1
}

# ── 1. Instalar Vault via Helm ────────────────────────────────────────────────
Write-Host "1. Agregando Vault Helm repo..." -ForegroundColor Blue
& helm repo add hashicorp https://helm.releases.hashicorp.com
& helm repo update

Write-Host "2. Creando namespace vault..." -ForegroundColor Blue
& kubectl create namespace vault --dry-run=client -o yaml | & kubectl apply -f -

Write-Host "3. Instalando Vault en dev mode (puede tardar 2-3 min)..." -ForegroundColor Blue
Write-Host "   ⚠️  Dev mode: los datos se pierden si el pod se reinicia" -ForegroundColor Yellow
& helm upgrade --install vault hashicorp/vault `
  --namespace vault `
  --set "server.dev.enabled=true" `
  --set "server.dev.devRootToken=root" `
  --set "server.dataStorage.enabled=false" `
  --set "server.service.type=ClusterIP" `
  --set "server.readinessProbe.enabled=false" `
  --set "server.livenessProbe.enabled=false" `
  --set "injector.enabled=true" `
  --set "injector.replicas=1" `
  --set "ui.enabled=true" `
  --set "ui.serviceType=ClusterIP" `
  --wait `
  --timeout 5m

Write-Host "4. Esperando a que Vault esté listo..." -ForegroundColor Blue
& kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

# ── 2. Configurar Vault via kubectl exec ──────────────────────────────────────
$VAULT_NS  = "vault"
$VAULT_POD = "vault-0"

Write-Host ""
Write-Host "5. Habilitando Kubernetes auth method..." -ForegroundColor Blue
& kubectl exec -n $VAULT_NS $VAULT_POD -- vault auth enable kubernetes 2>$null
Write-Host "   OK" -ForegroundColor DarkGray

Write-Host "6. Configurando Kubernetes auth..." -ForegroundColor Blue
$SA_TOKEN = (& kubectl exec -n $VAULT_NS $VAULT_POD -- `
    cat /var/run/secrets/kubernetes.io/serviceaccount/token)
$CA_CERT  = (& kubectl exec -n $VAULT_NS $VAULT_POD -- `
    cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)

& kubectl exec -n $VAULT_NS $VAULT_POD -- vault write auth/kubernetes/config `
    "token_reviewer_jwt=$SA_TOKEN" `
    kubernetes_host="https://kubernetes.default.svc:443" `
    "kubernetes_ca_cert=$CA_CERT"

Write-Host "7. Creando secretos de ejemplo..." -ForegroundColor Blue
& kubectl exec -n $VAULT_NS $VAULT_POD -- `
    vault kv put secret/mi-app/db username=appuser password=changeme

& kubectl exec -n $VAULT_NS $VAULT_POD -- `
    vault kv put secret/expense/db `
        username=expense_user `
        "password=S3cret!Vault" `
        "url=jdbc:postgresql://postgres-expense:5432/expensedb"

Write-Host "8. Creando políticas..." -ForegroundColor Blue
$miAppPolicy = @"
path "secret/data/mi-app/db" {
  capabilities = ["read"]
}
"@
$miAppPolicy | & kubectl exec -i -n $VAULT_NS $VAULT_POD -- vault policy write mi-app-policy -

$expensePolicy = @"
path "secret/data/expense/db" {
  capabilities = ["read"]
}
"@
$expensePolicy | & kubectl exec -i -n $VAULT_NS $VAULT_POD -- vault policy write expense-policy -

Write-Host "9. Creando roles de Kubernetes auth..." -ForegroundColor Blue
& kubectl exec -n $VAULT_NS $VAULT_POD -- vault write auth/kubernetes/role/app-con-vault-role `
    bound_service_account_names=default `
    bound_service_account_namespaces=default `
    policies=mi-app-policy `
    ttl=1h

& kubectl exec -n $VAULT_NS $VAULT_POD -- vault write auth/kubernetes/role/vault-quarkus-demo-role `
    bound_service_account_names=vault-quarkus-demo `
    bound_service_account_namespaces=default `
    policies=mi-app-policy `
    ttl=1h

& kubectl exec -n $VAULT_NS $VAULT_POD -- vault write auth/kubernetes/role/expense-service-role `
    bound_service_account_names=expense-service `
    bound_service_account_namespaces=default `
    policies=expense-policy `
    ttl=1h

# ── Resumen ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Vault listo para usar" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Root token : root" -ForegroundColor Cyan
Write-Host "  URL interno: http://vault.vault.svc.cluster.local:8200" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para abrir la UI:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n vault svc/vault 8200:8200" -ForegroundColor Cyan
Write-Host "  http://localhost:8200  (token: root)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para usar vault CLI:" -ForegroundColor Yellow
Write-Host "  Start-Job { kubectl port-forward -n vault svc/vault 8200:8200 }" -ForegroundColor Cyan
Write-Host "  `$env:VAULT_ADDR='http://localhost:8200'" -ForegroundColor Cyan
Write-Host "  `$env:VAULT_TOKEN='root'" -ForegroundColor Cyan
Write-Host "  vault status" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para eliminar Vault:" -ForegroundColor Yellow
Write-Host "  .\vault-down.ps1" -ForegroundColor Cyan
Write-Host ""
