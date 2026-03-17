Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Limpia todos los recursos de las demos de Vault (namespace default).
# NO toca el namespace vault (Vault server + injector permanecen).

Write-Host "=== Eliminando deployments ==="
kubectl delete deployment app-con-vault vault-quarkus-demo expense-service postgres-expense `
  --ignore-not-found

Write-Host ""
Write-Host "=== Eliminando services ==="
kubectl delete service vault-quarkus-demo expense-service postgres-expense `
  --ignore-not-found

Write-Host ""
Write-Host "=== Eliminando ServiceAccounts ==="
kubectl delete serviceaccount vault-quarkus-demo expense-service `
  --ignore-not-found

Write-Host ""
Write-Host "=== Eliminando PVCs ==="
kubectl delete pvc postgres-expense-pvc `
  --ignore-not-found

Write-Host ""
Write-Host "=== Limpieza completa ==="
Write-Host "Vault (namespace vault) no fue tocado."
kubectl get all
