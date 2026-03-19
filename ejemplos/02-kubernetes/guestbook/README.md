# Ejemplo: Guestbook (Patrón Frontend + Redis)

## Descripción

Aplicación de libro de visitas que demuestra un patrón clásico de Kubernetes:
- **Redis Leader**: almacenamiento primario de datos.
- **Redis Followers**: réplicas de lectura (escalado horizontal).
- **Frontend**: interfaz de usuario que escribe/lee del Redis.

## Componentes

```
Redis Leader (1 réplica) → datos de escritura
    ↓
Redis Followers (N réplicas) → datos de lectura
    ↓
Frontend (N réplicas) → UI que consume Redis
```

## Desplegar en Docker Desktop

### 1. Crear namespace
```bash
kubectl create namespace curso-local
```

### 2. Aplicar manifiestos en orden
```bash
# Redis Leader
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-leader-deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-leader-service.yaml -n curso-local

# Redis Followers
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-follower-deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-follower-service.yaml -n curso-local

# Frontend
kubectl apply -f ejemplos/02-kubernetes/guestbook/frontend-deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/frontend-service.yaml -n curso-local
```

### 3. Verificar despliegue
```bash
kubectl get pods -n curso-local
kubectl get svc -n curso-local
kubectl describe service frontend -n curso-local
```

### 4. Acceder a la aplicación

#### Opción A: Port Forward (recomendado)
```bash
kubectl port-forward svc/frontend 3000:80 -n curso-local
```
Abre `http://localhost:3000` en tu navegador.

#### Opción B: Exec para debug
```bash
kubectl exec -it <pod-redis-leader> -n curso-local -- redis-cli
# Dentro de redis-cli:
KEYS *
GET guestbook-message
```

## Conceptos clave

- **Stateless Frontend**: Los Pods frontend no guardan estado; lo delegan a Redis.
- **Service Discovery**: El frontend localiza `redis-master:6379` y `redis-follower:6379` por DNS.
- **Scaling**: Puedes escalar replicas de frontend e independientemente
 el número de followers Redis.
- **Leader-Follower Pattern**: Escrituras van al leader, lecturas distribuidas a followers.

## Flujo de datos

1. Usuario escribe en UI (Frontend).
2. Frontend envía PUT/POST al Redis Leader.
3. Redis Leader replica a los Followers.
4. Usuario lee desde UI → Frontend consulta Followers.

## Limpiar
```bash
kubectl delete -f ejemplos/02-kubernetes/guestbook/ -n curso-local
kubectl delete namespace curso-local
```

## Referencia
- Basado en: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
