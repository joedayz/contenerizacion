# Demo 2: Health Checks Dinámicos con Consul


## 🎯 Objetivo

Demostrar cómo Consul monitorea la salud de los servicios y automáticamente quita instancias no saludables del pool de discovery, garantizando alta disponibilidad.

## 📋 Arquitectura

```
┌──────────────────┐
│  client-service  │ 
│  Hace requests   │
└────────┬─────────┘
         │ GET /api/data
         ▼
   Consul DNS Query
   "backend.service.consul"
         │
         ▼
┌────────────────────────────────────┐
│          Consul Registry           │
│  ✅ backend-1 (Healthy)            │
│  ❌ backend-2 (Unhealthy) Excluded │
│  ✅ backend-3 (Healthy)            │
└────────────────────────────────────┘
         │
         ▼ Returns only healthy
┌────────┴─────────┐
│  backend-1 (✅)  │  backend-3 (✅)
│  Recibe tráfico  │  Recibe tráfico
└──────────────────┘
```

## 🔧 Componentes

### 1. backend-service (3 réplicas)

Servicio con health check configurable:

- `GET /api/data` - Devuelve datos
- `GET /q/health` - Health check (puede cambiar estado)
- `POST /admin/health/fail` - Marca como no saludable
- `POST /admin/health/recover` - Marca como saludable

### 2. client-service

Cliente que consume backend y muestra qué instancias reciben tráfico.

## 🚀 Paso a Paso


### Paso 0: Construir las imagenes

```bash
./build-and-load.ps1
```

### Paso 1: Desplegar backend-service

```bash
# Desplegar backend con 3 réplicas
kubectl apply -f backend-service.yaml

# Verificar que las 3 réplicas están corriendo
kubectl get pods -l app=backend-service
```

**Salida esperada**:
```
NAME                              READY   STATUS    RESTARTS   AGE
backend-service-xyz-1             1/1     Running   0          10s
backend-service-xyz-2             1/1     Running   0          10s
backend-service-xyz-3             1/1     Running   0          10s
```

### Paso 2: Verificar Health Checks en Consul

```bash
# Ver el servicio en Consul con detalles de health
kubectl exec -n consul consul-server-0 -- \
  consul catalog nodes -service=backend-service -detailed

# Usando la UI de Consul
kubectl port-forward -n consul svc/consul-ui 8500:80
# Ir a: http://localhost:8500/ui/dc1/services/backend-service
# Ver las 3 instancias como "Passing"
```

### Paso 3: Desplegar client-service

```bash
# Desplegar el cliente
kubectl apply -f client-service.yaml

# Verificar
kubectl get pods -l app=client-service

# Port-forward para acceder
kubectl port-forward svc/client-service 8082:8082
```

### Paso 4: Probar con todas las instancias saludables

```bash
# Hacer múltiples requests para ver distribución
for i in {1..10}; do
  curl -s http://localhost:8082/api/requests | jq '.backend'
done
```

**Salida esperada** (distribución entre las 3 instancias):
```json
{"instance": "backend-service-xyz-1", "status": "healthy"}
{"instance": "backend-service-xyz-3", "status": "healthy"}
{"instance": "backend-service-xyz-1", "status": "healthy"}
{"instance": "backend-service-xyz-2", "status": "healthy"}
...
```

### Paso 5: Simular falla en un backend

```bash
# Obtener nombre de un pod
POD=$(kubectl get pods -l app=backend-service -o jsonpath='{.items[0].metadata.name}')
echo "Marcando como no saludable: $POD"

# Marcar ese pod como no saludable
kubectl exec $POD -- sh -c "touch /tmp/unhealthy"

# Esperar 10-15 segundos para que Consul detecte la falla
sleep 15

# Verificar en Consul
kubectl exec -n consul consul-server-0 -- \
  consul catalog nodes -service=backend-service -detailed
```

### Paso 6: Observar exclusión automática

