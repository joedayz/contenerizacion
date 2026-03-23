# Ejemplo: Frontend + Backend (Comunicación entre Pods)

## Descripción

Demuestra cómo dos aplicaciones (frontend y backend) se comunican dentro de un clúster Kubernetes usando **Service Discovery** con DNS internos.

## Componentes

- **Backend**: API REST que expone endpoints.
- **Frontend**: Aplicación que consume el backend usando el nombre del servicio DNS.

## Desplegar en Docker Desktop

### 1. Crear namespace
```bash
kubectl create namespace curso-local
```

### 2. Aplicar manifiestos
```bash
# Desde la raíz del repo
kubectl apply -f ejemplos/02-kubernetes/frontend-backend/backend.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/frontend-backend/frontend.yaml -n curso-local
```

### 3. Verificar despliegue
```bash
kubectl get pods -n curso-local
kubectl get svc -n curso-local
```

### 4. Acceder al frontend

#### Opción A: Port Forward
```bash
kubectl port-forward svc/frontend-service 3000:80 -n curso-local
```
Luego abre `http://localhost:3000` en tu navegador.

#### Opción B: Exec en el Pod
```bash
kubectl exec -it <pod-frontend> -n curso-local -- sh
# Dentro del pod:
curl http://backend-service:80
```

## Conceptos clave

- **Service Discovery**: El frontend localiza el backend usando el nombre del servicio (`http://backend:8080`).
- **DNS interno**: Kubernetes resuelve automáticamente `backend` al IP del servicio.
- **Namespace isolation**: Los recursos están en el namespace `curso-local`.

## Limpiar
```bash
kubectl delete -f ejemplos/02-kubernetes/frontend-backend/ -n curso-local
kubectl delete namespace curso-local
```
