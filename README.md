# Curso de Contenerización — Material y Demos

Material del **Módulo Principal — Formación Completa** en contenerización: conceptos clave, Docker/Kubernetes, RKE2, Rancher, HashiCorp Vault, HashiCorp Consul, Secrets y ConfigMaps. **Duración total: 39 horas.**

- **[Planificación 39 h](PLANIFICACION-39-HORAS.md)** — Distribución de horas por módulo y desglose por sesión.
- **[Entorno del curso](ENTORNO-CURSO.md)** — ¿Todo en local o nube? Sí, todo se puede instalar y ejecutar en local (Docker + RKE2 en VMs, Rancher/Vault/Consul en el clúster).

## Estructura del curso

| Módulo | Contenido | Guía | Ejemplos |
|--------|-----------|------|----------|
| **01** | Contenerización y Docker | [guías/01-contenerizacion-docker.md](guías/01-contenerizacion-docker.md) | [ejemplos/01-docker/](ejemplos/01-docker/) |
| **02** | Kubernetes (RKE2) | [guías/02-kubernetes-rke2.md](guías/02-kubernetes-rke2.md) | [ejemplos/02-kubernetes/](ejemplos/02-kubernetes/), [ejemplos/02a-kubernetes-local-azure/](ejemplos/02a-kubernetes-local-azure/) |
| **03** | Rancher | [guías/rancher.md](guías/rancher.md) | [rancher/](rancher/) |
| **04** | HashiCorp Vault | [guías/03-hashicorp-vault.md](guías/03-hashicorp-vault.md) | [ejemplos/03-vault/](ejemplos/03-vault/), [ejemplos/04-vault/](ejemplos/04-vault/) |
| **05** | HashiCorp Consul | [guías/04-hashicorp-consul.md](guías/04-hashicorp-consul.md) | [ejemplos/04-consul/](ejemplos/04-consul/) |
| **06** | Secrets y ConfigMaps | [guías/05-secrets-configmaps.md](guías/05-secrets-configmaps.md) | [ejemplos/05-secrets-configmaps/](ejemplos/05-secrets-configmaps/) |

## Por qué RKE2, Rancher y HashiCorp

- **RKE2** (Rancher Kubernetes Engine 2): distribución de Kubernetes lista para producción, con seguridad reforzada y compatibilidad con estándares (CIS, FIPS). Es el “Kubernetes” que usaremos en el curso.
- **Rancher**: interfaz y herramienta para gestionar uno o varios clústeres K8s (incluidos RKE2): roles, políticas, dashboards y multi-cluster desde un solo lugar.
- **HashiCorp Vault**: gestión centralizada de secretos e información sensible (contraseñas, API keys, certificados).
- **HashiCorp Consul**: descubrimiento de servicios, health checks y relaciones entre servicios (service mesh opcional).

Juntos forman un stack: **RKE2** como orquestador, **Rancher** para operar los clústeres, **Vault** para secretos y **Consul** para que los servicios se encuentren y se comuniquen de forma segura.

## Requisitos previos

- Conocimientos básicos de Linux y línea de comandos.
- (Opcional) Nociones de redes y servicios.

## Cómo usar este repositorio

1. Sigue las guías en orden (01 → 06).
2. Ejecuta los ejemplos en la carpeta `ejemplos/` correspondiente a cada guía.
3. Cada guía incluye objetivos, teoría breve y pasos prácticos.

---

*Material para el curso de Contenerización — ANEXO I*
