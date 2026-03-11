#!/bin/sh
set -euo pipefail

# Script para construir y subir imágenes a AWS ECR
# Requiere: aws-setup.sh ejecutado previamente o aws-config.env configurado

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
CONFIG_FILE="$(cd "$(dirname "$0")" && pwd)/aws-config.env"

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

ECR_SERVICE_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SERVICE_REPO}:latest"
ECR_CLIENT_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${CLIENT_REPO}:latest"

echo "=== Build and Push to ECR ==="
echo "Region: ${AWS_REGION}"
echo "Cuenta: ${AWS_ACCOUNT_ID}"
echo "Servicio: ${ECR_SERVICE_IMAGE}"
echo "Cliente : ${ECR_CLIENT_IMAGE}"
echo ""

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: AWS CLI no está instalado."
  exit 1
fi

CONTAINER_CMD=""
if command -v podman >/dev/null 2>&1; then
  CONTAINER_CMD="podman"
  echo "Detectado: Podman"
elif command -v docker >/dev/null 2>&1; then
  CONTAINER_CMD="docker"
  echo "Detectado: Docker"
else
  echo "Error: no se encontró ni podman ni docker."
  exit 1
fi

echo "=== Login a ECR ==="
aws ecr get-login-password --region "${AWS_REGION}" \
  | "${CONTAINER_CMD}" login \
    --username AWS \
    --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo ""

build_and_push() {
  local dir="$1"
  local image="$2"
  local dockerfile="$3"

  echo "=== Building ${image} desde ${dir} ==="
  cd "${ROOT_DIR}/${dir}"

  mvn -q package

  if [ "${CONTAINER_CMD}" = "docker" ] && docker buildx version >/dev/null 2>&1; then
    echo "Usando buildx (linux/amd64)..."
    docker buildx build --platform linux/amd64 -f "${dockerfile}" -t "${image}" --load .
  else
    echo "Construyendo imagen (linux/amd64)..."
    "${CONTAINER_CMD}" build --platform linux/amd64 -f "${dockerfile}" -t "${image}" .
  fi

  echo "=== Pushing ${image} a ECR ==="
  "${CONTAINER_CMD}" push "${image}"
  echo ""
}

build_and_push "ejemplos/02a-kubernetes-local-azure/expense-service" "${ECR_SERVICE_IMAGE}" "src/main/docker/Dockerfile.jvm"
build_and_push "ejemplos/02a-kubernetes-local-azure/expense-client" "${ECR_CLIENT_IMAGE}" "src/main/docker/Dockerfile.jvm"

echo "=== Todas las imágenes construidas y subidas a ECR ==="
echo "Servicio: ${ECR_SERVICE_IMAGE}"
echo "Cliente : ${ECR_CLIENT_IMAGE}"

