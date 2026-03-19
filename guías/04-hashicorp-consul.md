# Guía 04 — HashiCorp Consul

## Objetivos

- Entender el papel de **Consul** en las **relaciones entre servicios** (service discovery, health checks).
- Ver cómo los servicios se descubren y se comunican en un entorno distribuido.
- Explorar demostraciones prácticas en `ejemplos/04-consul/` con comandos para Bash y PowerShell.

---

## 1. ¿Por qué Consul?

En un clúster con muchos microservicios:

- Los servicios necesitan **encontrarse** (¿dónde está el API de usuarios? ¿en qué puerto?).
- Necesitan saber si un nodo está **sano** (health checks) para no enviar tráfico a instancias caídas.
- Opcionalmente, se puede usar **service mesh** (mTLS, tráfico entre servicios cifrado y controlado).

**Consul** ofrece:

- **Service discovery**: registro de servicios y resolución DNS o HTTP.
- **Health checking**: comprobación del estado de los servicios.
- **Service mesh** (opcional): conectividad segura entre servicios con Envoy.

En el curso nos centramos en **relaciones entre servicios**: descubrimiento y salud.

---

## 2. Conceptos básicos

| Concepto | Descripción |
|----------|-------------|
| **Agente** | Proceso de Consul en cada nodo (cliente o servidor) |
| **Servicio** | Aplicación registrada en Consul (nombre, puerto, health check) |
| **Health check** | Script o HTTP check que marca el servicio como passing/failing |
| **Consensus** | Los servidores Consul usan Raft para mantener el catálogo de servicios |

Los clientes consultan “¿dónde está el servicio X?” y Consul devuelve la lista de instancias sanas (IP + puerto).

---

## 3. Cómo se relacionan los servicios

- **Registro**: cada servicio (o un sidecar) se registra en Consul con nombre, IP, puerto y opcionalmente health check.
- **Descubrimiento**: otro servicio pregunta por el nombre (vía DNS o API HTTP de Consul) y obtiene las direcciones de las instancias que pasan el health check.
- **Actualización**: si un pod se cae, el health check falla y Consul deja de devolverlo; los clientes dejan de enviarle tráfico.

Así se evita hardcodear IPs o listas estáticas de backends.

---

## 4. Consul en Kubernetes

- **Consul Helm chart**: despliega Consul en el clúster (modo servidor o cliente).
- **Consul Connect** (service mesh): inyecta sidecars Envoy en los Pods; el tráfico entre servicios pasa por el mesh con mTLS.
- Para el curso se puede empezar solo con **service discovery** (registro + consulta DNS/HTTP) sin activar aún el mesh.

---

## 5. Ejemplo de uso

Un backend “pedidos” necesita llamar al servicio “usuarios”:

- Sin Consul: URL fija o variable de entorno con host:puerto del servicio usuarios.
- Con Consul: el servicio “usuarios” está registrado; “pedidos” resuelve `usuarios.service.consul` (DNS) o llama a la API de Consul y obtiene la lista de instancias. Consul solo devuelve instancias con health check en passing.

Los ejemplos en `ejemplos/04-consul/` muestran definiciones de servicio y health checks.

---

## 6. Relación con el resto del curso

- **Kubernetes/RKE2**: los Pods pueden registrarse en Consul (por ejemplo con un sidecar o un init container).
- **Rancher**: desde el dashboard se ven los Pods; Consul añade la capa de “catálogo de servicios” y salud.
- **Vault**: se encarga de secretos; Consul de “dónde está cada servicio y si está vivo”.

---

## 7. Práctica recomendada

1. Desplegar Consul en el clúster (Helm o manifests de ejemplo).
2. Registrar 2 servicios sencillos (por ejemplo dos Deployments con un health check HTTP).
3. Desde un Pod de prueba, resolver el nombre de uno de los servicios vía DNS de Consul o API.
4. (Opcional) Simular la caída de un Pod y comprobar que Consul deja de devolverlo en las consultas.

---

## 8. Demostraciones prácticas

Explora `ejemplos/04-consul/` para demostraciones interactivas con comandos en Bash y PowerShell:
- Setup e instalación de Consul y Vault
- Registro de servicios y health checks
- Descubrimiento de servicios y resolución DNS
- Integración con Vault para gestionar configuración dinámica
- Cada demo incluye scripts para ambas plataformas (`.sh` para Linux/macOS, `.ps1` para Windows).

---

## 9. Siguiente paso

En la **Guía 05** cerraremos el ciclo con **Secrets y ConfigMaps** en Kubernetes y cómo separar almacenamiento sensible (Secret / Vault) de no sensible (ConfigMap).
