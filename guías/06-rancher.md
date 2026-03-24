# Guía 06 — Rancher

## Objetivos

- Usar **Rancher** para gestionar uno o varios clústeres Kubernetes (incluidos K3s y RKE2).
- Entender **roles**, **políticas** y **dashboards** para equipos y entornos.

---

## 0. Instalación de K3s y Rancher en Ubuntu

### 0.1 Requisitos del sistema

**Para K3s (servidor):**
- Ubuntu 24.04 LTS (también funciona en 22.04 LTS)
- Mínimo: 4 vCPU, 8 GB RAM, 50 GB disco
- Recomendado: 8 vCPU, 16 GB RAM, 100 GB disco

**Puertos necesarios:**
- TCP 22 (SSH)
- TCP 80, 443 (Rancher UI y API)
- TCP 6443 (Kubernetes API)
- TCP 9345 (registro de nodos K3s, si se usan agentes)
- UDP 8472 (Canal/Flannel VXLAN)
- TCP 10250 (Kubelet metrics)

### 0.2 Instalar K3s en Ubuntu

**1. Actualizar el sistema:**

```bash
sudo apt update && sudo apt upgrade -y
```

**2. Instalar K3s (versión estable):**

```bash
curl -sfL https://get.k3s.io | sh -
```

**3. Habilitar y arrancar el servicio K3s:**

```bash
sudo systemctl enable k3s
sudo systemctl start k3s
```

**4. Verificar estado:**

```bash
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

Esperar hasta que todos los componentes estén en Running (~2-3 minutos).

**5. Configurar kubectl:**

```bash
# Configurar kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# Verificar acceso
kubectl get nodes
```

Deberías ver el nodo en estado `Ready`.

**6. Verificar todos los pods del sistema:**

```bash
kubectl get pods -A
```

En un clúster K3s, en `kube-system` deben verse en `Running` al menos:
- `coredns`
- `metrics-server`
- `local-path-provisioner`
- Flannel (`svclb`/`helm-install` según versión)
- Traefik (si no fue deshabilitado durante la instalación)

### 0.3 Instalar Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 0.4 Instalar cert-manager (prerequisito para Rancher)

```bash
# Agregar repositorio de cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Instalar cert-manager con CRDs
kubectl create namespace cert-manager

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true \
  --version v1.13.0

# Verificar instalación
kubectl get pods -n cert-manager
```

Esperar a que los 3 pods estén en `Running`:
- `cert-manager-xxxxx`
- `cert-manager-cainjector-xxxxx`
- `cert-manager-webhook-xxxxx`

### 0.5 Instalar Rancher

**1. Agregar repositorio de Rancher:**

```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

**2. Crear namespace para Rancher:**

```bash
kubectl create namespace cattle-system
```

**3. Instalar Rancher:**

Opción A: **Con dominio propio** (recomendado para producción):

```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.midominio.com \
  --set replicas=1 \
  --set bootstrapPassword=admin123
```

Opción B: **Con IP pública** (para demos/desarrollo):

```bash
# Reemplaza IP_PUBLICA con la IP de tu VM
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=IP_PUBLICA.sslip.io \
  --set replicas=1 \
  --set bootstrapPassword=admin123
```

**Nota:** `sslip.io` es un servicio que resuelve `192.168.1.100.sslip.io` → `192.168.1.100` automáticamente, útil para pruebas.

**4. Verificar instalación:**

```bash
kubectl -n cattle-system get pods
kubectl -n cattle-system rollout status deploy/rancher
```

Esperar hasta que el pod `rancher-xxxxx` esté `Running` y `1/1 Ready`.

**5. Obtener la URL de Rancher:**

```bash
echo "https://$(kubectl -n cattle-system get ingress rancher -o jsonpath='{.spec.rules[0].host}')"
```

### 0.6 Configuración inicial de Rancher

**1. Acceder a la UI:**

Abre en el navegador la URL obtenida en el paso anterior (ej: `https://rancher.midominio.com`).

Si ves error de certificado SSL:
- **Producción:** Configura un certificado válido con Let's Encrypt
- **Demo/desarrollo:** Acepta el certificado autofirmado

