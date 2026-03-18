# Demo 1: Service Discovery Básico con Consul

> **💡 Usuarios de Windows/PowerShell:** Todos los comandos `bash` en este README tienen equivalentes PowerShell. Ver tabla de conversión al final de este documento o consultar [../DOCKER-DESKTOP-WINDOWS.md](../DOCKER-DESKTOP-WINDOWS.md).

## 🎯 Objetivo

Demostrar cómo dos microservicios se descubren mutuamente usando Consul DNS sin configuración estática de IPs o nombres de host.

## 📋 Arquitectura

```
┌─────────────────┐         Consul DNS          ┌─────────────────┐
│  order-service  │ ──────────────────────────> │ product-service │
│  (Consumer)     │   ¿Dónde está products?     │   (Provider)    │
│  Port: 8081     │ <────────────────────────── │   Port: 8080    │
└─────────────────┘   IP y Port de products     └─────────────────┘
         │                                                │
         └────────────────┬───────────────────────────────┘
                          │
                   ┌──────▼───────┐
                   │    Consul    │
                   │   Registry   │
                   └──────────────┘
```

## 🔧 Componentes

### 1. product-service (Puerto 8080)

Microservicio simple que expone una API de productos:

- `GET /api/products` - Lista de productos
- `GET /q/health` - Health check

### 2. order-service (Puerto 8081)

Microservicio que consume product-service:

- `GET /api/orders` - Lista de órdenes (consulta productos via Consul)
- `GET /api/orders/products` - Proxy directo a products
- `GET /q/health` - Health check

**Punto clave**: order-service NO tiene la IP de product-service hardcodeada. Usa Consul DNS para resolverla.

## 🚀 Paso a Paso

### Paso 1: Desplegar product-service

```bash
# Aplicar el deployment y service de products
kubectl apply -f product-service.yaml

# Verificar que está corriendo
kubectl get pods -l app=product-service
kubectl get svc product-service
```

### Paso 2: Verificar registro en Consul

```bash
# Ver servicios registrados en Consul
kubectl exec -n consul consul-server-0 -- consul catalog services

# Deberías ver 'product-service' en la lista

# Ver detalles del servicio
kubectl exec -n consul consul-server-0 -- consul catalog nodes -service=product-service
```

**Alternativa con UI**:
```bash
# Exponer Consul UI (en otra terminal)
kubectl port-forward -n consul svc/consul-ui 8500:80

# Abrir en navegador: http://localhost:8500
# Ver en Services > product-service
```

### Paso 3: Desplegar order-service

```bash
# Aplicar el deployment y service de orders
kubectl apply -f order-service.yaml

# Verificar que está corriendo
kubectl get pods -l app=order-service
```

### Paso 4: Probar Service Discovery

```bash
# Port-forward para acceder a order-service
kubectl port-forward svc/order-service 8081:8081

# En otra terminal, hacer requests:

# 1. Ver órdenes (internamente consulta products via Consul)
curl http://localhost:8081/api/orders

# 2. Ver productos directamente via proxy
curl http://localhost:8081/api/orders/products

# 3. Ver health check
curl http://localhost:8081/q/health
```

**Salida esperada**:

```json
// GET /api/orders
{
  "orders": [
    {
      "orderId": 1,
      "product": "Laptop",
      "quantity": 2,
      "resolvedVia": "consul-dns"
    }
  ],
  "discoveryInfo": {
    "method": "consul",
    "productServiceUrl": "http://product-service.service.consul:8080"
  }
}
```

### Paso 5: Explorar desde dentro del clúster

```bash
# Crear un pod de debug
kubectl run debug --image=nicolaka/netshoot --rm -it -- bash

# Dentro del pod de debug:

# 1. Resolver el servicio via Consul DNS
nslookup product-service.service.consul

# 2. Hacer request directo
curl http://product-service.service.consul:8080/api/products

# 3. Ver la salud del servicio
consul catalog nodes -service=product-service -detailed

# Salir
exit
```

## 🔍 Puntos Clave de Aprendizaje

### 1. Registro Automático

Los Services de Kubernetes se registran automáticamente en Consul gracias a la configuración de `connectInject` en Consul.

**En product-service.yaml**:
```yaml
metadata:
  annotations:
    "consul.hashicorp.com/connect-inject": "false"  # Solo registro, sin mesh
```

### 2. Resolución DNS

