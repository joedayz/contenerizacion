# Guía 04 — HashiCorp Vault

## Objetivos

- Entender el papel de **Vault** en la **gestión de información sensible**.
- Ver cómo las aplicaciones (y Kubernetes) pueden obtener secretos de forma segura.

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

## 5. Práctica recomendada

1. Tener Vault instalado (en el clúster o en un servidor accesible).
2. Habilitar el **auth method** de Kubernetes y el **KV secrets engine**.
3. Crear un secreto de ejemplo (por ejemplo `secret/mi-app/db`) con usuario y contraseña.
4. Configurar un Deployment de prueba que use **Vault Agent Injector** para montar ese secreto en el Pod.
5. Comprobar que la aplicación lee el secreto sin tenerlo en imagen ni en ConfigMap.

Los ejemplos en `ejemplos/04-vault/` incluyen anotaciones y manifiestos de referencia.

---

## 6. Relación con el resto del curso

- **Secrets y ConfigMaps (Guía 06)**: en K8s, lo no sensible va a ConfigMap; lo sensible puede venir de Vault y exponerse vía archivo o env en el Pod.
- **Consul (Guía 05)**: se encarga de descubrimiento y relaciones entre servicios; Vault se centra en “quién puede leer qué secreto”.

---

## 7. Siguiente paso

En la **Guía 05** veremos **HashiCorp Consul** para relaciones entre servicios (service discovery, health checks y opcionalmente service mesh).
