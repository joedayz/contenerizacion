# Demo 4: Configuración Dinámica con Consul KV + Vault

> **💡 Usuarios de Windows/PowerShell:** Esta demo incluye scripts PowerShell `01-setup-consul-kv.ps1` y `02-setup-vault-secrets.ps1`. Todos los comandos `bash` tienen equivalentes PowerShell. Ver tabla al final o consultar [../DOCKER-DESKTOP-WINDOWS.md](../DOCKER-DESKTOP-WINDOWS.md).

## 🎯 Objetivo

Demostrar cómo combinar **Consul KV** (para configuración no sensible) y **Vault** (para secretos) para lograr configuración dinámica sin reiniciar aplicaciones.

## 📋 Arquitectura

```
┌────────────────────────────────────────────────────────────┐
│                  Feature Flags Service                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Config       │  │ App Service  │  │ Consul Watch     │  │
│  │ Watcher      │  │              │  │                  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────────┘  │
│         │ Watches         │ Uses             │ Monitors     │
└─────────┼─────────────────┼──────────────────┼──────────────┘
          │                 │                  │
          ▼                 ▼                  ▼
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │ Consul   │      │  Vault   │      │ Consul   │
    │   KV     │      │ Secrets  │      │  Watch   │
    └──────────┘      └──────────┘      └──────────┘
         │                 │
         │ Non-sensitive   │ Sensitive
         │ - Feature flags │ - API keys
         │ - Timeouts      │ - Passwords
         │ - Rate limits   │ - Tokens
         └─────────────────┘
```

## 🔧 Componentes

### 1. Consul KV Store

Almacena configuración no sensible:
- **Feature flags**: Activar/desactivar funcionalidades
- **Rate limits**: Límites de requests por segundo
- **Timeouts**: Configuración de timeouts
- **Cache settings**: TTL de caché

### 2. Vault Secrets

Almacena configuración sensible:
- **API keys**: Para servicios externos
- **Database credentials**: Con rotación automática
- **JWT secrets**: Para autenticación

### 3. Config Service

Aplicación que:
- Lee configuración de Consul KV
- Lee secretos de Vault
- Recarga automáticamente sin reiniciar
- Expone endpoint para ver configuración actual

## 🚀 Paso a Paso

### Paso 1: Configurar Consul KV

```bash
# Cargar configuración inicial
./01-setup-consul-kv.sh
```

Este script crea configuración en Consul KV:

```bash
# Feature flags
consul kv put demo04/config/features/new-ui enabled
consul kv put demo04/config/features/analytics disabled

# Rate limiting
consul kv put demo04/config/ratelimit/requests-per-second 100
consul kv put demo04/config/ratelimit/burst 20

# Cache
consul kv put demo04/config/cache/ttl 300
consul kv put demo04/config/cache/max-size 1000

# Timeouts
consul kv put demo04/config/timeouts/connect 5s
consul kv put demo04/config/timeouts/read 30s
```

### Paso 2: Configurar Vault

```bash
# Cargar secretos
./02-setup-vault-secrets.sh
```

Este script crea secretos en Vault:

```bash
# API keys
vault kv put secret/demo04/api-keys \
  weather-api="sk_prod_abc123xyz" \
  payment-gateway="pk_live_def456uvw"

# JWT secret
vault kv put secret/demo04/jwt \
  secret="super-secret-jwt-key-do-not-share" \
  algorithm="HS256" \
  expiration="3600"
```

### Paso 3: Desplegar Config Service

```bash
# Desplegar servicio
kubectl apply -f config-service.yaml

# Port-forward
kubectl port-forward svc/config-service 8085:8085
```

### Paso 4: Ver configuración actual

```bash
# Ver toda la configuración
curl http://localhost:8085/api/config

# Ver solo feature flags
curl http://localhost:8085/api/config/features

# Ver rate limits
curl http://localhost:8085/api/config/ratelimit
```

**Salida esperada**:

```json
{
  "config": {
    "features": {
      "new-ui": "enabled",
      "analytics": "disabled"
    },
    "ratelimit": {
      "requests-per-second": "100",
      "burst": "20"
    },
    "cache": {
      "ttl": "300",
      "max-size": "1000"
    },
    "timeouts": {
      "connect": "5s",
      "read": "30s"
    }
  },
  "secrets": {
    "apiKeys": {
      "weather-api": "sk_prod_***",
      "payment-gateway": "pk_live_***"
    },
    "jwt": {
      "algorithm": "HS256",
      "expiration": "3600"
    }
  },
  "metadata": {
    "lastUpdate": "2024-03-18T10:30:45Z",
    "source": {
      "config": "consul-kv",
      "secrets": "vault"
    }
  }
}
```

### Paso 5: Cambiar configuración dinámicamente (sin reiniciar)

```bash
# Port-forward a Consul en otra terminal
kubectl port-forward -n consul svc/consul-server 8500:8500

# Cambiar feature flag
consul kv put demo04/config/features/analytics enabled

# INMEDIATAMENTE (sin reiniciar), verificar el cambio
curl http://localhost:8085/api/config/features

# Cambiar rate limit
consul kv put demo04/config/ratelimit/requests-per-second 200

# Verificar
curl http://localhost:8085/api/config/ratelimit
```

**Resultado**: ¡Los cambios se reflejan SIN reiniciar el pod!

### Paso 6: Probar feature flags en acción

```bash
# Endpoint que usa feature flags
curl http://localhost:8085/api/features/new-ui/status

# Si está enabled:
{
  "feature": "new-ui",
  "status": "enabled",
  "message": "New UI is active. Showing modern interface."
}

# Desactivar
consul kv put demo04/config/features/new-ui disabled

# Probar nuevamente (cambio inmediato)
curl http://localhost:8085/api/features/new-ui/status

# Ahora responde:
{
  "feature": "new-ui",
  "status": "disabled",
  "message": "New UI is disabled. Showing classic interface."
}
```

### Paso 7: Observar recargas en los logs

```bash
# Ver logs del config-service
POD=$(kubectl get pods -l app=config-service -o jsonpath='{.items[0].metadata.name}')
kubectl logs -f $POD -c config-service

# Cuando cambias configuración en Consul, verás:
# [INFO] Config change detected in Consul KV
# [INFO] Reloading configuration...
# [INFO] New config applied: features.analytics=enabled
```

## 🔍 Puntos Clave de Aprendizaje

### 1. Separación de Configuración

| Tipo | Dónde | Por qué |
|------|-------|---------|
| **Feature flags** | Consul KV | Cambian frecuentemente, no son sensibles |
| **Rate limits** | Consul KV | Necesitan ajuste rápido sin redeploy |
| **API keys** | Vault | Sensibles, necesitan auditoría |
| **DB passwords** | Vault | Sensibles, rotación automática |
| **Endpoints URLs** | ConfigMap | Dependen del entorno |

### 2. Consul Watch Mechanism

El servicio usa Consul watches para detectar cambios:

```go
// Pseudocódigo
watch := consul.WatchPrefix("demo04/config/")
for change := range watch.Changes() {
    config.Reload(change.Key, change.Value)
    log.Info("Config reloaded:", change.Key)
}
```

### 3. Hot Reload vs Cold Reload

| Tipo | Requiere Restart | Ejemplo |
|------|------------------|---------|
| **Hot Reload** | ❌ No | Feature flags, cache TTL |
| **Cold Reload** | ✅ Sí | Version de Java, dependencias |

### 4. Orden de Precedencia

```
1. Environment Variables (más alta prioridad)
2. Vault Secrets
3. Consul KV
4. ConfigMap
5. Defaults en código (más baja prioridad)
```

## 🧪 Experimentos Sugeridos

### Experimento 1: A/B Testing con Feature Flags

```bash
# Configurar porcentaje de usuarios para nueva feature
consul kv put demo04/config/features/new-algorithm-percentage 10

# Endpoint que respeta el porcentaje
for i in {1..20}; do
  curl -s http://localhost:8085/api/features/test-allocation | jq '.variant'
done

# Ver distribución: ~10% "new", ~90% "old"
```

### Experimento 2: Circuit Breaker Dinámico

```bash
# Configurar circuit breaker
consul kv put demo04/config/circuit-breaker/threshold 5
consul kv put demo04/config/circuit-breaker/timeout 30s

# Simular errores
for i in {1..6}; do
  curl http://localhost:8085/api/external-service
done

# Después de 5 errores, el circuit breaker abre
# Respuesta: {"error":"Circuit breaker is OPEN","retry_after":"30s"}
```

