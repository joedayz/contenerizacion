# Ejemplos HashiCorp Vault — Guía 04

Estos archivos son **referencia** para integrar Vault con Kubernetes. Requieren Vault y (opcionalmente) Vault Agent Injector instalados en el clúster.

## 1. Configuración en Vault (resumen)

- Habilitar **Kubernetes auth method** y configurarlo con la URL del API server de K8s y un token de servicio con permisos para verificar JWTs.
- Habilitar **KV secrets engine** (v2) en una ruta, por ejemplo `secret/`.
- Crear un secreto de prueba:
  ```bash
  vault kv put secret/mi-app/db username="appuser" password="changeme"
  ```
- Crear una **policy** que permita leer esa ruta y un **role** en el auth method de Kubernetes que asocie un ServiceAccount + namespace con esa policy.

## 2. Ejemplo de Deployment con anotaciones (Vault Agent Injector)

El archivo `deployment-with-vault-annotations.yaml` muestra las anotaciones típicas para inyectar secretos de Vault en el Pod. El injector añade un sidecar que escribe los secretos en un volumen compartido.

## Comandos útiles (en un entorno con Vault CLI)

```bash
vault status
vault auth list
vault kv get secret/mi-app/db
```

## Seguridad

- No subir tokens ni credenciales reales al repositorio.
- En clase usar valores de ejemplo y rotarlos después.
