# Guía rápida: Instalar Vault en Kubernetes (Docker Desktop / Podman)

Esta guía explica cómo desplegar **HashiCorp Vault** en un clúster de Kubernetes local usando **Docker Desktop** (o cualquier clúster equivalente, como Podman Desktop o kind), pensada para uso **de laboratorio**.

> ⚠️ El despliegue usa Vault en **modo dev**, sin alta disponibilidad ni persistencia. Es solo para demos y práctica en clase, **no para producción**.

---

## 1. Prerrequisitos

- Docker Desktop (o Podman Desktop) con **Kubernetes activado**.
- `kubectl` instalado y apuntando al clúster local:

```bash
kubectl cluster-info
kubectl get nodes
```

- `helm` instalado:

```bash
helm version
```

Si estos comandos fallan, hay que corregir el entorno antes de seguir.

---

## 2. Crear namespace y añadir repo de Helm

Usaremos un namespace dedicado llamado `vault`:

```bash
kubectl create namespace vault
```

Añadir el repositorio oficial de HashiCorp para Helm:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

---

## 3. Archivo de valores para entorno local

Creamos un archivo de configuración mínimo para laboratorio, sin almacenamiento persistente y con el **Vault Agent Injector** activado:

```bash
cat > values-docker-desktop.yaml <<EOF
server:
  dataStorage:
    enabled: false      # sin PVC, los datos se pierden si se borra el pod
  dev:
    enabled: true       # modo dev: un solo nodo, token raíz fijo
  service:
    type: ClusterIP     # lo expondremos con port-forward
  readinessProbe:
    enabled: false
  livenessProbe:
    enabled: false
Injector:
  enabled: true         # habilita el Vault Agent Injector (sidecar)
  externalVaultAddr: "http://vault.vault.svc.cluster.local:8200"
EOF
```

Este archivo se puede crear en cualquier carpeta (por ejemplo, en la raíz del repositorio del curso).

---

## 4. Instalar / actualizar Vault con Helm

Con el archivo de valores listo, instalamos Vault:

```bash
helm upgrade --install vault hashicorp/vault \
  -n vault \
  -f values-docker-desktop.yaml
```

Comprobar que los pods están en `Running`:

```bash
kubectl -n vault get pods
```

Deberías ver al menos un pod tipo `vault-0` y pods del injector (`vault-agent-injector`).

---

## 5. Exponer Vault a través de port-forward

Para acceder a la UI y a la API de Vault desde el navegador o el CLI en tu máquina, usamos `kubectl port-forward`.

En una terminal separada:

```bash
kubectl -n vault port-forward svc/vault 8200:8200
```

Mientras este comando esté corriendo, Vault será accesible en:

- Navegador: `http://127.0.0.1:8200`
- CLI: `http://127.0.0.1:8200`

---

## 6. Obtener el token raíz (root token)

En modo dev, Vault genera un **root token** y lo expone en la variable de entorno `VAULT_DEV_ROOT_TOKEN_ID` dentro del pod.

La forma más sencilla y compatible de obtenerlo es:

```bash
kubectl -n vault exec -it vault-0 -- sh -c 'echo $VAULT_DEV_ROOT_TOKEN_ID'
```

La salida será algo como:

```text
s.XXXXXXXXXXXXXXXXXXXX
```

Ese valor (`s.XXX...`) es el `VAULT_TOKEN` que usaremos para las prácticas.

---

## 7. Configurar el CLI de Vault en tu máquina

> 🔴 **Muy importante**: antes de usar el comando `vault` desde tu máquina, asegúrate de que el **port-forward del paso 5 está activo** en otra terminal:
>
> ```bash
> kubectl -n vault port-forward svc/vault 8200:8200
> ```

Si tienes el binario de Vault instalado localmente (por ejemplo con Homebrew en macOS o con Chocolatey en Windows), configura las variables de entorno según tu shell.

### 7.1. Bash / Zsh (macOS, Linux, Git Bash)

```bash
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=<TU_ROOT_TOKEN_AQUI>
```

### 7.2. PowerShell (Windows)

```powershell
$env:VAULT_ADDR = "http://127.0.0.1:8200"
$env:VAULT_TOKEN = "<TU_ROOT_TOKEN_AQUI>"
```

### 7.3. CMD clásico (Windows)

```bat
set VAULT_ADDR=http://127.0.0.1:8200
set VAULT_TOKEN=<TU_ROOT_TOKEN_AQUI>
```

Ejemplo de prueba (en cualquier shell):

```bash
vault status
vault auth list
```

Si todo está bien, deberías ver que Vault está en estado `sealed=false` y que hay métodos de autenticación habilitados.

> Si **no** tienes el binario de Vault instalado, puedes ejecutar los comandos `vault ...` **dentro del pod** usando `kubectl exec`. El servidor es el mismo, solo cambia el lugar donde corre el CLI.

Ejemplo desde dentro del pod:

```bash
kubectl -n vault exec -it vault-0 -- sh

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=<TU_ROOT_TOKEN_AQUI>
vault status
exit
```

---

## 8. Crear un secreto de ejemplo (KV)

Con Vault ya accesible, podemos crear un secreto en el motor **KV** por defecto (`secret/`):

```bash
vault kv put secret/mi-app/db username="appuser" password="changeme"
vault kv get secret/mi-app/db
```

Eso deja un secreto listo para ser consumido desde Kubernetes (por ejemplo, vía Vault Agent Injector, CSI Driver o aplicaciones integradas).

---

## 9. Notas para Podman Desktop / kind

Si en lugar de Docker Desktop usas:

- **Podman Desktop** (con su integración de Kubernetes), o  
- un clúster local como **kind** sobre Docker/Podman,

los pasos son exactamente los mismos:

1. Asegúrate de que `kubectl config current-context` apunta a ese clúster.
2. Ejecuta los comandos de los apartados 2–8 sin cambios.

La diferencia está en cómo se crea/gestiona el clúster, pero desde el punto de vista de `kubectl` y `helm`, el flujo de instalación de Vault es idéntico.

---

Con esto, los alumnos tendrán un **Vault funcional en Kubernetes** para usar en las demos de:

- KV + secretos básicos,
- Kubernetes Auth Method,
- Vault Agent Injector (sidecar y anotaciones),
- y cualquier integración adicional (Quarkus, etc.). 

