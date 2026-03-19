# Ejemplo: Voting App (Arquitectura Microservicios Completa)

## Descripción

Aplicación de votación multi-tier que demuestra una **arquitectura microservicios completa** en Kubernetes:

```
Users → Vote (Frontend) → Redis (Cola de votos)
                          ↓
                        Worker (Procesa votos)
                          ↓
                        PostgreSQL (Almacén)
                          ↓
                        Result (Backend - Resultados)
                          ↓
                        UI (Muestra resultados)
```

## Componentes

| Componente | Lenguaje | Rol |
|-----------|----------|-----|
| **vote** | Python | Frontend: interfaz para votar |
| **worker** | Java | Background: procesa votos de Redis → PostgreSQL |
| **db** | PostgreSQL | Persistence: almacena votos |
| **redis** | Redis | Broker: cola de mensajes |
| **result** | Node.js | Backend: API de resultados |

## Desplegar en Docker Desktop

### 1. Crear namespace
```bash
kubectl create namespace voting-app
```

### 2. Aplicar manifiestos (orden recomendado)

#### Datastore (Redis & PostgreSQL)
```bash
# Redis (broker de mensajes)
kubectl apply -f ejemplos/02-kubernetes/voting-app/redis-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/redis-service.yaml -n voting-app

# PostgreSQL (base de datos)
kubectl apply -f ejemplos/02-kubernetes/voting-app/db-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/db-service.yaml -n voting-app
```

#### Aplicación (Frontend, Backend, Worker)
```bash
# Vote (Frontend)
kubectl apply -f ejemplos/02-kubernetes/voting-app/vote-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/vote-service.yaml -n voting-app

# Result (Backend API)
kubectl apply -f ejemplos/02-kubernetes/voting-app/result-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/result-service.yaml -n voting-app

# Worker (Background)
kubectl apply -f ejemplos/02-kubernetes/voting-app/worker-deployment.yaml -n voting-app
```

### 3. Verificar despliegue
```bash
kubectl get pods -n voting-app
kubectl get svc -n voting-app
kubectl get deployments -n voting-app

# Ver logs de cada componente
kubectl logs -l app=vote -n voting-app --tail=20
kubectl logs -l app=worker -n voting-app --tail=20
kubectl logs -l app=result -n voting-app --tail=20
```

### 4. Acceder a la aplicación

#### Opción A: Port Forward (múltiples terminales)
```bash
# Terminal 1: Votación
kubectl port-forward svc/vote 5000:8080 -n voting-app

# Terminal 2: Resultados
kubectl port-forward svc/result 5001:8081 -n voting-app
```

- **Votación**: `http://localhost:5000`
- **Resultados**: `http://localhost:5001`

#### Opción B: Exec para debugging
```bash
# Conectar a PostgreSQL
kubectl exec -it <pod-db> -n voting-app -- psql -U postgres

# Inspeccionar Redis
kubectl exec -it <pod-redis> -n voting-app -- redis-cli
KEYS *
LLEN votes

# Ver logs completos del worker
kubectl logs deploy/worker -n voting-app -f
```

## Flujo de datos

1. **Vote (Frontend)**: Usuario vota (Cat/Dog) → envía a Redis.
2. **Queue**: Redis almacena votos en una cola (`LPUSH`).
3. **Worker (Background)**: Procesa votos de Redis → inserta en PostgreSQL.
4. **Result (Backend)**: Lee PostgreSQL → devuelve JSON con conteo.
5. **Result UI**: Muestra gráfico con resultados en tiempo real.

## Conceptos clave

- **Desacoplamiento**: El Frontend (vote) y Backend (result) no se comunican directamente; usan Redis como broker.
- **Service Discovery**: Cada servicio localiza a otros por nombre (ej: `redis:6379`, `db:5432`).
- **Escalado Independiente**: Puedes escalar worker, vote o result sin afectar a otros.
- **Persistencia**: PostgreSQL almacena datos permanentemente; Redis es temporal.
- **Background Job**: Worker simula un "job scheduler" que procesa tareas asincrónicas.

## Ejemplo: Monitorear el flujo

```bash
# Terminal 1: Ver eventos de Kubernetes
kubectl get events -n voting-app --watch

# Terminal 2: Monitorear Redis
kubectl exec -it <pod-redis> -n voting-app -- redis-cli MONITOR

# Terminal 3: Logs del worker
kubectl logs deploy/worker -n voting-app -f

# Terminal 4: Hacer votos
curl -X POST http://localhost:5000/
```

## Limpiar
```bash
kubectl delete -f ejemplos/02-kubernetes/voting-app/ -n voting-app
kubectl delete namespace voting-app
```

## Referencia
- Inspirado en: https://github.com/dockersamples/example-voting-app
