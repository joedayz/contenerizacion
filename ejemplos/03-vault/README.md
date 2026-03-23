# Ejemplos HashiCorp Vault — Guía 03

Estos archivos son **referencia** para integrar Vault con Kubernetes. Requieren Vault y (opcionalmente) Vault Agent Injector instalados en el clúster.

## Contenido de esta carpeta

- `scripts/vault-up.sh` / `scripts/vault-up.ps1`: **instala Vault vía Helm y lo configura** (k8s auth, secretos, políticas, roles) en un solo paso.
- `scripts/vault-down.sh` / `scripts/vault-down.ps1`: **elimina demos y desinstala Vault** del clúster.
- `scripts/cleanup-demos.sh` / `scripts/cleanup-demos.ps1`: elimina solo los deployments de demo sin tocar Vault.
- `deployment-with-vault-annotations.yaml`: ejemplo base con BusyBox para entender el injector.
- `quarkus-vault-demo/`: demo runnable de Quarkus que consume secretos inyectados por Vault.
- `expense-service/`: API REST CRUD (Quarkus + Panache + PostgreSQL) con credenciales inyectadas desde Vault.

## Inicio rápido (Docker Desktop)

```bash
# Linux / macOS
cd ejemplos/03-vault/scripts
./vault-up.sh        # instala + configura todo
# ... trabajar con las demos ...
./vault-down.sh      # elimina todo cuando termines
```

```powershell
# Windows
cd ejemplos/03-vault/scripts
.\vault-up.ps1       # instala + configura todo
# ... trabajar con las demos ...
.\vault-down.ps1     # elimina todo cuando termines
```

> `vault-up` hace automáticamente: Helm install (dev mode) → kubernetes auth → secretos de ejemplo → políticas → roles.
> No necesitas vault CLI instalado localmente; todo se ejecuta dentro del pod via `kubectl exec`.

## 1. Configuración en Vault (resumen)

- La configuración de Vault para estas demos ya viene automatizada en:
  - `scripts/vault-up.sh`
  - `scripts/vault-up.ps1`
- Estos scripts dejan listo en un solo paso:
  - instalación de Vault + Injector en `vault`
  - Kubernetes auth method configurado
  - secretos de ejemplo (`secret/mi-app/db`, `secret/expense/db`)
  - policies y roles para `app-con-vault`, `vault-quarkus-demo` y `expense-service`
- Si quieres desmontar todo, usa:
  - `scripts/vault-down.sh`
  - `scripts/vault-down.ps1`

## 2. Ejemplo de Deployment con anotaciones (Vault Agent Injector)

El archivo `deployment-with-vault-annotations.yaml` muestra las anotaciones típicas para inyectar secretos de Vault en el Pod. El injector añade un sidecar que escribe los secretos en un volumen compartido.

### Pasos rápidos para probarlo

1. **Preparar Vault con el script automático**:

   **Linux / macOS (bash)**

   ```bash
   cd ejemplos/03-vault/scripts
   ./vault-up.sh
   ```

   **Windows (PowerShell)**

   ```powershell
   cd ejemplos/03-vault/scripts
   .\vault-up.ps1
   ```

2. **Aplicar el Deployment**:

   **Linux / macOS:**
   ```bash
   cd ejemplos/03-vault
   kubectl apply -f deployment-with-vault-annotations.yaml
   kubectl get pods -l app=app-con-vault -w
   ```

   **Windows (PowerShell):**
   ```powershell
   cd ejemplos/03-vault
   kubectl apply -f deployment-with-vault-annotations.yaml
   kubectl get pods -l app=app-con-vault -w
   ```

3. **Entrar al Pod y ver el archivo inyectado**:

   Linux / macOS:

   ```bash
   POD_NAME=$(kubectl get pod -l app=app-con-vault -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -it "$POD_NAME" -- sh
   ```

   PowerShell:

   ```powershell
   $POD_NAME = kubectl get pod -l app=app-con-vault -o jsonpath='{.items[0].metadata.name}'
   kubectl exec -it $POD_NAME -- sh
   ```

   Dentro del contenedor:

   ```sh
   ls -la /vault/secrets
   cat /vault/secrets/db
   exit
   ```

Si ves el contenido del secreto (usuario/contraseña) en `/vault/secrets/db`, significa que el **Vault Agent Injector** y las anotaciones del Deployment están funcionando correctamente.

## 3. Integración Quarkus + Vault (demo lista para clase)

