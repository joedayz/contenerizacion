# Demo 4: Configuración Dinámica con Consul KV + Vault

> **💡 Multi-plataforma:** Esta guía incluye comandos para **Linux/macOS (bash)** y **Windows (PowerShell)** lado a lado. Scripts disponibles: `01-setup-consul-kv.sh/.ps1` y `02-setup-vault-secrets.sh/.ps1`.

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

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `./01-setup-consul-kv.sh` | `.\01-setup-consul-kv.ps1` |

Este script crea configuración en Consul KV. Ejemplo de comandos que ejecuta:

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/features/new-ui enabled` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-ui enabled` |
| `consul kv put demo04/config/features/analytics disabled` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/analytics disabled` |
| `consul kv put demo04/config/ratelimit/requests-per-second 100` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/ratelimit/requests-per-second 100` |
| `consul kv put demo04/config/ratelimit/burst 20` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/ratelimit/burst 20` |
| `consul kv put demo04/config/cache/ttl 300` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/cache/ttl 300` |
| `consul kv put demo04/config/cache/max-size 1000` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/cache/max-size 1000` |
| `consul kv put demo04/config/timeouts/connect 5s` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/timeouts/connect 5s` |
| `consul kv put demo04/config/timeouts/read 30s` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/timeouts/read 30s` |

### Paso 2: Configurar Vault

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `./02-setup-vault-secrets.sh` | `.\02-setup-vault-secrets.ps1` |

Este script crea secretos en Vault. Ejemplo de comandos que ejecuta:

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `vault kv put secret/demo04/api-keys weather-api="sk_prod_abc123xyz" payment-gateway="pk_live_def456uvw"` | `kubectl exec -n vault vault-0 -- vault kv put secret/demo04/api-keys weather-api="sk_prod_abc123xyz" payment-gateway="pk_live_def456uvw"` |
| `vault kv put secret/demo04/jwt secret="super-secret-jwt-key" algorithm="HS256" expiration="3600"` | `kubectl exec -n vault vault-0 -- vault kv put secret/demo04/jwt secret="super-secret-jwt-key" algorithm="HS256" expiration="3600"` |

### Paso 3: Construir y cargar imagen

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `./build-and-load.sh` | `.\build-and-load.ps1` |

Este script construye la imagen Docker del config-service y la carga en Docker Desktop o Kind.

### Paso 4: Desplegar Config Service

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl apply -f config-service.yaml` | `kubectl apply -f config-service.yaml` |
| `kubectl port-forward svc/config-service 8085:8085` | `kubectl port-forward svc/config-service 8085:8085` |

### Paso 5: Ver configuración actual

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `curl http://localhost:8085/api/config` | `irm http://localhost:8085/api/config` |
| `curl http://localhost:8085/api/config/features` | `irm http://localhost:8085/api/config/features` |
| `curl http://localhost:8085/api/config/ratelimit` | `irm http://localhost:8085/api/config/ratelimit` |

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

### Paso 6: Cambiar configuración dinámicamente (sin reiniciar)
| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl port-forward -n consul svc/consul-server 8500:8500` | `kubectl port-forward -n consul svc/consul-server 8500:8500` |

**Cambiar feature flag** (en otra terminal):

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/features/analytics enabled` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/analytics enabled` |

**Verificar el cambio INMEDIATAMENTE (sin reiniciar):**

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `curl http://localhost:8085/api/config/features` | `irm http://localhost:8085/api/config/features` |

**Cambiar rate limit:**

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/ratelimit/requests-per-second 200` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/ratelimit/requests-per-second 200` |
| `curl http://localhost:8085/api/config/ratelimit` | `irm http://localhost:8085/api/config/ratelimit` |

**Resultado**: ¡Los cambios se reflejan SIN reiniciar el pod!

### Paso 7: Probar feature flags en acción

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `curl http://localhost:8085/api/features/new-ui/status` | `irm http://localhost:8085/api/features/new-ui/status` |

**Si está enabled:**
```json
{
  "feature": "new-ui",
  "status": "enabled",
  "message": "New UI is active. Showing modern interface."
}
```

**Desactivar:**

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/features/new-ui disabled` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-ui disabled` |
| `curl http://localhost:8085/api/features/new-ui/status` | `irm http://localhost:8085/api/features/new-ui/status` |

**Ahora responde:**
```json
{
  "feature": "new-ui",
  "status": "disabled",
  "message": "New UI is disabled. Showing classic interface."
}
```

### Paso 8: Observar recargas en los logs

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `POD=$(kubectl get pods -l app=config-service -o jsonpath='{.items[0].metadata.name}')` | `$POD = kubectl get pods -l app=config-service -o jsonpath='{.items[0].metadata.name}'` |
| `kubectl logs -f $POD -c config-service` | `kubectl logs -f $POD -c config-service` |

**Cuando cambias configuración en Consul, verás:**
```
[INFO] Config change detected in Consul KV
[INFO] Reloading configuration...
[INFO] New config applied: features.analytics=enabled
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

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/features/new-algorithm-percentage 10` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-algorithm-percentage 10` |
| `for i in {1..20}; do curl -s http://localhost:8085/api/features/test-allocation \| jq '.variant'; done` | `1..20 \| ForEach-Object { (irm http://localhost:8085/api/features/test-allocation).variant }` |

Ver distribución: ~10% "new", ~90% "old"

