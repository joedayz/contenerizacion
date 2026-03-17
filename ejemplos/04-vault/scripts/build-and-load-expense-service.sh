#!/usr/bin/env bash
set -euo pipefail

# Construye expense-service y lo carga en un clúster kind (Podman).
# Para Docker Desktop basta con: docker build ... (ver README).

CLUSTER_NAME="${CLUSTER_NAME:-microservices}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

build_and_load() {
  local dir="$1"
  local name="$2"
  local dockerfile="$3"

  echo ""
  echo "=== Building ${name} in ${dir} ==="
  cd "${ROOT_DIR}/${dir}"

  mvn -q package -DskipTests

  local short_tag="${name}:latest"
  podman build -f "${dockerfile}" -t "${short_tag}" .

  echo "Loading ${short_tag} into kind cluster '${CLUSTER_NAME}'..."
  if KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image "${short_tag}" --name "${CLUSTER_NAME}"; then
    echo "Loaded ${short_tag} via docker-image"
  else
    echo "Falling back to image-archive for ${short_tag}"
    mkdir -p "${ROOT_DIR}/${dir}/target"
    local archive_path="${ROOT_DIR}/${dir}/target/${name}-image.tar"
    podman save -o "${archive_path}" "${short_tag}"
    KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive "${archive_path}" --name "${CLUSTER_NAME}"
  fi
}

build_and_load "expense-service" "expense-service" "src/main/docker/Dockerfile.jvm"

echo ""
echo "=== Done: expense-service loaded into kind cluster '${CLUSTER_NAME}' ==="