Proyecto: `quarkus-vault-demo/`

**Linux / macOS:**
```bash
cd quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .

kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl get pods -l app=vault-quarkus-demo
```

**Windows (PowerShell):**
```powershell
cd quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .

kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl get pods -l app=vault-quarkus-demo
```

Endpoint de prueba: `GET /vault-demo/secret`
- Lee secretos desde `/vault/secrets/db` (archivo creado por Vault Agent Injector)
- No expone la password completa (solo longitud)

### 3.1. Construir y cargar la imagen de Quarkus

#### Caso A: Kubernetes de Docker Desktop (sin kind, usando Docker como runtime)

```bash
cd quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .

kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl get pods -l app=vault-quarkus-demo
```

En este caso, el clúster usa el mismo daemon de Docker Desktop y encuentra la imagen local `vault-quarkus-demo:latest` **sin pasos adicionales**.  
No es necesario hacer `kind load docker-image` ni subir la imagen a un registry.

#### Caso B: clúster kind (por ejemplo `microservices`)

- **Linux / macOS con Podman**: usa el script `.sh`:

  ```bash
  cd ejemplos/03-vault
  chmod +x scripts/build-and-load-vault-quarkus-demo.sh
  CLUSTER_NAME=microservices ./scripts/build-and-load-vault-quarkus-demo.sh
  ```

- **Windows con Docker Desktop**: usa el script `.ps1` en PowerShell:

  ```powershell
  cd ejemplos/03-vault
  ./scripts/build-and-load-vault-quarkus-demo.ps1 -ClusterName microservices
  ```

Después de ejecutar el script (en cualquiera de los casos):

```bash
kubectl apply -f quarkus-vault-demo/k8s/vault-quarkus-demo.yaml
kubectl get pods -l app=vault-quarkus-demo
```

> Nota: cuando usas **kind**, el clúster tiene su propio daemon interno.  
> Estos scripts se encargan de construir la imagen localmente y hacer `kind load` para que quede disponible dentro del clúster.

### 3.2. Probar el endpoint

Flujo Linux/macOS:

```bash
kubectl port-forward svc/vault-quarkus-demo 8082:8080
curl http://localhost:8082/vault-demo/secret
```

Flujo PowerShell:

```powershell
kubectl port-forward svc/vault-quarkus-demo 8082:8080
curl http://localhost:8082/vault-demo/secret
```

Ver detalle del demo en `quarkus-vault-demo/README.md`.

## 4. Expense Service + PostgreSQL + Vault (demo completa)

Proyecto: `expense-service/` — API REST CRUD de gastos con Hibernate ORM Panache + PostgreSQL.

En esta demo, **Vault inyecta las credenciales de la base de datos** (usuario, contraseña y URL JDBC) directamente como propiedades de Quarkus. No se necesita código Java especial: Quarkus lee el archivo inyectado por Vault Agent gracias a `SMALLRYE_CONFIG_LOCATIONS`.

### 4.1. Desplegar PostgreSQL en el clúster

```bash
kubectl apply -f expense-service/k8s/postgresql.yaml
kubectl get pods -l app=postgres-expense -w   # esperar a Running
```

### 4.2. Crear secreto y role en Vault

> Si ya ejecutaste `scripts/vault-up.sh` o `scripts/vault-up.ps1`, esta configuración ya quedó creada.
> Esta sección es útil como referencia para entender o ajustar la configuración manualmente.

**Linux / macOS (bash)**

```bash
# Secreto con credenciales de PostgreSQL + URL JDBC interna del clúster
kubectl -n vault exec vault-0 -- \
  vault kv put secret/expense/db \
    username='expense_user' \
    password='S3cret!Vault' \
    url='jdbc:postgresql://postgres-expense:5432/expensedb'

# Policy de lectura
kubectl -n vault exec vault-0 -- sh -c \
  'vault policy write expense-policy - <<EOF
path "secret/data/expense/db" {
  capabilities = ["read"]
}
EOF'

# Role vinculado al ServiceAccount expense-service en namespace default
kubectl -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/expense-service-role \
    bound_service_account_names=expense-service \
    bound_service_account_namespaces=default \
    policies=expense-policy \
    ttl=1h
```

**Windows (PowerShell)**

