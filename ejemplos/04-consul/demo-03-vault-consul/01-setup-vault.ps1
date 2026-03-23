# Script para configurar Vault para Demo 3 (PowerShell)
# Configura autenticación Kubernetes y secretos de PostgreSQL

# No detener el script en errores, los manejaremos manualmente
$ErrorActionPreference = "Continue"

Write-Host "=== Configurando Vault para Demo 3 ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que Vault esté instalado
$vaultPod = & kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($vaultPod)) {
    Write-Host "❌ Vault no está instalado. Ejecuta setup-vault.ps1 primero." -ForegroundColor Red
    exit 1
}

Write-Host "1. Habilitando Kubernetes auth method..." -ForegroundColor Blue
$authOutput = & kubectl exec -n vault $vaultPod -- vault auth enable kubernetes 2>&1
if ($LASTEXITCODE -ne 0) {
    if ($authOutput -like "*path is already in use*") {
        Write-Host "⚠️  Kubernetes auth ya estaba habilitado" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️  $authOutput" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Kubernetes auth habilitado" -ForegroundColor Green
}

Write-Host "2. Configurando Kubernetes auth..." -ForegroundColor Blue

# Usar heredoc para evitar problemas de escape en PowerShell
& kubectl exec -n vault $vaultPod -- sh -c @'
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://kubernetes.default.svc:443" \
  kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"
'@

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error configurando Kubernetes auth" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Kubernetes auth configurado" -ForegroundColor Green

Write-Host "3. Creando secretos de PostgreSQL..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault kv put secret/demo03/database `
    username="userdb" `
    password="SecureP@ssw0rd2024" `
    host="postgres-db.service.consul" `
    port="5432" `
    database="userdb"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error creando secretos" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Secretos creados" -ForegroundColor Green

Write-Host "4. Creando policy para user-service..." -ForegroundColor Blue
# Crear policy usando stdin
$policyContent = @'
path "secret/data/demo03/database" {
  capabilities = ["read"]
}
path "secret/metadata/demo03/*" {
  capabilities = ["list"]
}
'@

$policyContent | & kubectl exec -i -n vault $vaultPod -- vault policy write user-service-policy -

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error creando policy" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Policy creada" -ForegroundColor Green


if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error creando role" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Role creado" -ForegroundColor Green
Write-Host "5. Vinculando Vault role con service account..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault write auth/kubernetes/role/user-service-role `
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
Write-Host "  • Secretos en: secret/demo03/database" -ForegroundColor White
Write-Host "  • Policy: user-service-policy" -ForegroundColor White
Write-Host "  • Role: user-service-role" -ForegroundColor White
Write-Host "  • ServiceAccount: user-service (en user-service.yaml)" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar:" -ForegroundColor Cyan
Write-Host "  kubectl exec -n vault $vaultPod -- vault kv get secret/demo03/database" -ForegroundColor White
Write-Host "  kubectl exec -n vault $vaultPod -- vault policy read user-service-policy" -ForegroundColor White
Write-Host "  kubectl exec -n vault $vaultPod -- vault read auth/kubernetes/role/user-service-role" -ForegroundColor White
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "  kubectl apply -f postgres.yaml" -ForegroundColor White
Write-Host "  kubectl apply -f user-service.yaml" -ForegroundColor White
Write-Host "  kubectl apply -f api-gateway.yaml" -ForegroundColor White
Write-Host ""
