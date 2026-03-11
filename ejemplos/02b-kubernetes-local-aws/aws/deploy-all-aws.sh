#!/bin/sh
set -euo pipefail

# Script para desplegar en EKS usando imágenes de ECR
# Requiere: aws-setup.sh y build-and-push-all-aws.sh ejecutados previamente

AWS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${AWS_DIR}/../.." && pwd)"
CONFIG_FILE="${AWS_DIR}/aws-config.env"
APP_MANIFEST="${AWS_DIR}/k8s/expenses-all-aws.yaml"

if [ -f "${CONFIG_FILE}" ]; then
  echo "Cargando configuración desde ${CONFIG_FILE}..."
  . "${CONFIG_FILE}"
fi

if [ -z "${AWS_REGION:-}" ] || [ -z "${AWS_ACCOUNT_ID:-}" ]; then
  echo "Error: AWS_REGION o AWS_ACCOUNT_ID no están configurados."
  echo "Ejecuta primero: ./aws-setup.sh"
  exit 1
fi

SERVICE_REPO="${AWS_ECR_SERVICE_REPO:-expense-service}"
CLIENT_REPO="${AWS_ECR_CLIENT_REPO:-expense-client}"

ECR_PREFIX="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Error: no hay conexión con un cluster Kubernetes."
  echo "Asegúrate de haber ejecutado: ./aws-setup.sh"
  exit 1
fi

echo "=== Deploying to EKS ==="
echo "Cluster : ${AWS_CLUSTER_NAME:-<no definido>}"
echo "ECR     : ${ECR_PREFIX}"
echo ""

mkdir -p "${AWS_DIR}/k8s"

SOURCE_MANIFEST="${ROOT_DIR}/02a-kubernetes-local-azure/azure/k8s/expenses-all.yaml"

if [ ! -f "${SOURCE_MANIFEST}" ]; then
  echo "Error: no se encontró el manifest base en:"
  echo "  ${SOURCE_MANIFEST}"
  exit 1
fi

sed \
  -e "s|\${ACR_NAME}.azurecr.io/expense-service|${ECR_PREFIX}/${SERVICE_REPO}|g" \
  -e "s|\${ACR_NAME}.azurecr.io/expense-client|${ECR_PREFIX}/${CLIENT_REPO}|g" \
  "${SOURCE_MANIFEST}" > "${APP_MANIFEST}"

kubectl apply -f "${APP_MANIFEST}"

echo ""
echo "Esperando a que los deployments estén listos..."
kubectl rollout status deployment/expense-service -w --timeout=5m
kubectl rollout status deployment/expense-client -w --timeout=5m

echo ""
echo "=== Despliegue completado ==="
kubectl get pods
kubectl get svc expense-service expense-client

echo ""
echo "Para obtener la URL del cliente (LoadBalancer):"
echo "  kubectl get svc expense-client"
echo ""
echo "O usar port-forward:"
echo "  kubectl port-forward svc/expense-client 8081:8080"
echo "  http://localhost:8081"