```powershell
# Secreto con credenciales de PostgreSQL + URL JDBC interna del clúster
kubectl -n vault exec vault-0 -- `
  vault kv put secret/expense/db `
    username="expense_user" `
    password="S3cret!Vault" `
    url="jdbc:postgresql://postgres-expense:5432/expensedb"

# Policy de lectura
@"
path "secret/data/expense/db" {
  capabilities = ["read"]
}
"@ | kubectl -n vault exec -i vault-0 -- vault policy write expense-policy -

# Role vinculado al ServiceAccount expense-service en namespace default
kubectl -n vault exec vault-0 -- `
  vault write auth/kubernetes/role/expense-service-role `
    bound_service_account_names=expense-service `
    bound_service_account_namespaces=default `
    policies=expense-policy `
    ttl=1h
```

### 4.3. Construir y cargar la imagen

#### Caso A: Docker Desktop (sin kind)

```bash
cd expense-service
mvn clean package -DskipTests
docker build -f src/main/docker/Dockerfile.jvm -t expense-service:latest .
```

#### Caso B: kind — Linux / macOS (Podman)

```bash
cd ejemplos/03-vault
chmod +x scripts/build-and-load-expense-service.sh
CLUSTER_NAME=microservices ./scripts/build-and-load-expense-service.sh
```

#### Caso C: kind — Windows (Docker + PowerShell)

```powershell
cd ejemplos\03-vault
.\scripts\build-and-load-expense-service.ps1 -ClusterName microservices
```

### 4.4. Desplegar expense-service

```bash
kubectl apply -f expense-service/k8s/expense-service.yaml
kubectl get pods -l app=expense-service -w   # esperar a 2/2 Running
```

### 4.5. Probar

En una terminal aparte, abrir el port-forward (igual en bash o PowerShell):

```bash
kubectl port-forward svc/expense-service 8083:8080
```

**Linux / macOS (bash)**

```bash
# Listar gastos
curl http://localhost:8083/expenses

# Crear un gasto (requiere Associate con id=1 — viene de import.sql)
curl -X POST http://localhost:8083/expenses \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Vault","paymentMethod":"CASH","amount":"42.50","associateId":1}'
```

**Windows (PowerShell)**

```powershell
# Listar gastos
Invoke-RestMethod http://localhost:8083/expenses

# Crear un gasto (requiere Associate con id=1 — viene de import.sql)
$body = @{ name="Test Vault"; paymentMethod="CASH"; amount="42.50"; associateId=1 } | ConvertTo-Json
Invoke-RestMethod http://localhost:8083/expenses -Method Post -ContentType 'application/json' -Body $body
```

### ¿Cómo funciona la inyección?

1. El Vault Agent Injector (init container) se autentica con Vault usando el ServiceAccount `expense-service`.
2. Vault Agent escribe `/vault/secrets/db` con el contenido:
   ```properties
   quarkus.datasource.username=expense_user
   quarkus.datasource.password=S3cret!Vault
   quarkus.datasource.jdbc.url=jdbc:postgresql://postgres-expense:5432/expensedb
   ```
3. La variable de entorno `SMALLRYE_CONFIG_LOCATIONS=/vault/secrets/db` le dice a Quarkus que lea ese archivo como fuente de configuración adicional, **sobreescribiendo** los valores por defecto de `application.properties`.

## ⚠️ Después de reiniciar Kubernetes / Vault (modo dev)

Vault corre en **modo dev** (`dataStorage.enabled: false`), por lo que **toda la configuración se pierde** cada vez que se reinicia el pod de Vault o el clúster de Kubernetes.

Para dejar todo operativo de nuevo, solo vuelve a ejecutar el script de setup:

**Linux / macOS (bash)**

```bash
cd ejemplos/03-vault/scripts
./vault-up.sh
```

**Windows (PowerShell)**

```powershell
cd ejemplos/03-vault/scripts
.\vault-up.ps1
```

Si algunos pods ya estaban desplegados y quedaron en `Init:0/1`, elimínalos para que el Deployment cree pods nuevos que puedan autenticarse:

```bash
kubectl delete pods -l app=vault-quarkus-demo
kubectl delete pods -l app=app-con-vault
kubectl delete pods -l app=expense-service
```

## Comandos útiles (opcional, con Vault CLI local)

**Linux / macOS (bash)**

```bash
vault status
vault auth list
vault kv get secret/mi-app/db
```

**Windows (PowerShell)**

```powershell
vault status
vault auth list
vault kv get secret/mi-app/db
```

## Seguridad

- No subir tokens ni credenciales reales al repositorio.
- En clase usar valores de ejemplo y rotarlos después.
