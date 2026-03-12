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

### 7.3 Desplegar los ejemplos

Desde la raíz del repo del curso:

```bash
# Deployment
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/deployment.yaml -n curso-local
kubectl get deployments -n curso-local
kubectl get pods -n curso-local

# Service
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/service.yaml -n curso-local
kubectl get svc -n curso-local
```

Para acceder a la aplicación:

- **Opción A — port-forward (simple):**

  ```bash
  kubectl port-forward svc/mi-servicio 8080:80 -n curso-local
  ```

  Navegador: `http://localhost:8080`

- **Opción B — NodePort (si cambias el Service):**

  - En `service.yaml` usar `type: NodePort`.
  - Volver a aplicar y mirar el `NODE-PORT`:

  ```bash
  kubectl apply -f ejemplos/02-kubernetes/ingress-demo/service.yaml -n curso-local
  kubectl get svc mi-servicio -n curso-local
  ```

  Navegador: `http://localhost:<NODE_PORT>`

### 7.4 Probar Ingress en local

Si Docker Desktop tiene un Ingress Controller habilitado:

1. Ajustar el host en `ingress.yaml`, por ejemplo:

   ```yaml
   rules:
     - host: app.localtest.me
   ```

   (`localtest.me` apunta a `127.0.0.1`, no requiere tocar `/etc/hosts`).

2. Aplicar:

   ```bash
   kubectl apply -f ejemplos/02-kubernetes/ingress-demo/ingress.yaml -n curso-local
   kubectl get ingress -n curso-local
   ```

3. Navegador: `http://app.localtest.me`

### 7.5 Limpiar recursos

Para borrar solo los recursos del ejemplo:

```bash
kubectl delete -f ejemplos/02-kubernetes/ingress-demo/ingress.yaml -n curso-local
kubectl delete -f ejemplos/02-kubernetes/ingress-demo/service.yaml -n curso-local
kubectl delete -f ejemplos/02-kubernetes/ingress-demo/deployment.yaml -n curso-local
```

Para borrar el namespace completo:

```bash
kubectl delete namespace curso-local
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
