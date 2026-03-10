# Guía 01 — Contenerización y Docker

## Objetivos

- Entender los conceptos clave: **contenerización**, **eficiencia**, **escalabilidad**, **portabilidad**.
- Conocer las herramientas y prácticas más relevantes (Docker).
- Trabajar en un entorno tipo Docker como base para Kubernetes.

---

## 1. Conceptos clave

### Contenerización

La **contenerización** consiste en empaquetar una aplicación con todas sus dependencias (librerías, runtime, configuración) en una unidad aislada llamada **contenedor**. El contenedor se ejecuta sobre un mismo kernel (el del host) pero con su propio sistema de archivos y namespace, lo que da sensación de “máquina ligera”.

### Eficiencia

- **Menor uso de recursos** que una máquina virtual: no hay un SO completo por instancia.
- **Arranque rápido**: los contenedores se inician en segundos.
- **Alta densidad**: en un mismo servidor caben muchos más contenedores que VMs.

### Escalabilidad

- Crear más instancias de la misma imagen es sencillo (escalado horizontal).
- Los orquestadores (Kubernetes, RKE2) automatizan el escalado según carga o políticas.

### Portabilidad

- **“Build once, run anywhere”**: la misma imagen corre en desarrollo, staging y producción.
- Reduce el clásico “en mi máquina funciona”: el entorno es reproducible.

---

## 2. Herramientas y prácticas relevantes

| Herramienta | Uso principal |
|-------------|----------------|
| **Docker** | Crear imágenes, ejecutar contenedores, Docker Compose para entornos locales |
| **Kubernetes / RKE2** | Orquestación en producción (siguiente módulo) |
| **Registries** | Almacenar y distribuir imágenes (Docker Hub, Harbor, etc.) |

Buenas prácticas que veremos a lo largo del curso:

- Imágenes mínimas (multi-stage builds cuando aplique).
- No ejecutar como root dentro del contenedor.
- Una preocupación por proceso (un proceso principal por contenedor).
- Uso de `.dockerignore` para builds más rápidos y seguros.

---

## 3. Entorno Docker — Comandos esenciales

```bash
# Ver versión
docker --version

# Listar contenedores en ejecución
docker ps

# Listar todas las imágenes
docker images

# Ejecutar un contenedor (ejemplo: nginx)
docker run -d --name mi-nginx -p 8080:80 nginx:alpine

# Ver logs
docker logs mi-nginx

# Detener y eliminar
docker stop mi-nginx && docker rm mi-nginx
```

---

## 4. Crear tu primera imagen

En la carpeta `ejemplos/01-docker/` encontrarás:

- `Dockerfile` — Definición de la imagen.
- `app/` — Código de ejemplo (por ejemplo, una app web sencilla).

Pasos típicos:

```bash
cd ejemplos/01-docker
docker build -t mi-app:v1 .
docker run -d -p 3000:3000 mi-app:v1
```

---

## 5. Siguiente paso

En la **Guía 02** pasamos a **Kubernetes con RKE2**: mismo concepto de contenedor, pero orquestado (deployments, servicios, ingress, configuración y secretos).