Consul provee un DNS service que resuelve:
- `<service-name>.service.consul` → IPs de instancias saludables

**En order-service** (código Java):
```java
@ConfigProperty(name = "product.service.url", 
                defaultValue = "http://product-service.service.consul:8080")
String productServiceUrl;
```

### 3. Ventajas vs Kubernetes Service

| Aspecto | K8s Service | Consul |
|---------|-------------|--------|
| Service Discovery | Dentro del clúster | Dentro y fuera del clúster |
| Health Checks | Readiness/Liveness | Más granular, customizable |
| Multi-cluster | No nativo | Soporte nativo |
| Service Mesh | Requiere Istio/Linkerd | Consul Connect incluido |

## 🧪 Experimentos Sugeridos

### Experimento 1: Escalar product-service

```bash
# Escalar a 3 réplicas
kubectl scale deployment product-service --replicas=3

# Verificar en Consul que ve las 3 instancias
kubectl exec -n consul consul-server-0 -- \
  consul catalog nodes -service=product-service

# Hacer múltiples requests y ver que se distribuyen
for i in {1..10}; do
  curl http://localhost:8081/api/orders/products
  echo ""
done
```

### Experimento 2: Simular caída de un pod

```bash
# Eliminar un pod de product-service
kubectl delete pod -l app=product-service --force --grace-period=0 | head -1

# Hacer requests inmediatamente - Consul remove el pod caído
curl http://localhost:8081/api/orders
```

### Experimento 3: Comparar con llamada directa a K8s Service

```bash
# Modificar la variable de entorno en order-service
kubectl set env deployment/order-service \
  PRODUCT_SERVICE_URL=http://product-service:8080

# Rehacer el request - funciona igual pero sin visibilidad de Consul
curl http://localhost:8081/api/orders
```

## 🧹 Limpieza

```bash
kubectl delete -f product-service.yaml
kubectl delete -f order-service.yaml
```

## 📚 Siguientes Pasos

Ahora que entiendes service discovery básico, continúa con:
- **Demo 2**: Health Checks dinámicos
- **Demo 3**: Integración con Vault

## 🐛 Troubleshooting

### Problema: orden-service no puede resolver product-service.service.consul

**Solución**:
```bash
# Verificar que Consul DNS está corriendo
kubectl get svc -n consul consul-dns

# Verificar ConfigMap de CoreDNS
kubectl get cm coredns -n kube-system -o yaml | grep consul
```

### Problema: Servicios no aparecen en Consul

**Solución**:
```bash
# Verificar que el sync catalog está activo
kubectl logs -n consul -l component=sync-catalog

# Verificar annotations en el Service
kubectl describe svc product-service
```

---

## 🪟 Comandos PowerShell (Windows)

<details>
<summary>Click para ver equivalencias de comandos PowerShell</summary>

### Despliegue y verificación

```powershell
# Aplicar manifests
kubectl apply -f product-service.yaml
kubectl apply -f order-service.yaml

# Verificar pods
kubectl get pods -l app=product-service
kubectl get pods -l app=order-service

# Ver servicios
kubectl get svc
```

### Port-forwarding en background

```powershell
# Iniciar port-forward en background
$orderJob = Start-Job -ScriptBlock { 
    kubectl port-forward svc/order-service 8081:8081 
}

# Hacer requests
Invoke-RestMethod -Uri http://localhost:8081/api/orders
Invoke-RestMethod -Uri http://localhost:8081/api/orders/products

# Detener port-forward cuando termines
Stop-Job -Job $orderJob
Remove-Job -Job $orderJob
```

### Consultar Consul

```powershell
# Ver servicios en Consul
kubectl exec -n consul consul-server-0 -- consul catalog services

# Ver detalles
kubectl exec -n consul consul-server-0 -- consul catalog nodes -service=product-service
```

### Experimentos

```powershell
# Escalar
kubectl scale deployment product-service --replicas=3

# Loop de requests (PowerShell)
1..10 | ForEach-Object {
    Invoke-RestMethod -Uri http://localhost:8081/api/orders/products
    Write-Host ""
}

# Eliminar un pod
$pod = kubectl get pod -l app=product-service -o jsonpath='{.items[0].metadata.name}'
kubectl delete pod $pod --force --grace-period=0
```

### Limpieza

```powershell
kubectl delete -f product-service.yaml
kubectl delete -f order-service.yaml
```

</details>

---

**¡Listo para la siguiente demo!** 🎉