**2. Login inicial:**

- Usuario: `admin`
- Password: `admin123` (o el que configuraste en `bootstrapPassword`)

**3. Cambiar password:**

Rancher te pedirá cambiar el password en el primer login.

**4. Confirmar URL del servidor:**

Rancher te preguntará la URL desde donde se accederá. Confirma la URL mostrada.

**5. Dashboard inicial:**

Verás el dashboard con:
- **local cluster**: El clúster K3s donde está instalado Rancher
- Opción para crear o importar más clústeres

### 0.7 Configurar firewall (opcional pero recomendado)

```bash
# Permitir SSH
sudo ufw allow 22/tcp

# Permitir HTTP/HTTPS (Rancher UI)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Permitir Kubernetes API
sudo ufw allow 6443/tcp

# Habilitar firewall
sudo ufw enable
sudo ufw status
```

### 0.8 Verificación final

**1. Verificar acceso a Kubernetes desde Rancher:**

En la UI de Rancher:
- Click en `local` (el clúster K3s)
- Navegar a `Workloads` → `Pods`
- Deberías ver todos los pods del sistema

**2. Descargar kubeconfig desde Rancher:**

- En la UI: `local` cluster → menú ⋮ → `Download KubeConfig`
- Guardar localmente como `~/rancher-kubeconfig.yaml`

**3. Probar acceso remoto:**

```bash
export KUBECONFIG=~/rancher-kubeconfig.yaml
kubectl get nodes
kubectl get pods -A
```

### 0.9 Troubleshooting común

**Problema: Rancher pod en CrashLoopBackOff**

```bash
# Ver logs
kubectl -n cattle-system logs -l app=rancher --tail=100

# Verificar cert-manager
kubectl get pods -n cert-manager
kubectl -n cert-manager logs -l app=cert-manager --tail=50
```

**Problema: No puedo acceder a la UI (timeout)**

```bash
# Verificar que el Ingress está configurado
kubectl -n cattle-system get ingress

# Verificar que el Service está arriba
kubectl -n cattle-system get svc rancher

# Verificar firewall
sudo ufw status
```

**Problema: Certificado SSL autofirmado en producción**

```bash
# Reinstalar Rancher con Let's Encrypt
helm uninstall rancher -n cattle-system

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.midominio.com \
  --set replicas=1 \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=tu@email.com \
  --set bootstrapPassword=admin123
```

---

## 1. ¿Qué es Rancher?

**Rancher** es una plataforma de gestión de Kubernetes que permite:

- **Varios clústeres** desde una misma consola (multi-cluster).
- **Importar** clústeres existentes (por ejemplo K3s o RKE2) o **crear** nuevos.
- **Control de acceso**: usuarios, roles y políticas por clúster o por proyecto.
- **Dashboards** y vistas unificadas (pods, workloads, logs, shell en contenedor).

En el curso, Rancher será la “ventana” desde la que los alumnos verán y operarán el clúster K3s.

---

## 2. Gestión de clústeres

- **Clusters**: lista de clústeres conectados (K3s, RKE2, EKS, GKE, etc.).
- **Proyectos/Namespaces**: organización lógica dentro de un clúster (por equipo, entorno o aplicación).
- Desde Rancher se pueden ver métricas, eventos y estado de los nodos.

Flujo típico:

1. Acceder a Rancher (URL y credenciales que proporcione el formador).
2. Seleccionar el clúster (por ejemplo, el K3s del curso).
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

1. Conectar Rancher al clúster K3s (si no está ya conectado).
2. Crear un **proyecto** o **namespace** por alumno o por equipo.
3. Asignar un **rol** de proyecto (por ejemplo “Member” o “Read-only” en otro proyecto).
4. Pedir a los alumnos que desplieguen una aplicación desde la UI o con `kubectl` y que comprueben en el dashboard los recursos creados.

Los ejemplos de la carpeta `ejemplos/02-kubernetes/` y `ejemplos/06-rancher/` se pueden desplegar y revisar desde Rancher.

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
   kubectl apply -f ejemplos/02-kubernetes/demo-kafka-microservices.yaml -n curso-rancher
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

