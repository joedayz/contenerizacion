# Ejemplos Docker — Guía 01

## Build y ejecución

### Linux/macOS (bash)

```bash
# Construir la imagen
docker build -t curso-contenerizacion-app:v1 .

# Ejecutar (puerto 3000)
docker run -d -p 3000:3000 --name mi-app curso-contenerizacion-app:v1

# Probar
curl http://localhost:3000

# Con variable de entorno
docker run -d -p 3002:3000 -e APP_ENV=produccion --name mi-app-prod curso-contenerizacion-app:v1

# Probar app-prod (3002)
curl http://localhost:3002

# Limpiar
docker stop mi-app mi-app-prod && docker rm mi-app mi-app-prod
```

### Windows (PowerShell)

```powershell
# Construir la imagen
docker build -t curso-contenerizacion-app:v1 .

# Ejecutar (puerto 3000)
docker run -d -p 3000:3000 --name mi-app curso-contenerizacion-app:v1

# Probar
(Invoke-WebRequest -Uri http://localhost:3000).Content

# Con variable de entorno
docker run -d -p 3002:3000 -e APP_ENV=produccion --name mi-app-prod curso-contenerizacion-app:v1

# Probar app-prod (3002, sin confirmación)
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:3002 | Select-Object -ExpandProperty Content

# Limpiar
docker stop mi-app mi-app-prod
docker rm mi-app mi-app-prod
```

## Estructura

- `Dockerfile`: imagen multi-stage mínima, usuario no-root.
- `server.js`: aplicación Node.js simple que escucha en el puerto 3000.
- `.dockerignore`: evita copiar `node_modules` y archivos innecesarios al contexto de build.
