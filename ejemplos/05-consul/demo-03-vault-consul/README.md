# Demo 3: Integración Vault + Consul

> **💡 Usuarios de Windows/PowerShell:** Esta demo incluye script PowerShell `01-setup-vault.ps1` para configuración. Todos los comandos `bash` tienen equivalentes PowerShell. Ver tabla al final o consultar [../DOCKER-DESKTOP-WINDOWS.md](../DOCKER-DESKTOP-WINDOWS.md).

## 🎯 Objetivo

Demostrar una arquitectura completa donde:
- 🔐 **Vault** maneja secretos (credenciales de BD, API keys)
- 🔍 **Consul** maneja service discovery y health checks
- 📦 **PostgreSQL** como base de datos con credenciales inyectadas desde Vault
- 🚀 **App Quarkus** que usa ambos servicios

## 📋 Arquitectura

```
┌────────────────────────────────────────────────────────────┐
│                     Application Pod                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Vault Agent  │  │ App Service  │  │ Consul Client    │  │
│  │  Sidecar     │  │  (Quarkus)   │  │   (DNS)          │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────────┘  │
│         │                  │                  │              │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          │ 1. Inject        │ 2. Uses          │ 3. Discover
          │    secrets       │    secrets       │    services
          ▼                  ▼                  ▼
    ┌─────────┐        ┌──────────┐      ┌──────────┐
    │  Vault  │        │PostgreSQL│      │  Consul  │
    │ Server  │        │   DB     │      │  Server  │
    └─────────┘        └──────────┘      └──────────┘
          ▲                  ▲                  ▲
          │                  │                  │
          └──────────┬───────┴──────────────────┘
                     │
              Secured by Vault
              Discovered by Consul
```

## 🔧 Componentes

### 1. PostgreSQL Database
- Credenciales almacenadas en Vault
- Registrado en Consul para service discovery
- Health checks automáticos

### 2. User Service (Quarkus)
- API REST CRUD para usuarios
- Recibe credenciales DB desde Vault Agent Injector
- Descubre DB via Consul DNS
- Expone health checks

### 3. API Gateway
- Punto de entrada para los alumnos
- Descubre user-service via Consul
- No tiene acceso directo a la BD

## 🚀 Paso a Paso

### Paso 0: Prerequisitos

```bash
# Verificar que Vault y Consul están instalados
kubectl get pods -n vault
kubectl get pods -n consul

# Si no están instalados, usar los scripts:
cd ../scripts/
./setup-vault.sh
./setup-consul.sh
```

### Paso 1: Configurar Vault

```bash
# Configurar Vault para la demo
./01-setup-vault.sh
```

Este script:
1. Habilita Kubernetes auth method
2. Crea secretos para la base de datos
3. Crea policy para user-service
4. Crea role para inyección de secretos

### Paso 2: Desplegar PostgreSQL

```bash
# Desplegar base de datos
kubectl apply -f postgres.yaml

# Verificar que está registrado en Consul
kubectl exec -n consul consul-server-0 -- \
  consul catalog services | grep postgres
```

### Paso 3: Desplegar User Service

```bash
# Desplegar el servicio (con Vault annotations)
kubectl apply -f user-service.yaml

# Verificar que el Vault Agent se inyectó
kubectl get pods -l app=user-service

# Deberías ver 2/2 containers (app + vault-agent)
```

### Paso 4: Verificar inyección de secretos

```bash
# Ver logs del vault-agent
POD=$(kubectl get pods -l app=user-service -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -c vault-agent-init

# Ver secretos inyectados (deben estar en /vault/secrets/)
kubectl exec $POD -c user-service -- ls -la /vault/secrets/
kubectl exec $POD -c user-service -- cat /vault/secrets/database-config.txt
```

**Salida esperada**:
```
postgresql://userdb:SecureP@ssw0rd@postgres-db.service.consul:5432/userdb
```

### Paso 5: Desplegar API Gateway

```bash
# Desplegar gateway
kubectl apply -f api-gateway.yaml

# Port-forward para acceso
kubectl port-forward svc/api-gateway 8090:8090
```

### Paso 6: Probar la integración completa

```bash
# 1. Crear un usuario
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'

# 2. Listar usuarios
curl http://localhost:8090/api/users

# 3. Obtener un usuario específico
curl http://localhost:8090/api/users/1

# 4. Verificar que usa Consul para discovery
curl http://localhost:8090/api/discovery/info
```

**Salida esperada de /api/discovery/info**:
```json
{
  "gateway": {
    "name": "api-gateway",
    "instance": "api-gateway-xyz-abc"
  },
  "userService": {
    "discoveredVia": "consul-dns",
    "url": "http://user-service.service.consul:8080",
    "healthyInstances": 2
  },
  "database": {
    "discoveredVia": "consul-dns",
    "credentialsFrom": "vault-injector",
    "url": "postgres-db.service.consul:5432"
  }
}
```

