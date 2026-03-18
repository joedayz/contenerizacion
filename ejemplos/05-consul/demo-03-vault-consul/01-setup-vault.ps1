# Script para configurar Vault para Demo 3 (PowerShell)
# Configura autenticación Kubernetes y secretos de PostgreSQL

$ErrorActionPreference = "Stop"

Write-Host "=== Configurando Vault para Demo 3 ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que Vault esté instalado
$vaultPod = & kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($vaultPod)) {
    Write-Host "❌ Vault no está instalado. Ejecuta setup-vault.ps1 primero." -ForegroundColor Red
    exit 1
}

Write-Host "1. Habilitando Kubernetes auth method..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault auth enable kubernetes 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Kubernetes auth ya estaba habilitado" -ForegroundColor Yellow
}

Write-Host "2. Configurando Kubernetes auth..." -ForegroundColor Blue
$K8S_HOST = "https://10.96.0.1:443"  # Default Kubernetes API server
$SA_TOKEN = & kubectl exec -n vault $vaultPod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
$SA_CA_CRT = & kubectl exec -n vault $vaultPod -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt

& kubectl exec -n vault $vaultPod -- vault write auth/kubernetes/config `
    token_reviewer_jwt="$SA_TOKEN" `
    kubernetes_host="$K8S_HOST" `
    kubernetes_ca_cert="$SA_CA_CRT"

Write-Host "3. Habilitando KV secrets engine..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault secrets enable -path=demo03 kv-v2 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  KV secrets engine ya estaba habilitado" -ForegroundColor Yellow
}

Write-Host "4. Creando secretos de PostgreSQL..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault kv put demo03/postgres `
    username=myuser `
    password=mypassword123 `
    host=postgres `
    port=5432 `
    database=mydb

Write-Host "5. Creando policy para user-service..." -ForegroundColor Blue
$POLICY = @'
path "demo03/data/postgres" {
  capabilities = ["read"]
}
'@

& kubectl exec -n vault $vaultPod -- sh -c "echo '$POLICY' | vault policy write user-service-policy -"

Write-Host "6. Creando Kubernetes service account..." -ForegroundColor Blue
& kubectl create serviceaccount user-service --dry-run=client -o yaml | & kubectl apply -f -

Write-Host "7. Vinculando Vault role con service account..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault write auth/kubernetes/role/user-service `
    bound_service_account_names=user-service `
    bound_service_account_namespaces=default `
    policies=user-service-policy `
    ttl=1h

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Vault configurado para Demo 3" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Configuración creada:" -ForegroundColor Yellow
Write-Host "  • Kubernetes auth habilitado" -ForegroundColor White
Write-Host "  • Secretos en: demo03/postgres" -ForegroundColor White
Write-Host "  • Policy: user-service-policy" -ForegroundColor White
Write-Host "  • Role: user-service" -ForegroundColor White
Write-Host "  • ServiceAccount: user-service" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n vault svc/vault 8200:8200" -ForegroundColor White
Write-Host "  `$env:VAULT_ADDR='http://localhost:8200'" -ForegroundColor White
Write-Host "  `$env:VAULT_TOKEN='root'" -ForegroundColor White
Write-Host "  vault kv get demo03/postgres" -ForegroundColor White
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "  kubectl apply -f postgres.yaml" -ForegroundColor White
Write-Host "  kubectl apply -f user-service.yaml" -ForegroundColor White
Write-Host "  kubectl apply -f api-gateway.yaml" -ForegroundColor White
Write-Host ""
