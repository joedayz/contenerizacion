# Ejemplo Guía 01 — Imagen mínima para el curso de Contenerización
# Buena práctica: imagen base pequeña (Alpine)
FROM node:20-alpine

# No ejecutar como root (buena práctica)
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S appuser -G appgroup
WORKDIR /app

# Copiar código de la aplicación (esta app no tiene dependencias externas)
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 3000

# Un proceso principal por contenedor
CMD ["node", "server.js"]
