#!/bin/bash
# Script para instalar y configurar Consul en Kubernetes

set -e

echo "=== Setup Consul para Demos ==="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl no está instalado"
  exit 1
fi

# Verificar helm
if ! command -v helm &> /dev/null; then
  echo "❌ helm no está instalado"
  echo "Instálalo desde: https://helm.sh/docs/intro/install/"
  exit 1
fi

echo -e "${BLUE}1. Agregando Consul Helm repo...${NC}"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo -e "${BLUE}2. Creando namespace consul...${NC}"
kubectl create namespace consul --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}3. Instalando Consul...${NC}"
helm upgrade --install consul hashicorp/consul \
  --namespace consul \
  --set global.name=consul \
  --set server.replicas=1 \
  --set server.bootstrapExpect=1 \
  --set server.storage=1Gi \
  --set ui.enabled=true \
  --set ui.service.type=ClusterIP \
  --set connectInject.enabled=true \
  --set connectInject.default=false \
  --set client.enabled=true \
  --set client.grpc=true \
  --set dns.enabled=true \
  --set dns.enableRedirection=true \
  --set syncCatalog.enabled=true \
  --set syncCatalog.toConsul=true \
  --set syncCatalog.toK8S=false \
  --wait \
  --timeout 5m

echo -e "${BLUE}4. Esperando a que Consul esté listo...${NC}"
kubectl wait --for=condition=Ready pod -l app=consul -n consul --timeout=300s

echo -e "${BLUE}5. Configurando CoreDNS para Consul...${NC}"
# Obtener la IP del servicio consul-dns
CONSUL_DNS_IP=$(kubectl get svc consul-dns -n consul -o jsonpath='{.spec.clusterIP}')
echo "Consul DNS IP: $CONSUL_DNS_IP"

# Verificar si ya existe la configuración
if kubectl get cm coredns -n kube-system -o yaml | grep -q "consul:53"; then
  echo "CoreDNS ya tiene configuración de Consul, omitiendo..."
else
  echo "Configurando CoreDNS para reenviar consultas .consul..."
  
  # Hacer backup
  kubectl get cm coredns -n kube-system -o yaml > /tmp/coredns-backup.yaml
  
  # Obtener el Corefile actual
  COREFILE=$(kubectl get cm coredns -n kube-system -o jsonpath='{.data.Corefile}')
  
  # Añadir configuración de Consul antes del bloque principal
  NEW_COREFILE="consul:53 {
    errors
    cache 30
    forward . ${CONSUL_DNS_IP}
  }
  $COREFILE"
  
  # Actualizar ConfigMap
  kubectl create cm coredns --from-literal=Corefile="$NEW_COREFILE" \
    --dry-run=client -o yaml | kubectl replace -f - -n kube-system
  
  # Reiniciar CoreDNS
  kubectl rollout restart deployment coredns -n kube-system
  kubectl rollout status deployment coredns -n kube-system --timeout=60s
  
  echo "✅ CoreDNS configurado para Consul"
fi

echo -e "${BLUE}6. Verificando instalación...${NC}"
kubectl get pods -n consul
kubectl get svc -n consul

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Consul instalado exitosamente${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Para acceder a la UI de Consul:"
echo "  kubectl port-forward -n consul svc/consul-ui 8500:80"
echo "  Luego abrir: http://localhost:8500"
echo ""
echo "Para usar Consul CLI:"
echo "  export CONSUL_HTTP_ADDR=http://localhost:8500"
echo "  kubectl port-forward -n consul svc/consul-server 8500:8500"
echo "  consul members"
echo ""