## 🔍 Puntos Clave de Aprendizaje

### 1. Vault Agent Injector Annotations

En `user-service.yaml`:

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "user-service-role"
  vault.hashicorp.com/agent-inject-secret-database-config.txt: "secret/data/demo03/database"
  vault.hashicorp.com/agent-inject-template-database-config.txt: |
    {{- with secret "secret/data/demo03/database" -}}
    postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@{{ .Data.data.host }}:{{ .Data.data.port }}/{{ .Data.data.database }}
    {{- end -}}
```

Esto:
- Inyecta un sidecar Vault Agent
- El sidecar autentica usando Kubernetes SA token
- Lee el secreto de Vault
- Escribe el secreto en `/vault/secrets/database-config.txt`
- La app lo lee desde el filesystem

### 2. Consul DNS Resolution

En la aplicación:

```properties
# En application.properties
# NO hardcodeamos IPs o nombres de K8s
quarkus.datasource.jdbc.url=jdbc:postgresql://postgres-db.service.consul:5432/userdb

# Para otros servicios
user.service.url=http://user-service.service.consul:8080
```

Consul resuelve `.service.consul` a IPs de instancias saludables.

### 3. Separación de Responsabilidades

| Componente | Responsable de | NO responsable de |
|------------|----------------|-------------------|
| **Vault** | Secretos sensibles | Service discovery |
| **Consul** | Service discovery, health | Secretos |
| **Kubernetes** | Orquestación, scheduling | Secrets management avanzado |

### 4. Seguridad en Capas

```
Layer 1: Network (K8s NetworkPolicy)
Layer 2: Auth (Vault Kubernetes Auth)
Layer 3: Authorization (Vault Policies)
Layer 4: Encryption (Secrets en tránsito)
Layer 5: Audit (Vault audit logs)
```

## 🧪 Experimentos Sugeridos

### Experimento 1: Rotar credenciales sin downtime

```bash
# 1. Cambiar password en Vault
vault kv put secret/demo03/database \
  username="userdb" \
  password="NewSecureP@ssw0rd123" \
  host="postgres-db.service.consul" \
  port="5432" \
  database="userdb"

# 2. Reiniciar user-service para obtener nuevas credenciales
kubectl rollout restart deployment user-service

# 3. Verificar que sigue funcionando
curl http://localhost:8090/api/users
```

### Experimento 2: Escalar y observar health checks

```bash
# Escalar user-service
kubectl scale deployment user-service --replicas=3

# Ver en Consul que registra las 3 instancias
kubectl exec -n consul consul-server-0 -- \
  consul catalog nodes -service=user-service -detailed

# Hacer requests y ver distribución
for i in {1..10}; do
  curl -s http://localhost:8090/api/discovery/info | jq '.userService'
done
```

### Experimento 3: Simular falla de BD y recuperación

```bash
# 1. Escalar BD a 0 (simular caída)
kubectl scale statefulset postgres-db --replicas=0

# 2. Intentar crear usuario (debería fallar)
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob","email":"bob@example.com"}'

# 3. Ver en Consul que BD está unhealthy
kubectl exec -n consul consul-server-0 -- \
  consul catalog nodes -service=postgres-db

# 4. Recuperar BD
kubectl scale statefulset postgres-db --replicas=1

# 5. Esperar y reintentar
sleep 30
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob","email":"bob@example.com"}'
```

## 📊 Visualización en UIs

### Consul UI

```bash
kubectl port-forward -n consul svc/consul-ui 8500:80
# http://localhost:8500
```

Explorar:
- **Services**: Ver postgres-db, user-service, api-gateway
- **Nodes**: Ver health de cada instancia
- **Intentions**: (Si usas Connect) reglas de comunicación

### Vault UI

```bash
kubectl port-forward -n vault svc/vault 8200:8200
# http://localhost:8200
# Token: root (en dev mode)
```

Explorar:
- **Secrets**: Ver secret/demo03/database
- **Access**: Ver Kubernetes auth method y roles
- **Policies**: Ver user-service-policy

## 🎓 Conceptos Avanzados

### Dynamic Database Credentials

En producción, usa Vault Database Secrets Engine:

```bash
# Vault genera credenciales temporales
vault read database/creds/user-service-role

# Credenciales con TTL (ej: 1 hora)
# Vault revoca automáticamente al expirar
```

### Service Mesh con Consul Connect

Para tráfico encriptado mTLS:

```yaml
annotations:
  "consul.hashicorp.com/connect-inject": "true"
  "consul.hashicorp.com/connect-service": "user-service"