## 6. Ejemplo guiado del curso

Para una práctica paso a paso de Rancher + K3s, usar el material en `ejemplos/06-rancher/`:

1. Aplicar `namespace.yaml`, `deployment.yaml`, `service.yaml` e `ingress.yaml`.
2. Validar Workloads y Service Discovery desde la UI de Rancher.
3. Escalar el Deployment desde Rancher para observar cambios en tiempo real.
4. Probar el Ingress y revisar logs de Pods.

---

## 7. Escenario cloud alternativo: Rancher + K3s en una VM Ubuntu

> **Nota:** La sección 0 ya usa K3s como ruta principal para el curso. Esta sección mantiene un escenario de VM cloud simplificado para laboratorio.

**Diferencias K3s vs RKE2:**

| Característica | K3s | RKE2 |
|----------------|-----|------|
| **Peso** | ~50 MB | ~200 MB |
| **Uso de memoria** | ~512 MB | ~1-2 GB |
| **Certificación** | IoT/Edge | Enterprise (FIPS 140-2) |
| **Complejidad** | Muy simple | Producción-ready |
| **Caso de uso** | Desarrollo, IoT | Producción enterprise |

Para que el alumnado vea **Rancher gestionando un clúster real**, puedes levantar un entorno sencillo en la nube (por ejemplo AWS) con:

- 1 VM Ubuntu 24.04 (2 vCPU, 4 GB RAM, 40 GB disco - requisitos mínimos para K3s).
- Un clúster **K3s** instalado en esa VM.
- **Rancher** desplegado dentro de ese K3s y expuesto por HTTPS.

### 7.1 Crear la VM (ejemplo AWS)

- AMI: Ubuntu Server 24.04 LTS.
- Tipo: `t3.small` (mínimo) o `t3.medium` (recomendado).
- Security Group:
  - TCP 22 (SSH) desde tu IP.
  - TCP 80 y 443 desde `0.0.0.0/0` (acceso de los alumnos al panel de Rancher).
  - TCP 6443 (Kubernetes API) - opcional, solo si quieres acceso directo con kubectl.

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

---

## 8. Resumen de instalación

### Opción recomendada para el curso: K3s + Rancher

```bash
# 1. Instalar K3s
curl -sfL https://get.k3s.io | sh -
sudo systemctl enable k3s
sudo systemctl start k3s

# 2. Configurar kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# 3. Instalar Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 4. Instalar cert-manager
helm repo add jetstack https://charts.jetstack.io
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true

# 5. Instalar Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=TU_HOSTNAME \
  --set replicas=1 \
  --set bootstrapPassword=admin123

# 6. Acceder a Rancher UI
# https://TU_HOSTNAME (usuario: admin, password: admin123)
```

### Opción alternativa enterprise: RKE2 + Rancher

Si necesitas un enfoque más cercano a producción enterprise, usa RKE2 en lugar de K3s y conserva el resto del flujo (Helm, cert-manager y Rancher).

---

## 9. Referencias

- **RKE2 Documentación:** https://docs.rke2.io/
- **Rancher Documentación:** https://ranchermanager.docs.rancher.com/
- **K3s Documentación:** https://k3s.io/
- **Helm Documentación:** https://helm.sh/docs/
- **cert-manager:** https://cert-manager.io/docs/

### Diferencias RKE2 vs K3s vs RKE1

| | RKE2 | K3s | RKE1 |
|---|------|-----|------|
| **Tipo** | Binary install | Binary install | Docker-based |
| **Certificación** | FIPS 140-2, CIS | Edge/IoT | Enterprise |
| **Peso** | ~200 MB | ~50 MB | Depende de Docker |
| **RAM mínima** | 8 GB | 512 MB | 4 GB |
| **Caso de uso** | Producción enterprise | Desarrollo, Edge | Legacy (deprecado) |
| **Soporte Rancher** | ✅ Full | ✅ Full | ⚠️ Limitado |

**Recomendación para el curso:** K3s para laboratorio y formación guiada; RKE2 como extensión enterprise.


