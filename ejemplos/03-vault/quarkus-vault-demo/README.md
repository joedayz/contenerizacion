# Quarkus + Vault Injector Demo

Demo minimo para mostrar como una app Quarkus consume secretos inyectados por Vault Agent Injector en Kubernetes.

## Que demuestra
- Vault escribe `DB_USERNAME` y `DB_PASSWORD` en `/vault/secrets/db`.
- Quarkus lee ese archivo en runtime y expone `GET /vault-demo/secret`.
- El endpoint devuelve solo estado seguro (`dbUsername`, `dbPasswordLength`), no la password.

## Prerrequisitos
- Kubernetes local funcionando (Docker Desktop recomendado para esta clase).
- Vault + Vault Agent Injector instalados y configurados.
- Rol de Vault `mi-app` asociado al ServiceAccount `vault-quarkus-demo` en el namespace de trabajo.
- Secreto KV v2 en `secret/data/mi-app/db` con `username` y `password`.

## Ejecutar en local sin Kubernetes (opcional para validar rapido)

```bash
cd ejemplos/03-vault/quarkus-vault-demo
echo 'export DB_USERNAME="demo"' > /tmp/vault-db.env
echo 'export DB_PASSWORD="demo123"' >> /tmp/vault-db.env
VAULT_SECRET_FILE=/tmp/vault-db.env mvn quarkus:dev
```

```powershell
cd ejemplos/03-vault/quarkus-vault-demo
"export DB_USERNAME=\"demo\"" | Out-File -FilePath "$env:TEMP\vault-db.env"
"export DB_PASSWORD=\"demo123\"" | Out-File -Append -FilePath "$env:TEMP\vault-db.env"
$env:VAULT_SECRET_FILE="$env:TEMP\vault-db.env"
mvn quarkus:dev
```

Probar:

```bash
curl http://localhost:8080/vault-demo/secret
```

## Build de imagen y despliegue en Kubernetes

```bash
cd ejemplos/03-vault/quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .
kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl get pods -l app=vault-quarkus-demo -w
kubectl port-forward svc/vault-quarkus-demo 8082:8080
```

```powershell
cd ejemplos/03-vault/quarkus-vault-demo
mvn clean package
docker build -f src/main/docker/Dockerfile.jvm -t vault-quarkus-demo:latest .
kubectl apply -f k8s/vault-quarkus-demo.yaml
kubectl get pods -l app=vault-quarkus-demo -w
kubectl port-forward svc/vault-quarkus-demo 8082:8080
```

En otra terminal:

```bash
curl http://localhost:8082/vault-demo/secret
```

## Troubleshooting rapido
- Si `secretLoaded=false`, revisar anotaciones del Deployment y path `secret/data/mi-app/db`.
- Si el pod no inyecta secretos, verificar webhook de Vault Injector y que el `role` coincida con ServiceAccount/namespace.
- Si el pod falla en arranque, revisar `kubectl logs deploy/vault-quarkus-demo -c app` y `kubectl describe pod`.