```bash
# Hacer requests nuevamente
for i in {1..10}; do
  curl -s http://localhost:8082/api/requests | jq '.backend'
done
```

**Resultado esperado**: Solo verás las 2 instancias saludables. La instancia con falla NO recibe tráfico.

```json
{"instance": "backend-service-xyz-2", "status": "healthy"}
{"instance": "backend-service-xyz-3", "status": "healthy"}
{"instance": "backend-service-xyz-2", "status": "healthy"}
// backend-service-xyz-1 NO aparece
```

### Paso 7: Recuperar el backend

```bash
# Recuperar el pod
kubectl exec $POD -- sh -c "rm -f /tmp/unhealthy"

# Esperar 10-15 segundos
sleep 15

# Verificar recuperación
for i in {1..10}; do
  curl -s http://localhost:8082/api/requests | jq '.backend'
done
```

**Resultado**: Las 3 instancias vuelven al pool de distribución.

## 🔍 Puntos Clave de Aprendizaje

### 1. Health Check Configuration

En el manifest `backend-service.yaml`:

```yaml
livenessProbe:
  exec:
    command:
    - sh
    - -c
    - "[ ! -f /tmp/unhealthy ]"
  periodSeconds: 5
readinessProbe:
  exec:
    command:
    - sh
    - -c
    - "[ ! -f /tmp/unhealthy ]"
  periodSeconds: 5
```

Consul respeta los health checks de Kubernetes y además puede tener sus propios checks.

### 2. Automatic Circuit Breaking

Sin configuración adicional:
- ✅ Instancia saludable → Recibe tráfico
- ❌ Instancia no saludable → Excluida automáticamente
- 🔄 Recuperación → Vuelta al pool

### 3. Tipos de Health Checks

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **HTTP** | Endpoint que devuelve 200 | `/q/health` |
| **TCP** | Conexión exitosa al puerto | Puerto 8080 abierto |
| **Script** | Ejecuta comando | `[ -f /tmp/healthy ]` |
| **TTL** | Servicio reporta su estado | Heartbeat cada 30s |

## 🧪 Experimentos Sugeridos

### Experimento 1: Simular latencia alta

```bash
# Agregar latencia a un pod
POD=$(kubectl get pods -l app=backend-service -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- sh -c "sleep 60 &"

# Consul puede configurarse para detectar timeouts
# Ver cómo el cliente maneja la latencia
```

### Experimento 2: Fallar múltiples instancias

```bash
# Fallar 2 de 3 backends
for POD in $(kubectl get pods -l app=backend-service -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | head -2); do
  kubectl exec $POD -- sh -c "touch /tmp/unhealthy"
done

# Esperar y hacer requests
sleep 15
for i in {1..10}; do
  curl -s http://localhost:8082/api/requests | jq
done

# Resultado: Todo el tráfico va al único backend saludable
```

### Experimento 3: Observar métricas de health

```bash
# Ver estadísticas de health checks
kubectl exec -n consul consul-server-0 -- \
  consul monitor -log-level=info | grep health

# En UI de Consul, ir a:
# Services > backend-service > Health Checks
# Ver historial de cambios de estado
```

## 📊 Visualización en Consul UI

1. Abrir UI: `http://localhost:8500`
2. Ir a **Services** > **backend-service**
3. Ver la tabla de instancias con estados:

```
┌────────────────────┬──────────┬─────────────┐
│ Node               │ Status   │ Output      │
├────────────────────┼──────────┼─────────────┤
│ backend-xyz-1      │ ✅ Pass  │ Health OK   │
│ backend-xyz-2      │ ❌ Fail  │ Unhealthy   │
│ backend-xyz-3      │ ✅ Pass  │ Health OK   │
└────────────────────┴──────────┴─────────────┘
```

4. Ver cambios en tiempo real cuando fallas/recuperas instancias

## 🎓 Conceptos Avanzados

### Service Health vs Instance Health