### Experimento 3: Rate Limiting en Tiempo Real

```bash
# Establecer límite bajo
consul kv put demo04/config/ratelimit/requests-per-second 5

# Hacer muchos requests
for i in {1..10}; do
  curl -w "\nStatus: %{http_code}\n" http://localhost:8085/api/data
  sleep 0.1
done

# Primeros 5: HTTP 200
# Siguientes 5: HTTP 429 (Too Many Requests)

# Aumentar límite (sin reiniciar)
consul kv put demo04/config/ratelimit/requests-per-second 50

# Reintentar - ahora todos pasan
```

## 📊 Visualización

### Consul UI - Ver KV Store

```bash
kubectl port-forward -n consul svc/consul-ui 8500:80
# http://localhost:8500/ui/dc1/kv/demo04/config/
```

Navegar el árbol de configuración:
```
demo04/
├── config/
│   ├── features/
│   │   ├── new-ui: enabled
│   │   └── analytics: disabled
│   ├── ratelimit/
│   │   ├── requests-per-second: 100
│   │   └── burst: 20
│   └── cache/
│       ├── ttl: 300
│       └── max-size: 1000
```

### Vault UI - Ver Secrets

```bash
kubectl port-forward -n vault svc/vault 8200:8200
# http://localhost:8200/ui/vault/secrets/secret/list
```

Ver secrets en:
- `secret/demo04/api-keys`
- `secret/demo04/jwt`

## 🎓 Conceptos Avanzados

### 1. Configuration Versioning

Mantener historial de cambios:

```bash
# Consul KV no tiene versionado nativo
# Workaround: Incluir timestamp en la key
consul kv put demo04/config/features/new-ui.v2.2024-03-18 enabled

# O usar Vault que sí tiene versionado
vault kv put -version=2 secret/demo04/api-keys weather-api="new-key"
vault kv get -version=1 secret/demo04/api-keys
```

### 2. Configuration Validation

Validar antes de aplicar:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-schema
data:
  schema.json: |
    {
      "features": {
        "type": "object",
        "properties": {
          "new-ui": {"enum": ["enabled", "disabled"]}
        }
      },
      "ratelimit": {
        "type": "object",
        "properties": {
          "requests-per-second": {"type": "number", "minimum": 1}
        }
      }
    }
```

### 3. Multi-Environment Configuration

```bash
# Estructura por ambiente
consul kv put prod/config/features/new-ui enabled
consul kv put staging/config/features/new-ui enabled
consul kv put dev/config/features/new-ui disabled

# App lee según ENVIRONMENT
export ENVIRONMENT=prod
```

### 4. Configuration as Code

```hcl
# config.hcl - Terraform para Consul KV
resource "consul_keys" "demo04" {
  key {
    path  = "demo04/config/features/new-ui"
    value = "enabled"
  }
  
  key {
    path  = "demo04/config/ratelimit/requests-per-second"
    value = "100"
  }
}
```

## 🧹 Limpieza

```bash
# Eliminar recursos de K8s
kubectl delete -f config-service.yaml

# Limpiar Consul KV
consul kv delete -recurse demo04/

# Limpiar Vault secrets
vault kv metadata delete secret/demo04/api-keys
vault kv metadata delete secret/demo04/jwt
```

## 🐛 Troubleshooting

### Problema: Cambios en Consul KV no se reflejan

**Diagnóstico**:
```bash
# Ver logs de consul watch
kubectl logs $POD -c config-service | grep "Config change"

# Verificar que el watch está activo
kubectl exec $POD -c config-service -- ps aux | grep consul
```

**Solución**: Verificar que el servicio tiene permisos para leer del Consul KV y que el watch está configurado correctamente.

### Problema: Config service no puede leer de Vault

**Solución**:
```bash
# Verificar Vault annotations
kubectl describe pod $POD | grep vault.hashicorp

# Ver logs del vault-agent
kubectl logs $POD -c vault-agent
```

## 📚 Patrones de Uso

### Gradual Feature Rollout

```bash
# Día 1: 10% de usuarios
consul kv put demo04/config/features/new-feature-percentage 10

