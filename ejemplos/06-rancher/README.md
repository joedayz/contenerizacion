# Ejemplos Rancher + K3s — Guía 06

Este directorio contiene una práctica completa para usar Rancher sobre un clúster K3s.

## Archivos de la práctica

- `namespace.yaml`: crea el namespace `curso-rancher`.
- `deployment.yaml`: despliega `demo-web` con 2 réplicas.
- `service.yaml`: expone `demo-web` como ClusterIP en puerto 80.
- `ingress.yaml`: publica la app por Ingress (Traefik) con host `demo-web.127.0.0.1.sslip.io`.

## 1. Despliegue con kubectl

Desde la raíz del repositorio:

```bash
kubectl apply -f ejemplos/06-rancher/namespace.yaml
kubectl apply -f ejemplos/06-rancher/deployment.yaml
kubectl apply -f ejemplos/06-rancher/service.yaml
kubectl apply -f ejemplos/06-rancher/ingress.yaml
```

Verificación:

```bash
kubectl get all -n curso-rancher
kubectl get ingress -n curso-rancher
```

## 2. Práctica guiada en Rancher UI

1. Entrar al clúster `local` en Rancher.
2. Ir a `Projects/Namespaces` y confirmar que existe `curso-rancher`.
3. Ir a `Workloads` y validar el Deployment `demo-web` y sus Pods.
4. Ir a `Service Discovery` y revisar `Service` e `Ingress`.
5. Abrir un Pod de `demo-web` y usar `View Logs`.
6. Escalar desde Rancher el Deployment a 3 réplicas y confirmar en la lista de Pods.

## 3. Probar acceso HTTP

Si trabajas en una VM con IP pública, cambia el host en `ingress.yaml` a:

```yaml
host: demo-web.<IP_PUBLICA>.sslip.io
```

Luego vuelve a aplicar el Ingress:

```bash
kubectl apply -f ejemplos/06-rancher/ingress.yaml
```

Prueba:

```bash
curl -I http://demo-web.127.0.0.1.sslip.io
```

## 4. Limpieza

```bash
kubectl delete namespace curso-rancher
```

## 5. Extensión sugerida

Como ejercicio, crear un segundo namespace (`curso-rancher-equipo-b`) y asignar permisos por proyecto en Rancher para comparar visibilidad entre equipos.
