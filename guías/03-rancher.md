# Guía 03 — Rancher

## Objetivos

- Usar **Rancher** para gestionar uno o varios clústeres Kubernetes (incluidos RKE2).
- Entender **roles**, **políticas** y **dashboards** para equipos y entornos.

---

## 1. ¿Qué es Rancher?

**Rancher** es una plataforma de gestión de Kubernetes que permite:

- **Varios clústeres** desde una misma consola (multi-cluster).
- **Importar** clústeres existentes (por ejemplo RKE2) o **crear** nuevos.
- **Control de acceso**: usuarios, roles y políticas por clúster o por proyecto.
- **Dashboards** y vistas unificadas (pods, workloads, logs, shell en contenedor).

En el curso, Rancher será la “ventana” desde la que los alumnos verán y operarán el clúster RKE2.

---

## 2. Gestión de clústeres

- **Clusters**: lista de clústeres conectados (RKE2, EKS, GKE, etc.).
- **Proyectos/Namespaces**: organización lógica dentro de un clúster (por equipo, entorno o aplicación).
- Desde Rancher se pueden ver métricas, eventos y estado de los nodos.

Flujo típico:

1. Acceder a Rancher (URL y credenciales que proporcione el formador).
2. Seleccionar el clúster (por ejemplo, el RKE2 del curso).
3. Navegar por Namespaces, Workloads, Service Discovery, Config Maps/Secrets, etc.

---

## 3. Roles y políticas

Rancher extiende el RBAC de Kubernetes con sus propios **roles**:

- **Administrador** del clúster: control total.
- **Usuario de clúster**: puede crear proyectos y namespaces, según permisos.
- **Usuario de proyecto**: solo ve y opera dentro de un proyecto (namespace o conjunto de namespaces).

**Políticas** permiten restringir, por ejemplo:

- Qué registries de imágenes están permitidos.
- Qué tipos de recursos puede crear un usuario (Pods, Services, etc.).

Para el curso suele bastar con 1–2 roles (admin y “desarrollador” o “operador”) para que los alumnos practiquen permisos.

---

## 4. Dashboards

- **Dashboard principal**: resumen del clúster (CPU, memoria, pods, nodos).
- **Workloads**: Deployments, StatefulSets, DaemonSets, Jobs.
- **Service Discovery**: Services e Ingress.
- **Config & Storage**: ConfigMaps, Secrets, Persistent Volumes.
- **Logs y Shell**: desde la UI se puede abrir un terminal en un contenedor y ver logs en tiempo real.

Esto evita depender solo de `kubectl` y ayuda a explicar conceptos de forma visual.

---

## 5. Práctica recomendada

1. Conectar Rancher al clúster RKE2 (si no está ya conectado).
2. Crear un **proyecto** o **namespace** por alumno o por equipo.
3. Asignar un **rol** de proyecto (por ejemplo “Member” o “Read-only” en otro proyecto).
4. Pedir a los alumnos que desplieguen una aplicación desde la UI o con `kubectl` y que comprueben en el dashboard los recursos creados.

Los ejemplos de la carpeta `ejemplos/02-kubernetes/` y `ejemplos/03-rancher/` se pueden desplegar y revisar desde Rancher.

---

## 6. Siguiente paso

En la **Guía 04** veremos **HashiCorp Vault** para centralizar la gestión de información sensible (secretos) que luego consumirán las aplicaciones en Kubernetes.
