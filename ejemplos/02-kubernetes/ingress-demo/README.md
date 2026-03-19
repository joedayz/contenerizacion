# Ejemplo: Ingress Demo

## Descripción

Demuestra cómo usar **Ingress** en Kubernetes para exponer aplicaciones HTTP con routing basado en rutas o hosts, en lugar de usar solo Services o port-forward.

## Componentes

- **Deployment**: Aplicación web simple.
- **Service**: Expone la aplicación internamente.
- **Ingress**: Define las reglas de routing HTTP/HTTPS desde fuera del clúster.

## Desplegar en Docker Desktop

### 1. Habilitar Ingress Controller en Docker Desktop

Docker Desktop incluye un Ingress Controller básico. Verifica que esté activo:

```bash
kubectl get ingressclass -A
kubectl get pods -n ingress-nginx
```

Si no ves pods, hay que habilitar el Ingress Controller.

#### Instalar NGINX Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

#### Esperar a que se desplieguen los pods
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

#### Verificar la instalación
```bash
kubectl get ingressclass -A
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### 2. Crear namespace
```bash
kubectl create namespace curso-local
```

### 3. Aplicar manifiestos
```bash
# Deployment
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/deployment.yaml -n curso-local

# Service
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/service.yaml -n curso-local

# Ingress
kubectl apply -f ejemplos/02-kubernetes/ingress-demo/ingress.yaml -n curso-local
```

### 4. Verificar despliegue
```bash
kubectl get pods -n curso-local
kubectl get svc -n curso-local
kubectl get ingress -n curso-local
```

### 5. Acceder mediante Ingress

#### En Windows (Docker Desktop):
```bash
# Obtener el IP del Ingress (puede ser 127.0.0.1 o localhost)
kubectl get ingress -n curso-local
```

Luego abre en tu navegador la URL indicada en `HOSTS` del Ingress (por defecto: `http://localhost/` o similar).

#### Alternativa: Port Forward del Ingress
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

Abre `http://localhost:8080` en tu navegador.

## Conceptos clave

- **Ingress Resource**: Define reglas de enrutamiento HTTP/HTTPS.
- **Path-based routing**: `/api/*` → servicio A, `/admin/*` → servicio B (requiere configuración).
- **Host-based routing**: `app.local` → servicio A, `api.local` → servicio B (requiere entrada en `/etc/hosts`).
- **TLS/SSL**: Ingress puede manejar certificados (no incluido en este ejemplo básico).

## Debugging

```bash
# Ver eventos del Ingress
kubectl describe ingress mi-ingress -n curso-local

# Ver logs del Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Testear conectividad desde dentro del clúster
kubectl run curl --rm -it --restart=Never --image=curlimages/curl -- curl http://mi-servicio.curso-local.svc.cluster.local
```

## Limpiar
```bash
kubectl delete -f ejemplos/02-kubernetes/ingress-demo/ -n curso-local
kubectl delete namespace curso-local
```
