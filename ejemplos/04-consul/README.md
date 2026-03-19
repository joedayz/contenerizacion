# Ejemplos HashiCorp Consul + Vault — Guía 04

Este directorio contiene **demos prácticas completas** que muestran cómo **Consul** y **Vault** trabajan juntos en un entorno de microservicios en Kubernetes.

> **💡 Para usuarios de Windows:** Todas las demos incluyen **scripts PowerShell** (`.ps1`) además de bash. Lee [DOCKER-DESKTOP-WINDOWS.md](DOCKER-DESKTOP-WINDOWS.md) para configuración inicial de Docker Desktop.

---

## 📚 Tabla de Contenidos

- [Prerequisitos](#-prerequisitos)
- [Setup Inicial](#-setup-inicial-5-minutos)
- [Demos Disponibles](#-demos-disponibles)
- [Ejecutar las Demos](#-ejecutar-las-demos)
- [Limpieza](#-limpieza)
- [Troubleshooting](#-troubleshooting)
- [Scripts Útiles](#️-scripts-útiles)
- [Conceptos Clave](#-conceptos-clave)
- [Recursos Adicionales](#-recursos-adicionales)

---

## 🔧 Prerequisitos

### Software Necesario

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
# Verificar instalación
kubectl version --client
helm version
consul version  # Opcional
vault version   # Opcional

# Verificar cluster
kubectl get nodes
```

</td>
<td>

```powershell
# Verificar instalación
kubectl version --client
helm version
consul version  # Opcional
vault version   # Opcional

# Verificar cluster
kubectl get nodes
```

</td>
</tr>
</table>

### Clúster Kubernetes

Cualquiera de estos:
- **Docker Desktop con Kubernetes habilitado** (recomendado para Windows)
- Kind
- Minikube
- AKS/EKS (para ambiente cloud)

> **⚠️ Para Windows:** Lee [DOCKER-DESKTOP-WINDOWS.md](DOCKER-DESKTOP-WINDOWS.md) para instrucciones completas de instalación de Docker Desktop, Chocolatey, kubectl, helm, consul y vault CLI.

---

## ⚡ Setup Inicial (5 minutos)

### 1. Instalar Consul y Vault

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
# Desde 04-consul/
cd scripts/

# Instalar Consul (2-3 min)
./setup-consul.sh

# Instalar Vault (1-2 min)
./setup-vault.sh

# Verificar
./verify-setup.sh
```

**Salida esperada:**
```
✅ Todo está listo para las demos!
```

</td>
<td>

```powershell
# Desde 04-consul/
cd scripts

# Instalar Consul (2-3 min)
.\setup-consul.ps1

# Instalar Vault (1-2 min)
.\setup-vault.ps1

# Verificar
.\verify-setup.ps1
```

**Salida esperada:**
```
✅ Todo está listo para las demos!
```

</td>
</tr>
</table>

### 2. Exponer UIs (Opcional pero recomendado)

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
# En una terminal separada
./port-forward-ui.sh
```

</td>
<td>

```powershell
# En una terminal separada
.\port-forward-ui.ps1
```

</td>
</tr>
</table>

Ahora puedes acceder a:
- **Consul UI:** http://localhost:8500
- **Vault UI:** http://localhost:8200 (token: `root`)

---

## 📚 Demos Disponibles

| Demo | Descripción | Tiempo | Dificultad | Conceptos |
|------|-------------|--------|------------|-----------|
| **[Demo 1](demo-01-discovery/)** | Service Discovery básico | 20-30 min | ⭐ Básico | Service registration, DNS resolution, Consul API |
| **[Demo 2](demo-02-health-checks/)** | Health Checks dinámicos | 25-35 min | ⭐⭐ Intermedio | Health checks HTTP, circuit breaking, failover automático |
| **[Demo 3](demo-03-vault-consul/)** | Integración Vault + Consul | 30-40 min | ⭐⭐⭐ Avanzado | Vault Agent Injector, Kubernetes auth, PostgreSQL |
| **[Demo 4](demo-04-dynamic-config/)** | Configuración dinámica | 25-35 min | ⭐⭐⭐ Avanzado | Consul KV store, config reload, feature flags |

### 🎯 Objetivos de Aprendizaje

Al completar estas demos, entenderás:

1. **Service Discovery**: Cómo los servicios se encuentran entre sí sin hardcodear IPs
2. **Health Checks**: Cómo Consul garantiza que solo servicios saludables reciben tráfico
3. **Secrets Management**: Cómo Vault inyecta secretos de forma segura
4. **Configuración Dinámica**: Cómo usar Consul KV junto con Vault para configuración en tiempo real

---

## 🎯 Ejecutar las Demos

### Demo 1: Service Discovery (Más Simple)

**Arquitectura:** Dos microservicios Quarkus:
- **product-service**: API que devuelve productos
- **order-service**: API que consume product-service usando Consul DNS

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
cd demo-01-discovery/

# Desplegar servicios
kubectl apply -f product-service.yaml
kubectl apply -f order-service.yaml

# Esperar a que estén listos
kubectl wait --for=condition=Ready \
  pod -l app=product-service --timeout=60s
kubectl wait --for=condition=Ready \
  pod -l app=order-service --timeout=60s

# Port-forward para probar
kubectl port-forward svc/order-service 8081:8081

# En otra terminal, probar
curl http://localhost:8081/api/orders
```

</td>
<td>

```powershell
cd demo-01-discovery

# Desplegar servicios
kubectl apply -f .

# Esperar a que estén listos
Start-Sleep -Seconds 10

# Verificar descubrimiento en logs
kubectl logs -l app=order-service --tail=20

# Port-forward para probar
kubectl port-forward svc/order-service 8081:8081

# En otra terminal, probar
Invoke-RestMethod -Uri http://localhost:8081/api/orders
```

</td>
</tr>
</table>

**Resultado esperado:** JSON con órdenes que incluyen productos descubiertos vía Consul.

---

### Demo 2: Health Checks

**Arquitectura:** Servicios con health checks simulables:
- **backend-service**: Múltiples réplicas con endpoint de salud
- **client-service**: Consume backends solo si están saludables

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
cd demo-02-health-checks/

# Desplegar
kubectl apply -f backend-service.yaml
kubectl apply -f client-service.yaml

# Esperar
kubectl wait --for=condition=Ready \
  pod -l app=backend-service --timeout=60s
kubectl wait --for=condition=Ready \
  pod -l app=client-service --timeout=60s

# Port-forward
kubectl port-forward \
  svc/client-service 8082:8082

# Probar distribución (5 requests)
for i in {1..5}; do 
  curl -s http://localhost:8082/api/requests \
    | jq '.backend.instance'
done

# Simular falla de un backend
POD=$(kubectl get pods \
  -l app=backend-service \
  -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- touch /tmp/unhealthy

# Esperar y ver que no recibe tráfico
sleep 15
for i in {1..5}; do 
  curl -s http://localhost:8082/api/requests \
    | jq '.backend.instance'
done

# Restaurar
kubectl exec $POD -- rm /tmp/unhealthy
```

</td>
<td>

```powershell
cd demo-02-health-checks

# Desplegar
kubectl apply -f .

# Esperar
Start-Sleep -Seconds 10

# Port-forward
kubectl port-forward `
  svc/client-service 8082:8082

# Probar distribución (5 requests)
1..5 | ForEach-Object {
  (Invoke-RestMethod `
    -Uri http://localhost:8082/api/requests).backend.instance
}

# Simular falla de un backend
$POD = kubectl get pod `
  -l app=backend-service `
  -o jsonpath='{.items[0].metadata.name}'
kubectl exec $POD -- touch /tmp/unhealthy

# Esperar y ver que no recibe tráfico
Start-Sleep -Seconds 15
1..5 | ForEach-Object {
  (Invoke-RestMethod `
    -Uri http://localhost:8082/api/requests).backend.instance
}

# Restaurar
kubectl exec $POD -- rm /tmp/unhealthy
```

</td>
</tr>
</table>

**Resultado esperado:** Verás que el pod "unhealthy" ya no recibe tráfico automáticamente.

---

### Demo 3: Vault + Consul (Más Completa)

**Arquitectura:** Aplicación completa que usa:
- **Vault**: Para credenciales de base de datos
- **Consul**: Para descubrir la base de datos y otros servicios
- **PostgreSQL**: Base de datos con credenciales desde Vault

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
cd demo-03-vault-consul/

# Configurar Vault
./01-setup-vault.sh

# Desplegar
kubectl apply -f postgres.yaml
kubectl wait --for=condition=Ready \
  pod -l app=postgres-db --timeout=120s

kubectl apply -f user-service.yaml
kubectl wait --for=condition=Ready \
  pod -l app=user-service --timeout=120s

kubectl apply -f api-gateway.yaml
kubectl wait --for=condition=Ready \
  pod -l app=api-gateway --timeout=60s

# Port-forward
kubectl port-forward \
  svc/api-gateway 8090:8090

# Probar
curl http://localhost:8090/api/users
curl http://localhost:8090/api/discovery/info \
  | jq
```

</td>
<td>

```powershell
cd demo-03-vault-consul

# Configurar Vault
.\01-setup-vault.ps1

# Desplegar
kubectl apply -f postgres.yaml
kubectl apply -f user-service.yaml
kubectl apply -f api-gateway.yaml

# Esperar
Start-Sleep -Seconds 30

# Verificar inyección de secretos
kubectl logs -l app=user-service `
  -c user-service --tail=20

# Port-forward
kubectl port-forward `
  svc/api-gateway 8090:8090

# Probar
Invoke-RestMethod `
  -Uri http://localhost:8090/api/users
Invoke-RestMethod `
  -Uri http://localhost:8090/api/discovery/info
```

</td>
</tr>
</table>

**Resultado esperado:** Lista de usuarios y metadata mostrando que usa Consul para discovery y Vault para secretos.

---

### Demo 4: Dynamic Config (Más Avanzada)

**Arquitectura:** Aplicación que:
- Lee configuración no sensible desde Consul KV
- Lee secretos desde Vault
- Recarga configuración sin reiniciar (hot reload)

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
cd demo-04-dynamic-config/

# Configurar Consul KV y Vault
./01-setup-consul-kv.sh
./02-setup-vault-secrets.sh

# Desplegar
kubectl apply -f config-service.yaml
kubectl wait --for=condition=Ready \
  pod -l app=config-service --timeout=120s

# Port-forward
kubectl port-forward \
  svc/config-service 8085:8085

# Ver configuración actual
curl http://localhost:8085/api/config | jq

# Port-forward a Consul (otra terminal)
kubectl port-forward -n consul \
  svc/consul-server 8500:8500

# Cambiar un feature flag
consul kv put demo04/config/features/analytics enabled

# Ver el cambio inmediato
curl http://localhost:8085/api/config/features \
  | jq
```

</td>
<td>

```powershell
cd demo-04-dynamic-config

# Configurar Consul KV y Vault
.\01-setup-consul-kv.ps1
.\02-setup-vault-secrets.ps1

# Desplegar
kubectl apply -f config-service.yaml
Start-Sleep -Seconds 30

# Ver config cargada en logs
kubectl logs -l app=config-service `
  -c config-service --tail=30

# Port-forward
kubectl port-forward `
  svc/config-service 8085:8085

# Ver configuración actual
Invoke-RestMethod `
  -Uri http://localhost:8085/api/config

# Port-forward a Consul (otra terminal)
Start-Job -ScriptBlock {
  kubectl port-forward -n consul `
    svc/consul-server 8500:8500
}
$env:CONSUL_HTTP_ADDR = "http://localhost:8500"

# Cambiar feature flag
$config = @{ 
  feature_x = $false
  feature_y = $true 
} | ConvertTo-Json
Invoke-RestMethod `
  -Uri "http://localhost:8500/v1/kv/demo04/config/features" `
  -Method Put -Body $config

# Ver el cambio en logs
kubectl logs -l app=config-service `
  -c config-service --tail=20
```

</td>
</tr>
</table>

**Resultado esperado:** La aplicación detecta el cambio de configuración y lo aplica sin reiniciar.

---

## 🧹 Limpieza

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
cd scripts/
./cleanup.sh
```

</td>
<td>

```powershell
cd scripts
.\cleanup.ps1
```

</td>
</tr>
</table>

---

## 🐛 Troubleshooting

### Pods stuck en Pending

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
kubectl describe pod <pod-name>
# Ver eventos
```

</td>
<td>

```powershell
kubectl describe pod <pod-name>
# Ver eventos
```

</td>
</tr>
</table>

**Solución común:** Falta recursos. Aumenta recursos del cluster o reduce réplicas.

### Consul/Vault no está listo

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
# Ver logs
kubectl logs -n consul -l app=consul
kubectl logs -n vault \
  -l app.kubernetes.io/name=vault

# Reintentar setup
cd scripts/
./cleanup.sh
./setup-consul.sh
./setup-vault.sh
```

</td>
<td>

```powershell
# Ver logs
kubectl logs -n consul -l app=consul
kubectl logs -n vault `
  -l app.kubernetes.io/name=vault

# Reintentar setup
cd scripts
.\cleanup.ps1
.\setup-consul.ps1
.\setup-vault.ps1
```

</td>
</tr>
</table>

### DNS no resuelve .service.consul

**Causa:** CoreDNS no está configurado para forward a Consul.

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
# Verificar configuración
kubectl get cm coredns -n kube-system \
  -o yaml | grep consul
```

</td>
<td>

```powershell
# Verificar configuración
kubectl get cm coredns -n kube-system `
  -o yaml | Select-String -Pattern "consul"
```

</td>
</tr>
</table>

**Solución:** El script `setup-consul.sh` / `setup-consul.ps1` debería configurar esto automáticamente. Si no funciona, ejecuta el script nuevamente.

### Vault Agent Injector no inyecta secretos

<table>
<tr>
<th>Linux/macOS</th>
<th>Windows (PowerShell)</th>
</tr>
<tr>
<td>

```bash
# Verificar que el injector está running
kubectl get pods -n vault \
  -l app.kubernetes.io/name=vault-agent-injector

# Ver anotaciones del pod
kubectl get pod <pod-name> -o yaml \
  | grep vault.hashicorp.com
```

</td>
<td>

```powershell
# Verificar que el injector está running
kubectl get pods -n vault `
  -l app.kubernetes.io/name=vault-agent-injector

# Ver anotaciones del pod
kubectl get pod <pod-name> -o yaml `
  | Select-String -Pattern "vault.hashicorp.com"
```

</td>
</tr>
</table>

---

## 🛠️ Scripts Útiles

La carpeta `scripts/` contiene utilidades en bash (`.sh`) y PowerShell (`.ps1`):

| Script | Descripción |
|--------|-------------|
| `setup-consul` | Instala Consul con configuración optimizada para demos |
| `setup-vault` | Configura Vault con las policies necesarias |
| `verify-setup` | Verifica que todo está funcionando |
| `port-forward-ui` | Expone las UIs de Consul y Vault localmente |
| `cleanup` | Limpia todos los recursos de las demos |

---

## 📋 Conceptos Clave

### Registro de servicios en Consul

Los servicios se pueden registrar por:
- **Archivo de configuración** en los nodos del agente
- **API HTTP** desde la aplicación o un sidecar
- **Kubernetes**: Consul sync catalog registra Services de K8s automáticamente

El archivo `service-definition.json` es un ejemplo de definición JSON para un agente Consul.

### Health Checks

El health check en la definición comprueba que HTTP en el puerto del servicio devuelva 200. Consul marca el servicio como *passing* o *failing* y solo devuelve instancias *passing* en las consultas DNS o API.

### Conceptos a Enfatizar

1. **Consul no es un load balancer**, es un service registry
2. **Vault no es una base de datos**, es un secrets manager
3. La combinación de ambos elimina configuración estática y credenciales hardcodeadas
4. En producción, esto se combina con service mesh (Istio, Linkerd, Consul Connect)

---

## 🎓 Notas para Instructores

### Secuencia Recomendada

1. **Setup** (20 min): Instalar Consul/Vault, explicar arquitectura
2. **Demo 1** (30 min): Service discovery básico - fundamento de todo
3. **Demo 2** (30 min): Health checks - resiliencia automática
4. **Break** (15 min)
5. **Demo 3** (45 min): Integrar Vault para ver el flujo completo
6. **Demo 4** (opcional): Configuración avanzada para grupos avanzados
7. **Q&A y Troubleshooting** (30 min)

### Timing Recomendado (sesión de 3 horas)

- **Introducción + Setup** (30 min): Instalar Consul/Vault y verificar
- **Demo 1** (30 min): Service discovery básico
- **Demo 2** (30 min): Health checks
- **Break** (15 min)
- **Demo 3** (45 min): Integración completa Vault + Consul
- **Q&A y Troubleshooting** (30 min)

---

## 📖 Recursos Adicionales

- [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)
- [Vault on Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Learn Consul](https://learn.hashicorp.com/consul)
- [Learn Vault](https://learn.hashicorp.com/vault)
- Guías del curso:
  - [../guías/04-hashicorp-vault.md](../../guías/04-hashicorp-vault.md)
  - [../guías/05-hashicorp-consul.md](../../guías/05-hashicorp-consul.md)

---

**¡Empieza con la Demo 1!** 🚀
