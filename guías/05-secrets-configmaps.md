# Guía 06 — Secrets y ConfigMaps

## Objetivos

- Diferenciar **almacenamiento sensible** (Secrets) de **no sensible** (ConfigMaps).
- Usar Secrets y ConfigMaps en Pods (variables de entorno, archivos).
- Relacionar este contenido con Vault (secretos centralizados) y buenas prácticas.

---

## 1. Separación sensible / no sensible

| Recurso | Uso recomendado | Ejemplos |
|---------|------------------|----------|
| **ConfigMap** | Configuración no sensible | URLs de APIs, feature flags, parámetros de aplicación, archivos de config (log level, timeouts) |
| **Secret** | Datos sensibles | Contraseñas, API keys, tokens, certificados, claves privadas |

En Kubernetes ambos se pueden inyectar como **variables de entorno** o como **archivos** montados en el Pod. La diferencia es que los Secrets se almacenan en base64 (no es cifrado fuerte, pero evita mostrarlos en logs o UIs por error) y Kubernetes puede restringir mejor quién los lee (RBAC).

---

## 2. ConfigMap

Creación desde literal o desde archivo:

```bash
# Desde literales
kubectl create configmap mi-config --from-literal=LOG_LEVEL=info --from-literal=API_URL=https://api.ejemplo.com

# Desde archivo
kubectl create configmap mi-config --from-file=config.json
```

Uso en un Pod:

```yaml
env:
  - name: LOG_LEVEL
    valueFrom:
      configMapKeyRef:
        name: mi-config
        key: LOG_LEVEL
volumeMounts:
  - name: config-volume
    mountPath: /etc/config
volumes:
  - name: config-volume
    configMap:
      name: mi-config
```

---

## 3. Secret

Creación (ejemplo genérico):

```bash
kubectl create secret generic db-credentials --from-literal=username=admin --from-literal=password=secret123
```

Uso en un Pod:

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
volumeMounts:
  - name: certs
    mountPath: /etc/certs
    readOnly: true
volumes:
  - name: certs
    secret:
      secretName: tls-secret
```

---

## 4. Buenas prácticas

- **No** subir Secrets al control de versiones en claro; usar herramientas de gestión de secretos (Vault, Sealed Secrets, etc.) o pipelines que los inyecten.
- **Rotación**: si usas Vault (Guía 04), los secretos pueden rotarse en Vault y las apps los renuevan vía Agent o CSI.
- **RBAC**: limitar quién puede ver/editar Secrets con roles y RoleBindings.
- Configuración que cambia poco y no es sensible → ConfigMap; datos que no deben filtrarse → Secret (y preferiblemente Vault para producción).

---

## 5. Relación con Vault

- **Solo Kubernetes**: ConfigMaps + Secrets nativos pueden ser suficientes para entornos pequeños.
- **Con Vault**: los secretos críticos se almacenan en Vault; el Pod los obtiene mediante Vault Agent Injector (o CSI) y los monta como archivos o env. Así se centraliza rotación, auditoría y políticas.

En el curso tiene sentido: primero practicar ConfigMap y Secret “a mano”, y luego ver en la Guía 04 cómo un mismo tipo de dato (por ejemplo credenciales de DB) se obtendría desde Vault.

---

## 6. Ejemplos

En `ejemplos/06-secrets-configmaps/` hay:

- ConfigMap de ejemplo (literal + archivo).
- Secret genérico de ejemplo.
- Un Deployment que consume ambos (env + volumeMounts).

No incluir contraseñas reales en el repositorio; usar placeholders y explicar que en clase se pueden crear con valores de prueba.

---

## 7. Resumen del módulo

Al terminar las seis guías, el alumno ha visto:

1. **Contenerización y Docker** — conceptos y primeras imágenes.
2. **Kubernetes (RKE2)** — orquestación, networking, ingress, deployments.
3. **Rancher** — gestión de clústeres, roles y dashboards.
4. **Vault** — gestión centralizada de información sensible.
5. **Consul** — relaciones entre servicios (descubrimiento y salud).
6. **Secrets y ConfigMaps** — separación sensible/no sensible en K8s y enlace con Vault.

Con esto se cubren los contenidos del ANEXO I de forma ordenada y práctica.