# Día 3: 25%
consul kv put demo04/config/features/new-feature-percentage 25

# Día 5: 50%
consul kv put demo04/config/features/new-feature-percentage 50

# Día 7: 100%
consul kv put demo04/config/features/new-feature-percentage 100
```

### Emergency Kill Switch

```bash
# Si una feature causa problemas
consul kv put demo04/config/features/problematic-feature disabled

# Cambio inmediato, sin redeploy, sin downtime
```

---

## 🪟 Comandos PowerShell (Windows)

<details>
<summary>Click para ver equivalencias de comandos PowerShell</summary>

### Setup (usa los scripts PowerShell)

```powershell
# Configurar Consul KV
.\01-setup-consul-kv.ps1

# Configurar Vault secrets
.\02-setup-vault-secrets.ps1

# Desplegar servicio
kubectl apply -f config-service.yaml
```

### Ver configuración cargada

```powershell
kubectl logs -l app=config-service -c config-service --tail=40
kubectl logs -l app=config-service -c config-service --follow
```

### Cambiar configuración en caliente

```powershell
# Port-forward a Consul
$consulJob = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-server 8500:8500 }

# Cambiar feature flag via HTTP
$newFeatures = @{
    feature_x = $false
    feature_y = $true
    feature_z = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/config/features" `
    -Method Put -Body $newFeatures -ContentType "application/json"

# Ver los logs - el servicio detecta el cambio
kubectl logs -l app=config-service -c config-service --tail=20

# Detener port-forward
Stop-Job -Job $consulJob; Remove-Job -Job $consulJob
```

### Cambiar rate limiter

```powershell
$consulJob = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-server 8500:8500 }

$newRateLimit = @{
    requests_per_minute = 200
    burst_size = 50
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/config/rate_limiter" `
    -Method Put -Body $newRateLimit

# Ver cambio reflejado
kubectl logs -l app=config-service -c config-service --tail=10

Stop-Job -Job $consulJob; Remove-Job -Job $consulJob
```

### Usar Consul CLI (si instalado)

```powershell
# Port-forward
$consulJob = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-server 8500:8500 }
$env:CONSUL_HTTP_ADDR = "http://localhost:8500"

# Ver todos los keys
consul kv get -recurse demo04/

# Cambiar configuración
$features = @{ feature_x = $false } | ConvertTo-Json
consul kv put demo04/config/features $features

# Limpiar
Stop-Job -Job $consulJob; Remove-Job -Job $consulJob
Remove-Item Env:\CONSUL_HTTP_ADDR
```

### Port-forward a config-service

```powershell
$configJob = Start-Job -ScriptBlock { kubectl port-forward svc/config-service 8084:8080 }

# Hacer requests
Invoke-RestMethod -Uri http://localhost:8084/config/current
Invoke-RestMethod -Uri http://localhost:8084/health

Stop-Job -Job $configJob; Remove-Job -Job $configJob
```

### Rotar secretos de Vault

```powershell
$vaultPod = kubectl get pod -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}'

# Cambiar API key
kubectl exec -n vault $vaultPod -- vault kv put demo04/secrets/api `
    api_key=new-super-secret-key-789 `
    api_secret=new-top-secret-value-abc

# Reiniciar pod
kubectl rollout restart deployment config-service
Start-Sleep -Seconds 20

# Verificar nuevo secret
kubectl logs -l app=config-service -c config-service --tail=15
```

### Ver Consul UI

```powershell
$consulUIJob = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-ui 8500:80 }

# Abrir http://localhost:8500/ui/dc1/kv/demo04/

Stop-Job -Job $consulUIJob; Remove-Job -Job $consulUIJob
```

### Limpieza

```powershell
kubectl delete -f config-service.yaml
kubectl delete sa config-service

# Limpiar Consul KV
$consulJob = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-server 8500:8500 }
$env:CONSUL_HTTP_ADDR = "http://localhost:8500"

if (Get-Command consul -ErrorAction SilentlyContinue) {
    consul kv delete -recurse demo04/
}

Stop-Job -Job $consulJob; Remove-Job -Job $consulJob
```

</details>

---

**¡Configuración dinámica enterprise-grade con Consul KV + Vault!** ⚙️
