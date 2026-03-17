# Ejemplos HashiCorp Vault — Guía 04

Estos archivos son **referencia** para integrar Vault con Kubernetes. Requieren Vault y (opcionalmente) Vault Agent Injector instalados en el clúster.

## Contenido de esta carpeta

- `deployment-with-vault-annotations.yaml`: ejemplo base con BusyBox para entender el injector.
- `quarkus-vault-demo/`: demo runnable de Quarkus que consume secretos inyectados por Vault.
- `expense-service/`: API REST CRUD (Quarkus + Panache + PostgreSQL) con credenciales inyectadas desde Vault.

## 1. Configuración en Vault (resumen)

- Habilitar **Kubernetes auth method** y configurarlo con la URL del API server de K8s y un token de servicio con permisos para verificar JWTs.
- Habilitar **KV secrets engine** (v2) en una ruta, por ejemplo `secret/`.
- Crear un secreto de prueba:
  ```bash
  vault kv put secret/mi-app/db username="appuser" password="changeme"
  ```
- Crear una **policy** que permita leer esa ruta y un **role** en el auth method de Kubernetes que asocie un ServiceAccount + namespace con esa policy.

## 2. Ejemplo de Deployment con anotaciones (Vault Agent Injector)

El archivo `deployment-with-vault-annotations.yaml` muestra las anotaciones típicas para inyectar secretos de Vault en el Pod. El injector añade un sidecar que escribe los secretos en un volumen compartido.

### Pasos rápidos para probarlo

1. **Habilitar Kubernetes auth, configurarlo y crear el secreto/roles en Vault** (usando el KV en `secret/`):

   ```bash
   # Asumiendo que ya tienes VAULT_ADDR y VAULT_TOKEN configurados

   # 1. Habilitar el método de autenticación Kubernetes (solo una vez)
   vault auth enable kubernetes

   # 2. Configurar el método de autenticación Kubernetes
   #    Como Vault corre dentro del clúster, usamos el servicio interno del API server
   kubectl -n vault exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > ca.crt
   SA_TOKEN=$(kubectl -n vault exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

   vault write auth/kubernetes/config \
     token_reviewer_jwt="$SA_TOKEN" \
     kubernetes_host="https://kubernetes.default.svc:443" \
     kubernetes_ca_cert=@ca.crt

   # 3. Crear el secreto de ejemplo
   vault kv put secret/mi-app/db username="appuser" password="changeme"

   # 4. Policy con permiso de lectura sobre ese secreto
   vault policy write mi-app-policy - <<EOF
   path "secret/data/mi-app/db" {
     capabilities = ["read"]
   }
   EOF

   # 5. Role de Kubernetes para el deployment app-con-vault (ServiceAccount default / namespace default)
   vault write auth/kubernetes/role/app-con-vault-role \
     bound_service_account_names=default \
     bound_service_account_namespaces=default \
     policies=mi-app-policy \
     ttl=1h
   # 6. Role de Kubernetes para el deployment vault-quarkus-demo (ServiceAccount vault-quarkus-demo / namespace default)
   vault write auth/kubernetes/role/vault-quarkus-demo-role \
     bound_service_account_names=vault-quarkus-demo \
     bound_service_account_namespaces=default \
     policies=mi-app-policy \
     ttl=1h

   # 7. Secreto, policy y role para expense-service (ver sección 4)
   vault kv put secret/expense/db username="expense_user" password="S3cret!Vault" url="jdbc:postgresql://postgres-expense:5432/expensedb"
   vault policy write expense-policy - <<EOF
   path "secret/data/expense/db" {
     capabilities = ["read"]
   }
   EOF
   vault write auth/kubernetes/role/expense-service-role \
     bound_service_account_names=expense-service \
     bound_service_account_namespaces=default \
     policies=expense-policy \
     ttl=1h
   ```

2. **Aplicar el Deployment**:

   ```bash
   cd ejemplos/04-vault
   kubectl apply -f deployment-with-vault-annotations.yaml
   kubectl get pods -l app=app-con-vault -w
   ```

3. **Entrar al Pod y ver el archivo inyectado**:

   ```bash
   POD_NAME=$(kubectl get pod -l app=app-con-vault -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -it "$POD_NAME" -- sh
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

- Endpoint de prueba: `GET /vault-demo/secret`
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
  cd ejemplos/04-vault
  chmod +x scripts/build-and-load-vault-quarkus-demo.sh
  CLUSTER_NAME=microservices ./scripts/build-and-load-vault-quarkus-demo.sh
  ```

