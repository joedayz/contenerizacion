# Ejemplos HashiCorp Vault — Guía 04

Estos archivos son **referencia** para integrar Vault con Kubernetes. Requieren Vault y (opcionalmente) Vault Agent Injector instalados en el clúster.

## Contenido de esta carpeta

- `deployment-with-vault-annotations.yaml`: ejemplo base con BusyBox para entender el injector.
- `quarkus-vault-demo/`: demo runnable de Quarkus que consume secretos inyectados por Vault.

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

1. **Habilitar Kubernetes auth y crear el secreto/role en Vault** (usando el KV en `secret/`):

   ```bash
   # Asumiendo que ya tienes VAULT_ADDR y VAULT_TOKEN configurados

   # 1. Habilitar el método de autenticación Kubernetes (solo una vez)
   vault auth enable kubernetes

   # 2. Crear el secreto de ejemplo
   vault kv put secret/mi-app/db username="appuser" password="changeme"

   # 3. Policy con permiso de lectura sobre ese secreto
   vault policy write mi-app-policy - <<EOF
   path "secret/data/mi-app/db" {
     capabilities = ["read"]
   }
   EOF

   # 4. Role de Kubernetes que usará el Deployment (ServiceAccount default en namespace default)
   vault write auth/kubernetes/role/mi-app \
     bound_service_account_names=default \
     bound_service_account_namespaces=default \
     policies=mi-app-policy \
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

Flujo Linux/macOS:

```bash
cd quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .
kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl port-forward svc/vault-quarkus-demo 8082:8080
curl http://localhost:8082/vault-demo/secret
```

Flujo PowerShell:

```powershell
cd quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .
kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl port-forward svc/vault-quarkus-demo 8082:8080
curl http://localhost:8082/vault-demo/secret
```

Ver detalle del demo en `quarkus-vault-demo/README.md`.

## Comandos útiles (en un entorno con Vault CLI)

```bash
vault status
vault auth list
vault kv get secret/mi-app/db
```

## Seguridad

- No subir tokens ni credenciales reales al repositorio.
- En clase usar valores de ejemplo y rotarlos después.