- **Instance Health**: Cada pod individual
- **Service Health**: Agregado de todas las instancias
  - Si al menos 1 instancia está saludable → Servicio disponible
  - Si todas las instancias fallan → Servicio degradado

### Configuración de Umbrales

En producción, puedes configurar:

```hcl
service {
  name = "backend-service"
  
  check {
    http     = "http://localhost:8080/q/health"
    interval = "10s"
    timeout  = "2s"
    
    # Tolerancia a fallos transitorios
    success_before_passing = 2  # 2 checks OK antes de marcar como healthy
    failures_before_critical = 3 # 3 checks fail antes de marcar como unhealthy
  }
}
```

## 🧹 Limpieza

```bash
# Recuperar todos los pods primero
for POD in $(kubectl get pods -l app=backend-service -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec $POD -- sh -c "rm -f /tmp/unhealthy" 2>/dev/null || true
done

# Eliminar recursos
kubectl delete -f backend-service.yaml
kubectl delete -f client-service.yaml
```

## 🐛 Troubleshooting

### Problema: Instancias no se marcan como unhealthy

**Diagnóstico**:
```bash
# Verificar que el readinessProbe detecta el problema
kubectl describe pod $POD | grep -A 10 "Readiness"

# Ver logs del pod
kubectl logs $POD
```

**Solución**: Asegurarse de que el health check está configurado correctamente y el período es razonable (5-10s).

### Problema: Instancia tarda mucho en recuperarse

**Causa**: Los períodos de health check son muy largos.

**Solución**: Ajustar `periodSeconds` a un valor más bajo (5-10s) en dev, 15-30s en prod.

## 📚 Siguientes Pasos

Ahora que entiendes health checks automáticos, continúa con:
- **Demo 3**: Integrar Vault para secrets + Consul para discovery
- **Demo 4**: Configuración dinámica con Consul KV

---

## 🪟 Comandos PowerShell (Windows)

<details>
<summary>Click para ver equivalencias de comandos PowerShell</summary>

### Despliegue

```powershell
kubectl apply -f backend-service.yaml
kubectl apply -f client-service.yaml

# Verificar
kubectl get pods
```

### Ver logs

```powershell
# Ver logs del client
kubectl logs -l app=client-service --tail=30 --follow

# Ver logs de todos los backends
kubectl logs -l app=backend-service --all-containers=true
```

### Marcar backend como unhealthy

```powershell
# Get primer pod de backend
$pod = kubectl get pod -l app=backend-service -o jsonpath='{.items[0].metadata.name}'

# Marcar como unhealthy
kubectl exec $pod -- touch /tmp/unhealthy

# Esperar y ver logs
Start-Sleep -Seconds 15
kubectl logs -l app=client-service --tail=20
```

### Ejecutar experimentos

```powershell
# Escalar backends
kubectl scale deployment backend-service --replicas=5

# Marcar 2 como unhealthy
$pods = kubectl get pod -l app=backend-service -o jsonpath='{.items[*].metadata.name}' -split ' '
kubectl exec $pods[0] -- touch /tmp/unhealthy
kubectl exec $pods[1] -- touch /tmp/unhealthy

# Ver distribución
kubectl logs -l app=client-service --tail=50
```

### Simular recuperación

```powershell
# Eliminar archivo unhealthy de todos
kubectl get pod -l app=backend-service -o jsonpath='{.items[*].metadata.name}' -split ' ' | ForEach-Object {
    kubectl exec $_ -- rm -f /tmp/unhealthy
}
```

### Port-forwarding

```powershell
# Port-forward client-service
$clientJob = Start-Job -ScriptBlock { kubectl port-forward svc/client-service 8082:8082 }

# Hacer requests
Invoke-RestMethod -Uri http://localhost:8082/client/call

# Detener
Stop-Job -Job $clientJob; Remove-Job -Job $clientJob
```

### Limpieza

```powershell
kubectl delete -f backend-service.yaml
kubectl delete -f client-service.yaml
```

</details>

---

**¡Resiliencia automática con Consul!** 🛡️