### Experimento 2: Circuit Breaker Dinámico

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/circuit-breaker/threshold 5` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/circuit-breaker/threshold 5` |
| `consul kv put demo04/config/circuit-breaker/timeout 30s` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/circuit-breaker/timeout 30s` |
| `for i in {1..6}; do curl http://localhost:8085/api/external-service; done` | `1..6 \| ForEach-Object { irm http://localhost:8085/api/external-service }` |

Después de 5 errores, el circuit breaker abre:
```json
{"error":"Circuit breaker is OPEN","retry_after":"30s"}
```

### Experimento 3: Rate Limiting en Tiempo Real

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/ratelimit/requests-per-second 5` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/ratelimit/requests-per-second 5` |
| `for i in {1..10}; do curl -w "\nStatus: %{http_code}\n" http://localhost:8085/api/data; sleep 0.1; done` | `1..10 \| ForEach-Object { try { irm http://localhost:8085/api/data } catch { $_.Exception.Response.StatusCode.value__ }; Start-Sleep -Milliseconds 100 }` |

Primeros 5: HTTP 200, Siguientes 5: HTTP 429 (Too Many Requests)

**Aumentar límite (sin reiniciar):**

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/ratelimit/requests-per-second 50` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/ratelimit/requests-per-second 50` |

Reintentar - ahora todos pasan

## 📊 Visualización

### Consul UI - Ver KV Store

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl port-forward -n consul svc/consul-ui 8500:80` | `kubectl port-forward -n consul svc/consul-ui 8500:80` |

Abrir: http://localhost:8500/ui/dc1/kv/demo04/config/

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

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl port-forward -n vault svc/vault 8200:8200` | `kubectl port-forward -n vault svc/vault 8200:8200` |

Abrir: http://localhost:8200/ui/vault/secrets/secret/list

Ver secrets en:
- `secret/demo04/api-keys`
- `secret/demo04/jwt`

## 🎓 Conceptos Avanzados

### 1. Configuration Versioning

Mantener historial de cambios:

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/features/new-ui.v2.2024-03-18 enabled` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-ui.v2.2024-03-18 enabled` |
| `vault kv put -version=2 secret/demo04/api-keys weather-api="new-key"` | `kubectl exec -n vault vault-0 -- vault kv put secret/demo04/api-keys weather-api="new-key"` |
| `vault kv get -version=1 secret/demo04/api-keys` | `kubectl exec -n vault vault-0 -- vault kv get -version=1 secret/demo04/api-keys` |

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

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put prod/config/features/new-ui enabled` | `kubectl exec -n consul consul-server-0 -- consul kv put prod/config/features/new-ui enabled` |
| `consul kv put staging/config/features/new-ui enabled` | `kubectl exec -n consul consul-server-0 -- consul kv put staging/config/features/new-ui enabled` |
| `consul kv put dev/config/features/new-ui disabled` | `kubectl exec -n consul consul-server-0 -- consul kv put dev/config/features/new-ui disabled` |
| `export ENVIRONMENT=prod` | `$env:ENVIRONMENT="prod"` |

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

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl delete -f config-service.yaml` | `kubectl delete -f config-service.yaml` |
| `consul kv delete -recurse demo04/` | `kubectl exec -n consul consul-server-0 -- consul kv delete -recurse demo04/` |
| `vault kv metadata delete secret/demo04/api-keys` | `kubectl exec -n vault vault-0 -- vault kv metadata delete secret/demo04/api-keys` |
| `vault kv metadata delete secret/demo04/jwt` | `kubectl exec -n vault vault-0 -- vault kv metadata delete secret/demo04/jwt` |

## 🐛 Troubleshooting

### Problema: Cambios en Consul KV no se reflejan

**Diagnóstico:**

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl logs $POD -c config-service \| grep "Config change"` | `kubectl logs $POD -c config-service \| Select-String "Config change"` |
| `kubectl exec $POD -c config-service -- ps aux \| grep consul` | `kubectl exec $POD -c config-service -- ps aux` |

**Solución**: Verificar que el servicio tiene permisos para leer del Consul KV y que el watch está configurado correctamente.

### Problema: Config service no puede leer de Vault

**Solución:**

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `kubectl describe pod $POD \| grep vault.hashicorp` | `kubectl describe pod $POD \| Select-String vault.hashicorp` |
| `kubectl logs $POD -c vault-agent` | `kubectl logs $POD -c vault-agent` |

## 📚 Patrones de Uso

### Gradual Feature Rollout

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| **Día 1: 10%** | |
| `consul kv put demo04/config/features/new-feature-percentage 10` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-feature-percentage 10` |
| **Día 3: 25%** | |
| `consul kv put demo04/config/features/new-feature-percentage 25` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-feature-percentage 25` |
| **Día 5: 50%** | |
| `consul kv put demo04/config/features/new-feature-percentage 50` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-feature-percentage 50` |
| **Día 7: 100%** | |
| `consul kv put demo04/config/features/new-feature-percentage 100` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/new-feature-percentage 100` |

### Emergency Kill Switch

| Linux/macOS (bash) | Windows (PowerShell) |
|-------------------|---------------------|
| `consul kv put demo04/config/features/problematic-feature disabled` | `kubectl exec -n consul consul-server-0 -- consul kv put demo04/config/features/problematic-feature disabled` |

Cambio inmediato, sin redeploy, sin downtime

---

**¡Configuración dinámica enterprise-grade con Consul KV + Vault!** ⚙️
