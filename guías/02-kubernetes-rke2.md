# Guía 02 — Kubernetes (RKE2)

## Objetivos

- Entender qué es RKE2 y por qué usarlo como entorno Kubernetes.
- Trabajar con **networking básico**, **Ingress**, **Deployments** y **configuración/secretos** en el clúster.

---

## 1. ¿Qué es RKE2?

**RKE2** (Rancher Kubernetes Engine 2) es una distribución de Kubernetes:

- **Lista para producción**: configuración segura por defecto (CIS, FIPS cuando aplica).
- **Fácil de instalar**: un binario, script de instalación y opción de alta disponibilidad.
- **Compatible** con el ecosistema Kubernetes (helm, manifests YAML, etc.).

En este curso, “el clúster” será un entorno RKE2 gestionado (o visualizado) desde **Rancher**.

---

## 2. Conceptos básicos de Kubernetes

| Recurso | Función |
|---------|--------|
| **Pod** | Unidad mínima: uno o más contenedores que comparten red y almacenamiento |
| **Deployment** | Gestiona réplicas de Pods (escalado, actualizaciones rolling) |
| **Service** | Punto de acceso estable a los Pods (ClusterIP, NodePort, LoadBalancer) |
| **Ingress** | HTTP/HTTPS: rutas y hosts hacia los Services |
| **ConfigMap** | Configuración no sensible (clave-valor o archivos) |
| **Secret** | Datos sensibles (contraseñas, tokens) |

---

## 3. Networking básico

- Cada Pod tiene su propia IP en la red del clúster.
- Los **Services** agrupan Pods por selector y exponen un nombre DNS: `nombre-servicio.namespace.svc.cluster.local`.
- Para exponer tráfico HTTP/HTTPS al exterior se usa un **Ingress** + controlador (por ejemplo Ingress NGINX).

