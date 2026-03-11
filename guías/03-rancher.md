# Guía 03 — Rancher

## Objetivos

- Usar **Rancher** para gestionar uno o varios clústeres Kubernetes (incluidos RKE2).
- Entender **roles**, **políticas** y **dashboards** para equipos y entornos.

---

## 1. ¿Qué es Rancher?

**Rancher** es una plataforma de gestión de Kubernetes que permite:

- **Varios clústeres** desde una misma consola (multi-cluster).
- **Importar** clústeres existentes (por ejemplo RKE2) o **crear** nuevos.
- **Control de acceso**: usuarios, roles y políticas por clúster o por proyecto.
- **Dashboards** y vistas unificadas (pods, workloads, logs, shell en contenedor).

En el curso, Rancher será la “ventana” desde la que los alumnos verán y operarán el clúster RKE2.

---

## 2. Gestión de clústeres

- **Clusters**: lista de clústeres conectados (RKE2, EKS, GKE, etc.).
- **Proyectos/Namespaces**: organización lógica dentro de un clúster (por equipo, entorno o aplicación).
- Desde Rancher se pueden ver métricas, eventos y estado de los nodos.

Flujo típico:

1. Acceder a Rancher (URL y credenciales que proporcione el formador).
2. Seleccionar el clúster (por ejemplo, el RKE2 del curso).
3. Navegar por Namespaces, Workloads, Service Discovery, Config Maps/Secrets, etc.

---

## 3. Roles y políticas

Rancher extiende el RBAC de Kubernetes con sus propios **roles**:

- **Administrador** del clúster: control total.
- **Usuario de clúster**: puede crear proyectos y namespaces, según permisos.
- **Usuario de proyecto**: solo ve y opera dentro de un proyecto (namespace o conjunto de namespaces).

**Políticas** permiten restringir, por ejemplo:

- Qué registries de imágenes están permitidos.
- Qué tipos de recursos puede crear un usuario (Pods, Services, etc.).

Para el curso suele bastar con 1–2 roles (admin y “desarrollador” o “operador”) para que los alumnos practiquen permisos.

---

## 4. Dashboards

- **Dashboard principal**: resumen del clúster (CPU, memoria, pods, nodos).
- **Workloads**: Deployments, StatefulSets, DaemonSets, Jobs.
- **Service Discovery**: Services e Ingress.
- **Config & Storage**: ConfigMaps, Secrets, Persistent Volumes.
- **Logs y Shell**: desde la UI se puede abrir un terminal en un contenedor y ver logs en tiempo real.

Esto evita depender solo de `kubectl` y ayuda a explicar conceptos de forma visual.

---

## 5. Práctica recomendada

1. Conectar Rancher al clúster RKE2 (si no está ya conectado).
2. Crear un **proyecto** o **namespace** por alumno o por equipo.
3. Asignar un **rol** de proyecto (por ejemplo “Member” o “Read-only” en otro proyecto).
4. Pedir a los alumnos que desplieguen una aplicación desde la UI o con `kubectl` y que comprueben en el dashboard los recursos creados.

Los ejemplos de la carpeta `ejemplos/02-kubernetes/` y `ejemplos/03-rancher/` se pueden desplegar y revisar desde Rancher.

---

### 5.1 Desplegar el ejemplo de la Guía 02 con `kubectl` (y verlo en Rancher)

**Objetivo en clase:** usar **el mismo YAML** de la Guía 02, pero contra el clúster que Rancher gestiona, y luego revisar todo desde la UI.

1. **Descargar kubeconfig desde Rancher**
   - En la UI de Rancher: entrar al clúster → menú de opciones (⋮) → **Download KubeConfig**.
   - Guardar el archivo, por ejemplo como `~/kubeconfig-curso.yaml`.

2. **Apuntar `kubectl` a ese clúster**

   ```bash
   export KUBECONFIG=~/kubeconfig-curso.yaml
   kubectl config get-contexts
   kubectl get nodes
   ```

3. **Crear namespace para la demo**

   ```bash
   kubectl create namespace curso-rancher
   kubectl get namespaces
   ```

4. **Aplicar los mismos manifests de `ejemplos/02-kubernetes/`**

   Desde la raíz del repo del curso:

   ```bash
   kubectl apply -f ejemplos/02-kubernetes/deployment.yaml -n curso-rancher
   kubectl apply -f ejemplos/02-kubernetes/service.yaml -n curso-rancher
   kubectl apply -f ejemplos/02-kubernetes/ingress.yaml -n curso-rancher   # si el clúster tiene Ingress Controller
   ```