- **Windows con Docker Desktop**: usa el script `.ps1` en PowerShell:

  ```powershell
  cd ejemplos/04-vault
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

```bash
# Secreto con credenciales de PostgreSQL + URL JDBC interna del clúster
kubectl -n vault exec vault-0 -- \
  vault kv put secret/expense/db \
    username="expense_user" \
    password="S3cret!Vault" \
    url="jdbc:postgresql://postgres-expense:5432/expensedb"

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

### 4.3. Construir y cargar la imagen

#### Caso A: Docker Desktop

```bash
cd expense-service
mvn clean package -DskipTests
docker build -f src/main/docker/Dockerfile.jvm -t expense-service:latest .
```

#### Caso B: Podman + kind

```bash
cd ejemplos/04-vault
chmod +x scripts/build-and-load-expense-service.sh
CLUSTER_NAME=microservices ./scripts/build-and-load-expense-service.sh
```

### 4.4. Desplegar expense-service

```bash
kubectl apply -f expense-service/k8s/expense-service.yaml
kubectl get pods -l app=expense-service -w   # esperar a 2/2 Running
```

### 4.5. Probar

```bash
kubectl port-forward svc/expense-service 8083:8080

# Listar gastos
curl http://localhost:8083/expenses

# Crear un gasto (requiere Associate con id=1 — viene de import.sql)
curl -X POST http://localhost:8083/expenses \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Vault","paymentMethod":"CASH","amount":"42.50","associateId":1}'
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

Ejecuta este bloque completo cada vez que reinicies para dejar Vault listo:

```bash
# ── 1. Habilitar y configurar Kubernetes auth method ──
kubectl -n vault exec vault-0 -- vault auth enable kubernetes

kubectl -n vault exec vault-0 -- sh -c \
  'vault write auth/kubernetes/config \
     kubernetes_host="https://kubernetes.default.svc:443" \
     token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
     kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"'

# ── 2. Secretos de ejemplo ──
kubectl -n vault exec vault-0 -- \
  vault kv put secret/mi-app/db username="appuser" password="changeme"

kubectl -n vault exec vault-0 -- \
  vault kv put secret/expense/db \
    username="expense_user" \
    password="S3cret!Vault" \
    url="jdbc:postgresql://postgres-expense:5432/expensedb"

# ── 3. Policies de lectura ──
kubectl -n vault exec vault-0 -- sh -c \
  'vault policy write mi-app-policy - <<EOF
path "secret/data/mi-app/db" {
  capabilities = ["read"]
}
EOF'

kubectl -n vault exec vault-0 -- sh -c \
  'vault policy write expense-policy - <<EOF
path "secret/data/expense/db" {
  capabilities = ["read"]
}
EOF'

# ── 4. Roles de Kubernetes (uno por deployment) ──
# Role para deployment-with-vault-annotations.yaml (ServiceAccount: default)
kubectl -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/app-con-vault-role \
    bound_service_account_names=default \
    bound_service_account_namespaces=default \
    policies=mi-app-policy \
    ttl=1h

# Role para vault-quarkus-demo (ServiceAccount: vault-quarkus-demo)
kubectl -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/vault-quarkus-demo-role \
    bound_service_account_names=vault-quarkus-demo \
    bound_service_account_namespaces=default \
    policies=mi-app-policy \
    ttl=1h

# Role para expense-service (ServiceAccount: expense-service)
kubectl -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/expense-service-role \
    bound_service_account_names=expense-service \
    bound_service_account_namespaces=default \
    policies=expense-policy \
    ttl=1h
```

Después, si los pods ya estaban desplegados y quedaron en `Init:0/1`, elimínalos para que el Deployment cree pods nuevos que puedan autenticarse:

```bash
kubectl delete pods -l app=vault-quarkus-demo
kubectl delete pods -l app=app-con-vault
kubectl delete pods -l app=expense-service
```

## Comandos útiles (en un entorno con Vault CLI)

```bash
vault status
vault auth list
vault kv get secret/mi-app/db
```

## Seguridad

- No subir tokens ni credenciales reales al repositorio.
- En clase usar valores de ejemplo y rotarlos después.