```

Consul inyecta Envoy proxy y maneja mTLS automáticamente.

### Vault Agent Caching

El Vault Agent puede cachear secretos y renovarlos automáticamente:

```yaml
vault.hashicorp.com/agent-cache-enable: "true"
vault.hashicorp.com/agent-revoke-on-shutdown: "true"
```

## 🧹 Limpieza

```bash
# Eliminar todos los recursos de la demo
kubectl delete -f api-gateway.yaml
kubectl delete -f user-service.yaml
kubectl delete -f postgres.yaml

# Limpiar secretos en Vault
vault kv metadata delete secret/demo03/database
vault delete auth/kubernetes/role/user-service-role
vault policy delete user-service-policy
```

## 🐛 Troubleshooting

### Problema: Pod stuck en init (Vault agent no puede autenticar)

**Diagnóstico**:
```bash
kubectl logs $POD -c vault-agent-init
```

**Causa común**: Kubernetes auth method no configurado correctamente.

**Solución**:
```bash
# Reconfigurar Vault
./01-setup-vault.sh
```

### Problema: App no puede conectar a BD

**Diagnóstico**:
```bash
# Ver logs de la app
kubectl logs $POD -c user-service

# Ver secretos inyectados
kubectl exec $POD -c user-service -- cat /vault/secrets/database-config.txt

# Verificar que BD está en Consul
kubectl exec -n consul consul-server-0 -- \
  consul catalog nodes -service=postgres-db
```

### Problema: Consul DNS no resuelve

**Solución**:
```bash
# Verificar configuración de CoreDNS
kubectl get cm coredns -n kube-system -o yaml

# Debería tener forward para .consul
# Si no, ejecutar:
cd ../scripts/
./configure-coredns-consul.sh
```

## 📚 Siguientes Pasos

- **Demo 4**: Configuración dinámica con Consul KV
- **Avanzado**: Implementar service mesh completo
- **Producción**: Dynamic database credentials con Vault

---

## 🪟 Comandos PowerShell (Windows)

<details>
<summary>Click para ver equivalencias de comandos PowerShell</summary>

### Setup

```powershell
# Configurar Vault (usa el script PowerShell)
.\01-setup-vault.ps1

# Desplegar servicios
kubectl apply -f postgres.yaml
kubectl apply -f user-service.yaml
kubectl apply -f api-gateway.yaml
```

### Verificar inyección de secretos

```powershell
# Ver logs de user-service
kubectl logs -l app=user-service -c user-service --tail=20

# Ver el pod completo (con init containers)
$pod = kubectl get pod -l app=user-service -o jsonpath='{.items[0].metadata.name}'
kubectl describe pod $pod
```

### Ver secretos inyectados

```powershell
$pod = kubectl get pod -l app=user-service -o jsonpath='{.items[0].metadata.name}'
kubectl exec $pod -c user-service -- cat /vault/secrets/database-config.txt
```

### Testear aplicación

```powershell
# Port-forward a api-gateway
$gatewayJob = Start-Job -ScriptBlock { kubectl port-forward svc/api-gateway 8083:8080 }

# Hacer requests
Invoke-RestMethod -Uri http://localhost:8083/users
Invoke-RestMethod -Uri http://localhost:8083/api/health

# Detener
Stop-Job -Job $gatewayJob; Remove-Job -Job $gatewayJob
```

### Acceder a Vault UI

```powershell
$vaultJob = Start-Job -ScriptBlock { kubectl port-forward -n vault svc/vault 8200:8200 }

# Abrir http://localhost:8200
# Token: root

# Detener cuando termines
Stop-Job -Job $vaultJob; Remove-Job -Job $vaultJob
```

### Verificar configuración de Vault

```powershell
$vaultPod = kubectl get pod -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}'

# Ver auth methods
kubectl exec -n vault $vaultPod -- vault auth list

# Ver secretos
kubectl exec -n vault $vaultPod -- vault kv get demo03/postgres

# Ver policies
kubectl exec -n vault $vaultPod -- vault policy read user-service-policy
```

### Experimento: Rotar credenciales

```powershell
# Cambiar password en Vault
$vaultPod = kubectl get pod -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}'
kubectl exec -n vault $vaultPod -- vault kv put demo03/postgres `
    username=myuser `
    password=new-password-456 `
    host=postgres `
    port=5432 `
    database=mydb

# Reiniciar pod de user-service
kubectl rollout restart deployment user-service

# Verificar nuevas credenciales
Start-Sleep -Seconds 20
kubectl logs -l app=user-service -c user-service --tail=10
```

### Limpieza

```powershell
kubectl delete -f api-gateway.yaml
kubectl delete -f user-service.yaml
kubectl delete -f postgres.yaml
kubectl delete sa user-service
```

</details>

---

**¡Arquitectura enterprise-ready con Vault + Consul!** 🏗️
