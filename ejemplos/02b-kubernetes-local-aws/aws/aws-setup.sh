#!/bin/sh
set -euo pipefail

# Script para configurar AWS: crear ECR y EKS si no existen
# Uso: ./aws-setup.sh [AWS_REGION] [CLUSTER_NAME]

AWS_REGION="${1:-us-east-1}"
CLUSTER_NAME="${2:-expense-eks}"

echo "=== AWS Setup ==="
echo "Region: ${AWS_REGION}"
echo "Cluster: ${CLUSTER_NAME}"
echo ""

# Verificar herramientas requeridas
for cmd in aws eksctl kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: no se encontró el comando '$cmd' en PATH."
    exit 1
  fi
done

echo "=== Verificando credenciales de AWS ==="
aws sts get-caller-identity >/dev/null
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
echo "Cuenta AWS: ${ACCOUNT_ID}"
echo ""

SERVICE_REPO="expense-service"
CLIENT_REPO="expense-client"

echo "=== Creando repositorios ECR (si no existen) ==="
aws ecr describe-repositories --repository-names "${SERVICE_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "${SERVICE_REPO}" --region "${AWS_REGION}"

aws ecr describe-repositories --repository-names "${CLIENT_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "${CLIENT_REPO}" --region "${AWS_REGION}"

echo ""
echo "Repositorios ECR:"
echo "  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SERVICE_REPO}"
echo "  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${CLIENT_REPO}"
echo ""

echo "=== Creando cluster EKS (si no existe) ==="
if eksctl get cluster --region "${AWS_REGION}" --name "${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "Cluster '${CLUSTER_NAME}' ya existe."
else
  echo "Creando cluster '${CLUSTER_NAME}' (puede tardar varios minutos)..."
  eksctl create cluster \
    --name "${CLUSTER_NAME}" \
    --region "${AWS_REGION}" \
    --nodes 2 \
    --node-type t3.small
fi
echo ""

echo "=== Configurando kubeconfig para EKS ==="
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
echo ""

echo "=== Verificando conexión con EKS ==="
kubectl cluster-info
kubectl get nodes
echo ""

CONFIG_FILE="$(cd "$(dirname "$0")" && pwd)/aws-config.env"
cat > "${CONFIG_FILE}" <<EOF
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${ACCOUNT_ID}
AWS_CLUSTER_NAME=${CLUSTER_NAME}
AWS_ECR_SERVICE_REPO=${SERVICE_REPO}
AWS_ECR_CLIENT_REPO=${CLIENT_REPO}
EOF

echo "=== Configuración completada ==="
echo "Configuración guardada en: ${CONFIG_FILE}"
echo "Para cargarla, ejecuta:"
echo "  source ${CONFIG_FILE}"

