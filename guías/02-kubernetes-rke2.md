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

## 7. Comandos útiles con RKE2

Si usas `kubectl` contra un clúster RKE2 (o gestionado por Rancher):

```bash
# Contexto y clúster
kubectl config get-contexts
kubectl cluster-info

# Namespaces
kubectl get namespaces

# Aplicar manifests
kubectl apply -f ejemplos/02-kubernetes/
```

---

## 8. Siguiente paso

En la **Guía 03** veremos **Rancher**: gestión de clústeres, roles, políticas y dashboards.
