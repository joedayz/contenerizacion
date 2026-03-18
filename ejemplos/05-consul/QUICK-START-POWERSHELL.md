# Quick Start - Demos Consul + Vault (PowerShell / Docker Desktop)

**Tiempo estimado:** 5 minutos  
**Objetivo:** El camino más rápido de 0 a 4 demos funcionando.

---

## ✅ Pre-requisitos

```powershell
# Verificar herramientas instaladas
kubectl version --client
helm version
docker --version

# Verificar que Docker Desktop tiene Kubernetes habilitado
kubectl cluster-info
```

**IMPORTANT:** En Docker Desktop, ve a Settings > Kubernetes > Enable Kubernetes.

---

## 🚀 Setup Base (2 minutos)

### 1. Instalar Consul

```powershell
cd ejemplos\05-consul\scripts
.\setup-consul.ps1
```

**Resultado esperado:**
```
✅ Consul instalado exitosamente
```

### 2. Instalar Vault

```powershell
.\setup-vault.ps1
```

**Resultado esperado:**
```
✅ Vault instalado exitosamente
Root token: root
```

### 3. Verificar setup

```powershell
.\verify-setup.ps1
```

**Resultado esperado:**
```
✅ Todo está listo para las demos!
```

---

## 🎯 Demo 1: Service Discovery (30 segundos)

```powershell
cd ..\demo-01-discovery
kubectl apply -f .
Start-Sleep -Seconds 5

# Verificar descubrimiento
kubectl logs -l app=order-service --tail=20
```

**¿Qué verás?**
```
Successfully connected to product-service.service.consul
Found product: Laptop
```

**Probar en segundo plano:**
```powershell
kubectl port-forward svc/order-service 8081:8080
# En otro terminal:
Invoke-RestMethod -Uri http://localhost:8081/orders
```

---

## 🎯 Demo 2: Health Checks (1 minuto)

```powershell
cd ..\demo-02-health-checks
kubectl apply -f .
Start-Sleep -Seconds 5

# Ver distribución de carga
kubectl logs -l app=client-service --tail=30
```

**¿Qué verás?**
```
Received: backend-1
Received: backend-2
Received: backend-3
```

**Simular caída de un backend:**
```powershell
$POD = kubectl get pod -l app=backend-service -o jsonpath='{.items[0].metadata.name}'
kubectl exec $POD -- touch /tmp/unhealthy
Start-Sleep -Seconds 15

# Ver logs - ya no usa el backend marcado como unhealthy
kubectl logs -l app=client-service --tail=20
```

**Restaurar:**
```powershell
kubectl exec $POD -- rm /tmp/unhealthy
```

---

## 🎯 Demo 3: Vault + Consul (2 minutos)

```powershell
cd ..\demo-03-vault-consul

# Configurar Vault
.\01-setup-vault.ps1

# Desplegar servicios
kubectl apply -f postgres.yaml
kubectl apply -f user-service.yaml
kubectl apply -f api-gateway.yaml

Start-Sleep -Seconds 30

# Verificar inyección de secretos
kubectl logs -l app=user-service -c user-service --tail=20
```

**¿Qué verás?**
```
DB_USERNAME=myuser
DB_PASSWORD=mypassword123
```

**Probar API:**
```powershell
kubectl port-forward svc/api-gateway 8083:8080
# En otro terminal:
Invoke-RestMethod -Uri http://localhost:8083/users
```

---

## 🎯 Demo 4: Dynamic Config (2 minutos)

```powershell
cd ..\demo-04-dynamic-config

# Configurar Consul KV
.\01-setup-consul-kv.ps1

# Configurar Vault secrets
.\02-setup-vault-secrets.ps1

# Desplegar servicio
kubectl apply -f config-service.yaml

Start-Sleep -Seconds 30

# Ver configuración cargada
kubectl logs -l app=config-service -c config-service --tail=30
```

**¿Qué verás?**
```
📦 Consul Config loaded:
   feature_x: true
   requests_per_minute: 100

🔐 Vault Secrets loaded:
   api_key: super-secret-***
```

**Cambiar configuración en caliente:**
```powershell
# Port-forward a Consul
Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-server 8500:8500 }
$env:CONSUL_HTTP_ADDR = "http://localhost:8500"

# Cambiar feature flag
$config = @{ feature_x = $false; feature_y = $true } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8500/v1/kv/demo04/config/features" `
    -Method Put -Body $config

# Ver logs - el servicio lee el cambio automáticamente
kubectl logs -l app=config-service -c config-service --tail=20
```

---

## 🎨 Explorar las UIs

```powershell
cd ..\scripts
.\port-forward-ui.ps1
```

Luego abre en tu navegador:
- **Consul UI:** http://localhost:8500
- **Vault UI:** http://localhost:8200 (token: `root`)

Presiona `Ctrl+C` para detener los port-forwards.

---

## 🧹 Limpieza

```powershell
cd ..\scripts
.\cleanup.ps1
```

---

## 🆘 Troubleshooting

### Pod en estado "ImagePullBackOff"

```powershell
kubectl describe pod <pod-name>
```

**Solución común:** Las imágenes públicas a veces tardan en descargar. Espera 1-2 minutos.

### Port-forward falla

```powershell
# Verificar que el servicio existe
kubectl get svc

# Verificar que hay pods running
kubectl get pods
```

### Logs vacíos

```powershell
# Ver todos los contenedores del pod
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].name}'

# Especificar contenedor
kubectl logs <pod-name> -c <container-name>
```

### Vault Agent Injector no funciona

```powershell
# Verificar que el injector está running
kubectl get pods -n vault -l app.kubernetes.io/name=vault-agent-injector

# Ver anotaciones del pod
kubectl get pod <pod-name> -o yaml | Select-String -Pattern "vault.hashicorp.com"
```

---

## 📚 Próximos pasos

Una vez que hayas ejecutado todos los demos:

1. Lee [DEMOS-README.md](DEMOS-README.md) para entender la arquitectura a fondo
2. Revisa los README de cada demo para ejercicios adicionales
3. Experimenta cambiando configuraciones y viendo el comportamiento
4. Consulta [../guías/04-hashicorp-vault.md](../../guías/04-hashicorp-vault.md) y [../guías/05-hashicorp-consul.md](../../guías/05-hashicorp-consul.md)

---

**¡Felicitaciones!** 🎉 Ahora tienes experiencia práctica con:
- Service discovery con Consul DNS
- Health checking inteligente
- Inyección de secretos con Vault Agent
- Configuración dinámica desde Consul KV
- Integración completa Vault + Consul
