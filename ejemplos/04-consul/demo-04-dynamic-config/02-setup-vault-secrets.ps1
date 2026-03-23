# Script para configurar Vault para Demo 4 (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "=== Configurando Vault Secrets para Demo 4 ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que Vault esté instalado
$vaultPod = & kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($vaultPod)) {
    Write-Host "❌ Vault no está instalado. Ejecuta setup-vault.ps1 primero." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Vault está corriendo" -ForegroundColor Green
Write-Host ""

Write-Host "3. Creando API keys..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault kv put secret/demo04/api-keys `
    weather-api=sk_prod_abc123xyz789 `
    payment-gateway=pk_live_def456uvw012 `
    maps-api=AIzaSyC_maps_key_example `
    analytics=ga_tracking_id_UA-12345
Write-Host "✅ API keys creados" -ForegroundColor Green

Write-Host "4. Creando JWT secrets..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault kv put secret/demo04/jwt `
    secret=super-secret-jwt-key-do-not-share-2024 `
    algorithm=HS256 `
    expiration=3600 `
    issuer=demo-app
Write-Host "✅ JWT secrets creados" -ForegroundColor Green

Write-Host "5. Creando integration secrets..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault kv put secret/demo04/integrations `
    slack-webhook=https://hooks.slack.com/services/T00/B00/xxx `
    github-token=ghp_example_token_123456 `
    sendgrid-api-key=SG.example_key_789
Write-Host "✅ Integration secrets creados" -ForegroundColor Green

Write-Host "6. Creando policy..." -ForegroundColor Blue
$POLICY = @'
path "secret/data/demo04/*" {
  capabilities = ["read"]
}

path "secret/metadata/demo04/*" {
  capabilities = ["list"]
}
'@

$POLICY | & kubectl exec -i -n vault $vaultPod -- vault policy write config-service-policy -
Write-Host "✅ Policy creada" -ForegroundColor Green

Write-Host "7. Creando role..." -ForegroundColor Blue
& kubectl exec -n vault $vaultPod -- vault write auth/kubernetes/role/config-service-role `
    bound_service_account_names=config-service `
    bound_service_account_namespaces=default `
    policies=config-service-policy `
    ttl=1h
Write-Host "✅ Role creado" -ForegroundColor Green

Write-Host ""
Write-Host "8. Verificando configuración..." -ForegroundColor Blue
Write-Host ""
Write-Host "API Keys:" -ForegroundColor Yellow
& kubectl exec -n vault $vaultPod -- vault kv get secret/demo04/api-keys
Write-Host ""
Write-Host "JWT Secrets:" -ForegroundColor Yellow
& kubectl exec -n vault $vaultPod -- vault kv get secret/demo04/jwt
Write-Host ""
Write-Host "Integrations:" -ForegroundColor Yellow
& kubectl exec -n vault $vaultPod -- vault kv get secret/demo04/integrations

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Vault Secrets configurado para Demo 4" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Configuración creada:" -ForegroundColor Yellow
Write-Host "  • API Keys: secret/demo04/api-keys" -ForegroundColor White
Write-Host "  • JWT Secrets: secret/demo04/jwt" -ForegroundColor White
Write-Host "  • Integrations: secret/demo04/integrations" -ForegroundColor White
Write-Host "  • Policy: config-service-policy" -ForegroundColor White
Write-Host "  • Role: config-service-role" -ForegroundColor White
Write-Host "  • ServiceAccount: config-service" -ForegroundColor White
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "  kubectl apply -f config-service.yaml" -ForegroundColor White
Write-Host ""