5. **Revisar en Rancher (vista alumno)**
   - En Rancher → seleccionar el clúster.
   - Filtrar por namespace **`curso-rancher`**.
   - Ir a:
     - `Workloads` → ver el Deployment y los Pods del ejemplo.
     - `Service Discovery` → ver el Service y el Ingress.
     - `Logs` / `Execute Shell` sobre un Pod para mostrar debugging básico.

### 5.2 Desplegar el mismo ejemplo pegando YAML en la UI de Rancher

**Alternativa para clase** sin usar terminal de los alumnos (todo clic a clic en la web):

1. En Rancher, seleccionar el clúster y el namespace `curso-rancher` (o crearlo desde la UI).
2. **Deployment**:
   - `Workloads` → `Deployments` → `Create`.
   - Elegir la opción de **editar/pegar YAML**.
   - Copiar el contenido de `ejemplos/02-kubernetes/deployment.yaml`.
   - Verificar que el `namespace` es `curso-rancher` (en el YAML o en el selector de la UI).
   - Guardar.
3. **Service**:
   - `Service Discovery` → `Services` → `Create`.
   - Pestaña de **YAML**, pegar el contenido de `ejemplos/02-kubernetes/service.yaml`.
   - Ajustar namespace si hace falta y crear.
4. **Ingress**:
   - `Service Discovery` → `Ingresses` → `Create`.
   - Pestaña de **YAML`, pegar el contenido de `ejemplos/02-kubernetes/ingress.yaml` (con el host que uses en el entorno demo).
   - Crear y comprobar en la lista de Ingress.
5. Probar la aplicación desde el navegador apuntando al host/puerto que corresponda en tu entorno demo (por ejemplo, un Ingress con dominio público que resuelva a la VM donde corre el clúster).

---

## 6. Siguiente paso

En la **Guía 04** veremos **HashiCorp Vault** para centralizar la gestión de información sensible (secretos) que luego consumirán las aplicaciones en Kubernetes.
---

## 7. Entorno de demo: Rancher + K3s en una VM Ubuntu (profesor)

Para que el alumnado vea **Rancher gestionando un clúster real**, puedes levantar un entorno sencillo en la nube (por ejemplo AWS) con:

- 1 VM Ubuntu 22.04 (4 vCPU, 8 GB RAM, 50–100 GB disco).
- Un clúster **K3s** instalado en esa VM.
- **Rancher** desplegado dentro de ese K3s y expuesto por HTTPS.

### 7.1 Crear la VM (ejemplo AWS)

- AMI: Ubuntu Server 22.04 LTS.
- Tipo: `t3.medium` (mínimo) o `t3.large` (recomendado).
- Security Group:
  - TCP 22 (SSH) desde tu IP.
  - TCP 80 y 443 desde `0.0.0.0/0` (acceso de los alumnos al panel de Rancher).

### 7.2 Instalar K3s en la VM

Conectado por SSH como `ubuntu`:

```bash
sudo apt update && sudo apt upgrade -y
curl -sfL https://get.k3s.io | sh -
sudo k3s kubectl get nodes
```

### 7.3 Instalar Helm y cert-manager

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --kubeconfig /etc/rancher/k3s/k3s.yaml
```

Esperar a que los pods de `cert-manager` estén en `Running`:

```bash
sudo k3s kubectl get pods -n cert-manager
```

### 7.4 Instalar Rancher

1. Añadir el repositorio de Rancher:

   ```bash
   helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
   helm repo update
   ```

2. Crear el namespace de Rancher:

   ```bash
   sudo k3s kubectl create namespace cattle-system
   ```

3. Instalar Rancher (cambia `TU_HOSTNAME` por un dominio o la IP pública):

   ```bash
   helm install rancher rancher-latest/rancher \
     --namespace cattle-system \
     --set hostname=TU_HOSTNAME \
     --set replicas=1 \
     --kubeconfig /etc/rancher/k3s/k3s.yaml
   ```

4. Esperar a que el pod de Rancher esté en `Running`:

   ```bash
   sudo k3s kubectl -n cattle-system get pods
   ```

### 7.5 Acceso del alumnado

- Abrir en el navegador: `https://TU_HOSTNAME` (o `https://IP_PUBLICA` si no hay dominio).
- La primera vez:
  - Rancher te pedirá configurar la contraseña de `admin`.
  - Después podrás compartir la URL con los alumnos para que vean:
    - Lista de clústeres (en este caso, el K3s de demo).
    - Namespaces, Workloads, Services, Ingress, ConfigMaps, Secrets, etc.

Opcionalmente, puedes descargar el `kubeconfig` desde Rancher y dárselo a los alumnos para que hagan `kubectl` contra ese clúster desde su máquina local (además de sus pruebas locales con Docker Desktop).
