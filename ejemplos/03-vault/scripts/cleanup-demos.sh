#!/usr/bin/env bash
set -euo pipefail

# Limpia todos los recursos de las demos de Vault (namespace default).
# NO toca el namespace vault (Vault server + injector permanecen).

echo "=== Eliminando deployments ==="
kubectl delete deployment app-con-vault vault-quarkus-demo expense-service postgres-expense \
  --ignore-not-found

echo ""
echo "=== Eliminando services ==="
kubectl delete service vault-quarkus-demo expense-service postgres-expense \
  --ignore-not-found

echo ""
echo "=== Eliminando ServiceAccounts ==="
kubectl delete serviceaccount vault-quarkus-demo expense-service \
  --ignore-not-found

echo ""
echo "=== Eliminando PVCs ==="
kubectl delete pvc postgres-expense-pvc \
  --ignore-not-found

echo ""
echo "=== Limpieza completa ==="
echo "Vault (namespace vault) no fue tocado."
kubectl get all
