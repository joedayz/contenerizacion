#!/bin/bash
set -e

echo "=== Config Service with Dynamic Configuration (Optimized) ==="

# Esperar a que Vault inyecte los secretos
while [ ! -f /vault/secrets/apikeys.env ]; do
  echo "Waiting for Vault to inject secrets..."
  sleep 2
done

echo "✅ Vault secrets injected"

# Source secrets
source /vault/secrets/apikeys.env
source /vault/secrets/jwt.env

echo "Starting Config Service on port 8085..."
echo "Consul KV prefix: demo04/config/"

# URL de Consul
CONSUL_URL="http://consul-server.consul.svc.cluster.local:8500"

# Cache file
CACHE_FILE="/tmp/consul-cache.json"
touch "$CACHE_FILE"

# Función para refrescar caché desde Consul (1 sola llamada HTTP)
refresh_cache() {
  while true; do
    # Obtener TODAS las keys del prefix en 1 sola llamada
    CONSUL_DATA=$(curl -s "$CONSUL_URL/v1/kv/demo04/config/?recurse" 2>/dev/null || echo "[]")
    
    # Construir JSON desde las keys de Consul
    cat > "$CACHE_FILE" <<EOF
{
  "config": {
    "features": {
      "new-ui": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/features/new-ui") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "analytics": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/features/analytics") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "dark-mode": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/features/dark-mode") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "beta-features": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/features/beta-features") | .Value' | base64 -d 2>/dev/null || echo "not-set")"
    },
    "ratelimit": {
      "requests-per-second": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/ratelimit/requests-per-second") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "burst": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/ratelimit/burst") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "enabled": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/ratelimit/enabled") | .Value' | base64 -d 2>/dev/null || echo "not-set")"
    },
    "cache": {
      "ttl": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/cache/ttl") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "max-size": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/cache/max-size") | .Value' | base64 -d 2>/dev/null || echo "not-set")",
      "enabled": "$(echo "$CONSUL_DATA" | jq -r '.[] | select(.Key=="demo04/config/cache/enabled") | .Value' | base64 -d 2>/dev/null || echo "not-set")"
    }
  },
  "secrets": {
    "apiKeys": {
      "weatherApi": "${WEATHER_API_KEY:0:10}***",
      "paymentGateway": "${PAYMENT_GATEWAY_KEY:0:10}***",
      "mapsApi": "${MAPS_API_KEY:0:10}***",
      "analytics": "$ANALYTICS_ID"
    },
    "jwt": {
      "algorithm": "$JWT_ALGORITHM",
      "expiration": "$JWT_EXPIRATION",
      "issuer": "$JWT_ISSUER"
    }
  },
  "metadata": {
    "lastUpdate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "instance": "$(hostname)",
    "sources": {
      "config": "consul-kv",
      "secrets": "vault-agent-injector"
    },
    "cache": {
      "enabled": true,
      "refreshInterval": "2s"
    }
  }
}
EOF
    
    echo "[$(date)] Cache refreshed from Consul"
    sleep 2
  done
}

# Iniciar refresh de caché en background
refresh_cache &

# Esperar primer refresh
sleep 1

# Función para servir desde caché
serve_http() {
  while true; do
    # Leer desde caché (NO hace llamadas a Consul)
    RESPONSE=$(cat "$CACHE_FILE")
    
    # Servir respuesta HTTP
    echo -ne "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\nCache-Control: no-cache\r\n\r\n$RESPONSE\r\n" | nc -l -p 8085
  done
}

# Servir HTTP desde caché
serve_http