Ejemplo de Service (ver `ejemplos/02-kubernetes/`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-servicio
spec:
  selector:
    app: mi-app
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

---

## 4. Deployments

Un Deployment define la plantilla del Pod (contenedores, imagen, recursos) y el número de réplicas. Kubernetes mantiene ese número y hace rolling updates.

```bash
kubectl get deployments
kubectl get pods
kubectl rollout status deployment/mi-deployment
```

Los manifests de ejemplo están en `ejemplos/02-kubernetes/deployment.yaml` y similares.

---

## 5. Ingress

El Ingress define reglas por host/path para dirigir el tráfico a distintos Services. Necesitas un **Ingress Controller** instalado en el clúster (RKE2 puede traer uno por defecto según la instalación).

Ejemplo mínimo:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-ingress
spec:
  rules:
    - host: app.ejemplo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mi-servicio
                port:
                  number: 80
```

---

## 6. Configuración y secretos (resumen)

- **ConfigMap**: para configuración no sensible (URLs, feature flags, etc.).
- **Secret**: para contraseñas, API keys, certificados.

En la **Guía 06** veremos en detalle Secrets y ConfigMaps, y cómo integrarlos con **HashiCorp Vault** (Guía 04) para gestión centralizada de información sensible.

---

## 7. Práctica local con Docker Desktop (alumnos)

En el día a día, tus alumnos probablemente usarán **Docker Desktop con Kubernetes activado** en sus portátiles (Windows/macOS). Los ejemplos de `ejemplos/02-kubernetes/` funcionan igual en ese entorno.

### 7.1 Preparar el entorno local

- Tener **Docker Desktop** instalado.
- Activar Kubernetes en Docker Desktop:
  - `Settings` → **Kubernetes** → marcar **Enable Kubernetes** → `Apply & Restart`.
- Verificar el contexto:

```bash
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl cluster-info
kubectl get nodes
```

### 7.2 Namespace de práctica

Crear un namespace para no mezclar recursos:

```bash
kubectl create namespace curso-local
kubectl get namespaces
```

En todos los comandos posteriores se recomienda usar `-n curso-local`.

### 7.3 Ejemplos disponibles

Cada subdirectorio en `ejemplos/02-kubernetes/` contiene un caso de uso diferente. Consulta el **README.md específico** de cada uno para instrucciones detalladas:

#### 1. **Frontend + Backend** — Comunicación entre Pods
- **Ruta**: `ejemplos/02-kubernetes/frontend-backend/`
- **Caso de uso**: Dos aplicaciones que se comunican por Service Discovery.
- **Instructivo**: Lee [ejemplos/02-kubernetes/frontend-backend/README.md](../../ejemplos/02-kubernetes/frontend-backend/README.md)

```bash
kubectl apply -f ejemplos/02-kubernetes/frontend-backend/backend.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/frontend-backend/frontend.yaml -n curso-local
```

#### 2. **Guestbook** — Redis + Frontend Escalado
- **Ruta**: `ejemplos/02-kubernetes/guestbook/`
- **Caso de uso**: Patrón Leader-Follower con Redis y frontend stateless.
- **Instructivo**: Lee [ejemplos/02-kubernetes/guestbook/README.md](../../ejemplos/02-kubernetes/guestbook/README.md)

```bash
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-leader-deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-leader-service.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-follower-deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/redis-follower-service.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/frontend-deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/guestbook/frontend-service.yaml -n curso-local
```

#### 3. **Ingress Demo** — Enrutamiento HTTP/HTTPS
- **Ruta**: `ejemplos/02-kubernetes/ingress-demo/`
- **Caso de uso**: Exponer aplicaciones con Ingress Controller (path/host-based routing).
- **Instructivo**: Lee [ejemplos/02-kubernetes/ingress-demo/README.md](../../ejemplos/02-kubernetes/ingress-demo/README.md)

```bash
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/deployment.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/service.yaml -n curso-local
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/ingress.yaml -n curso-local
```

#### 4. **Voting App** — Arquitectura Microservicios Completa
- **Ruta**: `ejemplos/02-kubernetes/voting-app/`
- **Caso de uso**: Multi-tier con Frontend (vote), Backend (result), Worker, Redis, PostgreSQL.
- **Instructivo**: Lee [ejemplos/02-kubernetes/voting-app/README.md](../../ejemplos/02-kubernetes/voting-app/README.md)

```bash
# Datastore
kubectl apply -f ejemplos/02-kubernetes/voting-app/redis-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/redis-service.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/db-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/db-service.yaml -n voting-app

# Aplicación
kubectl apply -f ejemplos/02-kubernetes/voting-app/vote-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/vote-service.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/result-deployment.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/result-service.yaml -n voting-app
kubectl apply -f ejemplos/02-kubernetes/voting-app/worker-deployment.yaml -n voting-app
```

### 7.4 Verificar despliegue

Tras aplicar cualquiera de los ejemplos anteriores:

```bash
# Ver pods en ejecución
kubectl get pods -n curso-local

# Ver servicios disponibles
kubectl get svc -n curso-local

# Ver ingress (solo si aplicas ejemplos con Ingress)
kubectl get ingress -n curso-local

# Describir un recurso para debugging
kubectl describe deployment <nombre> -n curso-local
kubectl logs -l app=<etiqueta> -n curso-local --tail=50
```

### 7.5 Acceder a las aplicaciones

**Opción A — Port Forward (recomendado para estudiantes)**

```bash
# Reemplazar <recurso> con el nombre del service
kubectl port-forward svc/<recurso> <puerto-local>:<puerto-svc> -n curso-local
```

Ejemplos:
- **Frontend-backend**: `kubectl port-forward svc/frontend 3000:80 -n curso-local` → `http://localhost:3000`
- **Guestbook**: `kubectl port-forward svc/frontend 3000:80 -n curso-local` → `http://localhost:3000`
- **Voting**: `kubectl port-forward svc/vote 5000:80 -n voting-app` → `http://localhost:5000`

**Opción B — NodePort (si configuras el Service con `type: NodePort`)**

```bash
kubectl get svc <recurso> -n curso-local
# Busca la columna NODE-PORT, ej: 30080
# Abre: http://localhost:30080
```

**Opción C — Ingress (para Ingress Demo)**

```bash
kubectl get ingress -n curso-local
# Obtén el hostname/IP, ej: app.localtest.me
# Abre: http://app.localtest.me
```

### 7.6 Debugging y monitoreo

```bash
# Logs en tiempo real
kubectl logs -f <pod-name> -n curso-local

# Exec dentro del pod
kubectl exec -it <pod-name> -n curso-local -- /bin/bash

# Port-forward a un pod específico
kubectl port-forward <pod-name> 8080:8080 -n curso-local

# Describir eventos de un pod
kubectl describe pod <pod-name> -n curso-local
```

### 7.7 Limpiar recursos

Cada ejemplo incluye instrucciones de limpieza en su **README.md específico**. Consulta:

- [ejemplos/02-kubernetes/frontend-backend/README.md](../../ejemplos/02-kubernetes/frontend-backend/README.md#limpiar) — Limpieza del ejemplo Frontend-Backend.
- [ejemplos/02-kubernetes/guestbook/README.md](../../ejemplos/02-kubernetes/guestbook/README.md#limpiar) — Limpieza del ejemplo Guestbook.
- [ejemplos/02-kubernetes/ingress-demo/README.md](../../ejemplos/02-kubernetes/ingress-demo/README.md#limpiar) — Limpieza del ejemplo Ingress Demo.
- [ejemplos/02-kubernetes/voting-app/README.md](../../ejemplos/02-kubernetes/voting-app/README.md#limpiar) — Limpieza del ejemplo Voting App.

Para borrar todos los namespaces:

```bash
kubectl delete namespace curso-local voting-app
```

---

## 8. Comandos útiles con RKE2 (entorno del profesor)

Si usas `kubectl` contra un clúster **RKE2** (o gestionado por Rancher) en tu infraestructura:

```bash
# Contexto y clúster
kubectl config get-contexts
kubectl cluster-info

# Namespaces
kubectl get namespaces

# Aplicar manifests (ejemplos de este curso)
kubectl apply -f ejemplos/02-kubernetes/
```

---

## 9. Siguiente paso

En la **Guía 03** veremos **Rancher**: gestión de clústeres, roles, políticas y dashboards.
