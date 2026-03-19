# Ejemplos Rancher — Guía 03

Rancher se usa sobre clústeres ya desplegados (por ejemplo RKE2). No hay manifests YAML específicos de Rancher en este repo; la práctica se hace desde la UI.

## Tareas sugeridas en Rancher

1. **Conectar al clúster**: ver el clúster RKE2 en *Clusters* y comprobar estado de nodos.
2. **Crear un proyecto/namespace**: por ejemplo `curso-alumnos` y desplegar los recursos de `ejemplos/02-kubernetes/` en ese namespace.
3. **Asignar roles**: crear un usuario o usar uno existente y asignar rol *Project Member* al proyecto para que los alumnos vean solo su ámbito.
4. **Revisar en el dashboard**: Workloads → Deployments/Pods del Deployment `mi-app`; Service Discovery → Services e Ingress; Config & Storage → ConfigMaps/Secrets cuando se usen (Guía 06).
5. **Logs y Shell**: abrir un Pod de `mi-app` y usar *Execute Shell* o *View Logs* desde la UI.

## Aplicar manifests desde Rancher

En *Workloads* → *Deployments* → *Create* se puede pegar YAML o importar desde archivo. También se puede usar `kubectl` con el kubeconfig que proporciona Rancher (Download KubeConfig en el clúster).

## Namespace de práctica

```bash
# Crear namespace para el curso
kubectl create namespace curso-practica

# Desplegar los ejemplos de la Guía 02 en ese namespace
kubectl apply -f ../02-kubernetes/ -n curso-practica
```

Luego en Rancher, seleccionar el namespace `curso-practica` y revisar los recursos creados.
