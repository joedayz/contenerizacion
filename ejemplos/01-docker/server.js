/**
 * Servidor HTTP mínimo para Guía 01 — Contenerización y Docker
 * Responde en el puerto 3000 con un mensaje y variables de entorno de ejemplo
 */
const http = require('http');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    message: 'Curso de Contenerización — Guía 01',
    env: process.env.APP_ENV || 'desarrollo',
    timestamp: new Date().toISOString(),
  }));
});

server.listen(PORT, () => {
  console.log(`Servidor escuchando en http://0.0.0.0:${PORT}`);
});
