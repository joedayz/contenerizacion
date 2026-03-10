# Inicio rápido — Curso de Contenerización

Resumen para el profesor: orden sugerido de la primera sesión y enlaces a material. **Curso: 39 horas** (ver [PLANIFICACION-39-HORAS.md](PLANIFICACION-39-HORAS.md)).

**Sesión de 3 h (mañana):** [SESION-MANANA-3H.md](SESION-MANANA-3H.md) — presentación (30 min), teoría Docker (45 min), práctica (1h 30 min), cierre (15 min).

## Entorno: local vs nube

**Todo se puede instalar en local** (Docker en el PC + RKE2 en una VM, Rancher/Vault/Consul en el clúster). No es obligatorio usar AWS, GCP ni Azure. Detalles: [ENTORNO-CURSO.md](ENTORNO-CURSO.md).

## Día 1 — Contenidos sugeridos

1. **Presentación del módulo** (ANEXO I): contenerización, eficiencia, escalabilidad, portabilidad.
2. **Docker** (Guía 01): conceptos, comandos básicos, primera imagen con `ejemplos/01-docker/`.
3. **Visión general del stack**: RKE2 = Kubernetes del curso, Rancher = gestión, Vault = secretos, Consul = relaciones entre servicios.

## Orden de las guías (alumnos)

| Sesión orientativa | Guía | Contenido |
|-------------------|------|-----------|
| 1 | 01 | Contenerización y Docker |
| 2 | 02 | Kubernetes (RKE2): deployments, services, ingress |
| 3 | 03 | Rancher: dashboards, roles, proyectos |
| 4 | 04 | HashiCorp Vault: gestión de secretos |
| 5 | 05 | HashiCorp Consul: service discovery |
| 6 | 06 | Secrets y ConfigMaps en K8s |

## Requisitos para los alumnos

- Docker instalado (para Guía 01).
- Acceso al clúster RKE2 y a Rancher (kubeconfig o URL + usuario) para las guías 02–06.
- (Opcional) `kubectl` configurado si se trabaja también por línea de comandos.

## Dónde está cada cosa

- **Guías**: carpeta `guías/` (01 a 06 en Markdown).
- **Ejemplos**: carpeta `ejemplos/`, una subcarpeta por módulo (01-docker, 02-kubernetes, …).
- **Índice y explicación RKE2/Rancher/HashiCorp**: `README.md` en la raíz.

## Preguntas frecuentes (para aclarar en clase)

- **¿Por qué RKE2?** Kubernetes listo para producción, fácil de instalar y compatible con Rancher.
- **¿Rancher sustituye a kubectl?** No; complementa. Se puede usar la UI de Rancher y también `kubectl` con el mismo clúster.
- **¿Vault es obligatorio?** Para el curso sirve practicar con Secrets de Kubernetes (Guía 06) y luego ver Vault como evolución para entornos con muchos secretos y rotación.
- **¿Consul y service mesh?** Se puede empezar solo con service discovery (registro + consulta); el mesh (Consul Connect) es opcional según el nivel del grupo.
