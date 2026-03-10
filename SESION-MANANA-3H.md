# Sesión de mañana — 3 horas

Guía minuto a minuto para la **primera sesión** del curso (3 h). Cubre presentación del curso, conceptos de contenerización y Docker con práctica incluida.

---

## Resumen

| Bloque | Tiempo | Contenido |
|--------|--------|-----------|
| 1 | 0:30 | Presentación del curso y del stack (RKE2, Rancher, Vault, Consul) |
| 2 | 0:45 | Teoría: contenerización, eficiencia, escalabilidad, portabilidad + Docker |
| 3 | 1:30 | Práctica Docker: comandos, primera imagen, ejemplo del repo |
| 4 | 0:15 | Cierre y qué veremos la próxima vez |

**Total: 3 h**

---

## Bloque 1 — Presentación (30 min)

- **5 min** — Presentación personal y del curso (39 h total, ANEXO I).
- **10 min** — Contenidos del módulo: contenerización → Docker → Kubernetes (RKE2) → Rancher → Vault → Consul → Secrets/ConfigMaps. Enlace al [README](README.md).
- **5 min** — **Stack en una frase:** RKE2 = Kubernetes del curso, Rancher = gestión de clústeres, Vault = secretos, Consul = relaciones entre servicios. Todo se puede hacer **en local** ([ENTORNO-CURSO.md](ENTORNO-CURSO.md)).
- **10 min** — Reparto de material: clonar/descargar el repo, abrir la [Guía 01](guías/01-contenerizacion-docker.md). Requisitos: tener Docker instalado (o instalarlo en el descanso).

---

## Bloque 2 — Teoría (45 min)

Seguir la [Guía 01 — secciones 1 y 2](guías/01-contenerizacion-docker.md): conceptos clave y herramientas.

- **Contenerización:** aplicación + dependencias en un contenedor; mismo kernel, entorno aislado.
- **Eficiencia:** menos recursos que una VM, arranque rápido, más densidad.
- **Escalabilidad:** muchas instancias de la misma imagen; luego Kubernetes lo orquestará.
- **Portabilidad:** “build once, run anywhere”.
- **Docker:** imágenes, contenedores, registries. Prácticas: imagen mínima, no root, un proceso por contenedor, `.dockerignore`.

Puedes apoyarte en un esquema en pizarra: “app + deps → imagen → contenedor → muchos contenedores → orquestador (próximas sesiones)”.

---

## Bloque 3 — Práctica Docker (1 h 30 min)

### Comprobación (5 min)

```bash
docker --version
docker ps
docker images
```

Si alguien no tiene Docker: indicar instalación (Docker Desktop o Engine según OS) y que siga cuando lo tenga.

### Contenedor ya hecho (15 min)

```bash
docker run -d --name mi-nginx -p 8080:80 nginx:alpine
```

- Abrir http://localhost:8080 → página de bienvenida de nginx.
- `docker ps`, `docker logs mi-nginx`, `docker stop mi-nginx`, `docker rm mi-nginx`.

### Nuestra primera imagen (45 min)

Ir a la carpeta del repo y usar `ejemplos/01-docker/`:

```bash
cd ejemplos/01-docker
docker build -t curso-app:v1 .
docker run -d -p 3000:3000 --name mi-app curso-app:v1
curl http://localhost:3000
```

Revisar en clase (5–10 min):

- **Dockerfile:** imagen base, usuario no-root, `WORKDIR`, `COPY`, `CMD`.
- **server.js:** app mínima que escucha en 3000.
- **.dockerignore:** por qué excluir `node_modules` y similares.

Variante (si da tiempo): ejecutar con variable de entorno y comprobar la respuesta:

```bash
docker run -d -p 3001:3000 -e APP_ENV=produccion --name mi-app-prod curso-app:v1
curl http://localhost:3001
```

### Limpieza y resumen (5 min)

```bash
docker stop mi-app
docker rm mi-app
```

Resumir: imagen = plantilla, contenedor = instancia en ejecución; la próxima sesión veremos Kubernetes (RKE2) para orquestar muchos contenedores.

---

## Bloque 4 — Cierre (15 min)

- **5 min** — Resumen: hoy = contenerización + Docker (conceptos + primera imagen).
- **5 min** — Próxima sesión: Kubernetes (RKE2), deployments, services, ingress. Si pueden, tener ya acceso al clúster o al menos `kubectl` instalado.
- **5 min** — Dudas y tarea opcional: que cada uno modifique algo en `server.js` o en el Dockerfile, vuelva a hacer `docker build` y `docker run` y compruebe el resultado.

---

## Checklist antes de clase

- [ ] Repo accesible para los alumnos (clone o ZIP).
- [ ] Tener Docker instalado en el equipo de demostración.
- [ ] Probar una vez el flujo: `docker build` y `docker run` en `ejemplos/01-docker/`.
- [ ] Decidir si en el descanso (si lo hay) se instala Docker para quien no lo tenga.

---

## Si sobra tiempo

- Explicar `docker run -d` vs sin `-d`, `-p`, `--name`.
- Mostrar `docker images` y `docker rmi` para borrar imágenes.
- Comentar qué es un registry (Docker Hub) y que más adelante subirán imágenes para usarlas en Kubernetes.

---

*Sesión 1 — Curso Contenerización, 3 h*
