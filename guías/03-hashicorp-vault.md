# Guía 03 — HashiCorp Vault

## Objetivos

- Entender el papel de **Vault** en la **gestión de información sensible**.
- Ver cómo las aplicaciones (y Kubernetes) pueden obtener secretos de forma segura.
- Explorar demostraciones prácticas en `ejemplos/03-vault/` con comandos para Bash y PowerShell.

---

## 1. ¿Por qué Vault?

En entornos con muchos servicios y clústeres:

- **Secretos repartidos** en ConfigMaps, variables de entorno o archivos suponen riesgo (fugas, rotación difícil).
- **Vault** centraliza secretos (contraseñas, API keys, certificados, claves de cifrado) y controla el acceso mediante políticas y auditoría.

En el curso, Vault complementa a los **Secrets nativos de Kubernetes**: podemos seguir usando Secrets de K8s para cosas muy simples, y usar Vault para secretos críticos y rotación automática.

---

## 2. Conceptos básicos

| Concepto | Descripción |
|----------|-------------|
| **Secret Engine** | Backend que genera o almacena secretos (KV, database, PKI, etc.) |
| **Auth Method** | Cómo se autentican clientes (token, Kubernetes, LDAP, etc.) |
| **Policy** | Permisos (qué paths puede leer/escribir un token o rol) |
| **Lease** | Tiempo de vida de un secreto; Vault puede revocarlo |

Flujo típico:

1. La aplicación se autentica contra Vault (por ejemplo con el **método Kubernetes**: un ServiceAccount de K8s).
2. Vault valida y devuelve un token con permisos limitados.
3. La aplicación usa ese token para leer secretos en una ruta (por ejemplo `secret/data/mi-app/db`).
4. Los secretos pueden tener TTL y renovarse o revocarse.

---

## 3. Uso típico en Kubernetes

- **Vault Agent Injector** (o CSI Provider): inyecta secretos de Vault en el Pod como archivos o variables de entorno, sin que la aplicación hable directamente con Vault.
- **Método de autenticación Kubernetes**: el Pod usa su ServiceAccount; Vault verifica el JWT con el API server de K8s y emite un token.

Así se evita guardar contraseñas en ConfigMaps o en imágenes.

---

## 4. Ejemplo de política (conceptual)

Una política que permite solo leer la ruta de nuestra app:

```hcl
path "secret/data/mi-app/*" {
  capabilities = ["read"]
}
```

El rol de Kubernetes en Vault se configura para asociar un **service account** + **namespace** con esta política.

---

## 5. Práctica recomendada (paso a paso con Injector)

1. **Preparar Vault con script automático (recomendado)**  
   - Linux / macOS:
     - `cd ejemplos/03-vault/scripts`
     - `./vault-up.sh`
   - Windows (PowerShell):
     - `cd ejemplos/03-vault/scripts`
     - `.\vault-up.ps1`
   - Estos scripts dejan listo en un solo paso: Vault (dev) + Injector + Kubernetes auth + secretos + policies + roles.

2. **Aplicar el Deployment con anotaciones del Injector**  
   - Usar el manifiesto `ejemplos/03-vault/deployment-with-vault-annotations.yaml`, que ya trae anotaciones típicas como:
     - `vault.hashicorp.com/agent-inject: "true"`
     - `vault.hashicorp.com/agent-inject-secret-db: "secret/mi-app/db"`
   - Desplegar:
     - `cd ejemplos/03-vault`
     - `kubectl apply -f deployment-with-vault-annotations.yaml`
     - `kubectl get pods -l app=app-con-vault -w`

3. **Verificar el secreto inyectado en el Pod**  
   - Entrar al Pod:
     - `POD_NAME=$(kubectl get pod -l app=app-con-vault -o jsonpath='{.items[0].metadata.name}')`
     - `kubectl exec -it "$POD_NAME" -- sh`
   - Dentro del contenedor:
     - `ls -la /vault/secrets`
     - `cat /vault/secrets/db`  (o el nombre definido en la plantilla)
   - Debes ver el usuario/contraseña que creaste en `secret/mi-app/db` sin que estén en la imagen ni en ConfigMaps.

4. **Demostraciones prácticas**  
   - Explora `ejemplos/03-vault/` para demostraciones interactivas con comandos en Bash y PowerShell:
    - Setup automático con `vault-up`
     - Integración Quarkus + Vault Agent Injector
     - Integración con credenciales de base de datos
   - Cada demo incluye scripts para ambas plataformas (`.sh` para Linux/macOS, `.ps1` para Windows).

5. **Conectar esto con una aplicación real**  
   - A partir de este Deployment base, puedes:
     - montar `/vault/secrets/db` en tu app (por ejemplo Quarkus, Spring, Node),
     - o parsear ese archivo para cargar variables de entorno al arrancar.

6. **Cuando termines la práctica, desmontar entorno**
  - Linux / macOS: `cd ejemplos/03-vault/scripts && ./vault-down.sh`
  - Windows (PowerShell): `cd ejemplos/03-vault/scripts; .\vault-down.ps1`
  - Si solo quieres limpiar apps demo y dejar Vault instalado, usa `cleanup-demos.sh` / `cleanup-demos.ps1`.

Los manifiestos en `ejemplos/03-vault/` sirven como plantilla para reutilizar las anotaciones del Injector en otras aplicaciones.

---

## 6. Relación con el resto del curso

- **Secrets y ConfigMaps (Guía 05)**: en K8s, lo no sensible va a ConfigMap; lo sensible puede venir de Vault y exponerse vía archivo o env en el Pod.
- **Consul (Guía 04)**: se encarga de descubrimiento y relaciones entre servicios; Vault se centra en "quién puede leer qué secreto".

---

## 7. Siguiente paso

En la **Guía 04** veremos **HashiCorp Consul** para relaciones entre servicios (service discovery, health checks y opcionalmente service mesh).
