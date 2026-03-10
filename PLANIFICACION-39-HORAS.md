# Planificación del curso — 39 horas

Distribución sugerida del **Módulo Principal — Formación Completa** en contenerización (ANEXO I), para un total de **39 horas**.

---

## Resumen por módulo

| Módulo | Contenido | Horas | Acumulado |
|--------|-----------|-------|-----------|
| 0 | Presentación y entorno | 1 h | 1 h |
| 1 | Contenerización y Docker | 6 h | 7 h |
| 2 | Kubernetes (RKE2) | 11 h | 18 h |
| 3 | Rancher | 5 h | 23 h |
| 4 | HashiCorp Vault | 5 h | 28 h |
| 5 | HashiCorp Consul | 5 h | 33 h |
| 6 | Secrets y ConfigMaps | 4 h | 37 h |
| 7 | Práctica integrada y cierre | 2 h | **39 h** |

---

## Desglose detallado

### Módulo 0 — Presentación y entorno (1 h)
- Presentación del curso y del ANEXO I.
- Explicación del stack: RKE2, Rancher, Vault, Consul.
- Requisitos y opciones de entorno: **todo en local** (ver documento de entorno) o nube si se prefiere.
- Reparto de material (repo, guías, ejemplos).

---

### Módulo 1 — Contenerización y Docker (6 h)
- **Teoría (2 h):** Conceptos clave (contenerización, eficiencia, escalabilidad, portabilidad). Contenedor vs VM. Herramientas y prácticas relevantes.
- **Práctica (4 h):** Instalación de Docker. Comandos básicos (`run`, `ps`, `logs`, `build`). Crear Dockerfile, construir imagen, ejecutar contenedor. Ejemplo de la carpeta `ejemplos/01-docker/`. Buenas prácticas (usuario no root, `.dockerignore`). Registro de imágenes (Docker Hub u otro registry local).

---

### Módulo 2 — Kubernetes (RKE2) (11 h)
- **Teoría (3 h):** Qué es Kubernetes y qué es RKE2. Pod, Deployment, Service, Ingress. Modelo de red en K8s. Configuración y secretos (visión general).
- **Instalación/entorno (2 h):** Opción A: clúster RKE2 local (single-node o 3 nodos en VMs). Opción B: acceso a un clúster ya preparado. Configuración de `kubectl`.
- **Práctica (6 h):** Deployments (réplicas, rolling update). Services (ClusterIP, NodePort). Ingress y controlador. Networking básico (DNS interno, pruebas entre pods). Aplicar y modificar los ejemplos de `ejemplos/02-kubernetes/`. Troubleshooting con `kubectl`.

---

### Módulo 3 — Rancher (5 h)
- **Teoría (1,5 h):** Papel de Rancher en la gestión de clústeres. Multi-cluster. Proyectos y namespaces.
- **Práctica (3,5 h):** Acceso a Rancher (local o proporcionado). Conectar/importar clúster RKE2. Navegación por el dashboard (Workloads, Service Discovery, Config & Storage). Crear proyectos/namespaces. Roles y políticas (ejemplo: admin vs usuario de proyecto). Desplegar recursos desde la UI y desde `kubectl`. Logs y shell desde Rancher. Ejemplos de `ejemplos/03-rancher/`.

---

### Módulo 4 — HashiCorp Vault (5 h)
- **Teoría (2 h):** Gestión centralizada de información sensible. Conceptos: Secret Engine, Auth Method, Policy, lease. Vault en Kubernetes (auth method K8s, inyección en Pods).
- **Práctica (3 h):** Vault en modo dev o servidor (local/clúster). Habilitar KV secrets engine. Crear secretos de ejemplo. Configurar Kubernetes auth (si el entorno lo permite). Ejemplo con Vault Agent Injector o anotaciones (ver `ejemplos/04-vault/`). Buenas prácticas (no guardar tokens en código/repo).

---

### Módulo 5 — HashiCorp Consul (5 h)
- **Teoría (2 h):** Relaciones entre servicios. Service discovery, health checks. Consul en Kubernetes. Service mesh (Consul Connect) como tema opcional.
- **Práctica (3 h):** Desplegar Consul en el clúster (Helm o manifests). Registrar servicios (definición tipo `ejemplos/05-consul/`). Consultar el catálogo (DNS o API). Health checks y comportamiento cuando un pod falla. Integración con aplicaciones desplegadas en K8s.

---

### Módulo 6 — Secrets y ConfigMaps (4 h)
- **Teoría (1 h):** Separación sensible / no sensible. ConfigMap vs Secret. Uso en Pods (env, volúmenes). Relación con Vault.
- **Práctica (3 h):** Crear ConfigMaps y Secrets. Consumirlos en un Deployment (variables de entorno y archivos montados). Ejemplos de `ejemplos/06-secrets-configmaps/`. Buenas prácticas (RBAC, no versionar secretos en claro). Repaso de cuándo usar Secret nativo vs Vault.

---

### Módulo 7 — Práctica integrada y cierre (2 h)
- Ejercicio opcional: desplegar una aplicación que use ConfigMap, Secret (o Vault), y esté visible en Rancher; opcionalmente registrar en Consul.
- Resumen del curso y relación con el ANEXO I.
- Dudas y evaluación/feedback.

---

## Distribución por tipo de sesión (ejemplo)

Si el curso son **5 días de ~8 h** (40 h con pausas, 39 h lectivas):

| Día | Horas | Módulos |
|-----|-------|---------|
| 1 | 8 h | Módulo 0 (1 h) + Módulo 1 (6 h) + inicio Módulo 2 (1 h) |
| 2 | 8 h | Módulo 2 (10 h restantes) |
| 3 | 8 h | Módulo 3 (5 h) + Módulo 4 (3 h) |
| 4 | 8 h | Módulo 4 (2 h restantes) + Módulo 5 (5 h) + inicio Módulo 6 (1 h) |
| 5 | 7 h | Módulo 6 (3 h restantes) + Módulo 7 (2 h) + colchón (2 h) |

Otra opción: sesiones de 4 h durante ~10 días, ajustando el reparto según disponibilidad.

---

*Documento de planificación — Curso de Contenerización, 39 horas*
