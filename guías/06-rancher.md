# Guía 06 — RKE2 + Rancher en Ubuntu

> Basado en: https://github.com/gastonmartres/youtube/tree/main/rke2-rancher

---

## 1. Instalación de RKE2 Server

El archivo de configuración principal de RKE2 es `config.yaml`. En las siguientes líneas veremos los distintos pasos y configuraciones necesarios para desplegar nuestro clúster de RKE2.

### 1.1 Ubicación del archivo de configuración

```
/etc/rancher/rke2/config.yaml
```

### 1.2 Generar el Token

El token se usa para que los nodos puedan unirse al clúster:

```bash
head -c 16 /dev/urandom | sha256sum | awk '{print $1}'
```

Ejemplo de resultado:
```
dc6801605649f15ff5fae878c6b8b8c0b783590c92d24b033a211229981da82c
```

Copia la cadena y guárdala en un editor para usarla más adelante.

### 1.3 Crear el archivo de configuración

```bash
sudo mkdir -p /etc/rancher/rke2
sudo nano /etc/rancher/rke2/config.yaml
```

Contenido del archivo:

```yaml
write-kubeconfig-mode: "0644"
etcd-snapshot-schedule-cron: "*/6 * * *"
etcd-snapshot-retention: 56
token: "TU_TOKEN_AQUI"
tls-san:
  - "rancher.example.com"
cni:
  - canal
```

> Reemplaza `TU_TOKEN_AQUI` por el token generado en el paso anterior.

### 1.4 Descargar RKE2 e iniciar el servicio

```bash
curl -sfL https://get.rke2.io | sh -
```

Una vez descargado, habilitar e iniciar el servicio:

```bash
sudo systemctl enable --now rke2-server
```

> Este proceso puede tardar dependiendo de la velocidad de internet y el rendimiento de la máquina.

Verificar estado:

```bash
sudo systemctl status rke2-server
```

Ver logs en tiempo real si hay problemas:

```bash
journalctl -xeu rke2-server -f
```

---

## 2. Instalar kubectl

```bash
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

La variable `KUBECONFIG` especifica la ubicación del archivo con las credenciales para acceder al clúster. El archivo se genera automáticamente al finalizar la instalación de `rke2-server`:

```bash
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
```

Para que persista en cada sesión:

```bash
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
source ~/.bashrc
```

Verificar el clúster:

```bash
kubectl get nodes
```

Ejemplo de salida:
```
NAME              STATUS   ROLES                       AGE   VERSION
ea-ubuntu         Ready    control-plane,etcd,master   14d   v1.30.7+rke2r1
```

Listar todos los pods en ejecución:

```bash
kubectl get pods -A
```

> El modificador `-A` muestra todos los pods en todos los namespaces.

Ejemplo de salida:
```
NAMESPACE     NAME                                                   READY   STATUS      RESTARTS   AGE
kube-system   cloud-controller-manager-ea-ubuntu                    1/1     Running     2          14d
kube-system   etcd-ea-ubuntu                                        1/1     Running     1          14d
kube-system   helm-install-rke2-canal-bthmt                         0/1     Completed   0          14d
kube-system   helm-install-rke2-coredns-6mwk9                       0/1     Completed   0          14d
kube-system   helm-install-rke2-ingress-nginx-c8kqr                 0/1     Completed   0          14d
kube-system   kube-apiserver-ea-ubuntu                              1/1     Running     3          14d
kube-system   kube-controller-manager-ea-ubuntu                     1/1     Running     2          14d
kube-system   kube-proxy-ea-ubuntu                                  1/1     Running     1          14d
kube-system   kube-scheduler-ea-ubuntu                              1/1     Running     1          14d
kube-system   rke2-canal-nft4l                                      2/2     Running     2          14d
kube-system   rke2-coredns-rke2-coredns-867d6d5c55-jpgjg            1/1     Running     1          14d
kube-system   rke2-ingress-nginx-controller-8bk8k                   1/1     Running     1          14d
kube-system   rke2-metrics-server-75866c5bb5-t6f62                  1/1     Running     1          14d
```

---

## 3. Agregar un nodo Agente (Worker)

### Diferencia entre Nodo Server y Nodo Agente

**Nodo Server:**
- Administra el estado del clúster y realiza tareas de control.
- Aloja los componentes del plano de control: API Server, Controller Manager, Scheduler, etcd.

**Nodo Agente:**
- No aloja el plano de control.
- Se conecta al nodo server para recibir instrucciones.
- Solo ejecuta pods y gestiona la comunicación de red.

| Función          | Nodo Server                          | Nodo Agente                              |
|------------------|--------------------------------------|------------------------------------------|
| Rol principal    | Gestionar el estado del clúster      | Ejecutar cargas de trabajo (pods)        |
| Componentes      | API Server, etcd, Scheduler          | Kubelet, container runtime, kube-proxy   |
| Almacena estado  | Sí, a través de etcd                 | No                                       |
| Responsabilidad  | Administración y orquestación        | Ejecución de aplicaciones                |

### 3.1 Crear el archivo de configuración del agente

En el nodo agente:

```bash
sudo mkdir -p /etc/rancher/rke2
sudo nano /etc/rancher/rke2/config.yaml
```

Contenido:

```yaml
server: https://IP_DEL_NODO_SERVER:9345
write-kubeconfig-mode: "0644"
token: "TU_TOKEN_AQUI"
tls-san:
  - "rancher.example.com"
```

Descripción de los parámetros:
- `server`: IP o DNS del nodo server principal.
- `write-kubeconfig-mode`: Permisos del archivo kubeconfig.
- `token`: El mismo token configurado en el nodo server.
- `tls-san`: Nombres adicionales en el certificado de RKE2.
- `node-label`: (Opcional) Etiqueta para usar como `selector` en manifiestos.

### 3.2 Instalar RKE2 en modo agente

```bash
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
```

### 3.3 Habilitar e iniciar el agente

```bash
sudo systemctl enable --now rke2-agent
```

Ver logs si tarda más de 5 minutos o hay problemas:

```bash
journalctl -xeu rke2-agent -f
```

Verificar desde el nodo server:

```bash
kubectl get nodes
```

Ejemplo con varios nodos:
```
NAME              STATUS   ROLES                       AGE   VERSION
ea-ubuntu-01      Ready    control-plane,etcd,master   19h   v1.31.4+rke2r1
ea-ubuntu-02      Ready    <none>                      19h   v1.31.4+rke2r1
ea-ubuntu-03      Ready    <none>                      19h   v1.31.4+rke2r1
```

---

## 4. Instalación de Rancher

### 4.1 Instalar Helm

```bash
curl -sLO https://get.helm.sh/helm-$(curl -L -s https://get.helm.sh/helm-latest-version)-linux-amd64.tar.gz
tar zxvf helm-*-linux-amd64.tar.gz
sudo install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm
```

Verificar:

```bash
helm version
```

### 4.2 Agregar el repositorio de Rancher

```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

### 4.3 Crear el namespace de Rancher

```bash
kubectl create namespace cattle-system
```

### 4.4 Instalar cert-manager

Cert-manager automatiza la gestión de certificados TLS/SSL en el clúster (emisión, renovación y validación desde CAs como Let's Encrypt).

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.16.2
```

Verificar progreso:

```bash
kubectl get pods -n cert-manager
```

Todos los pods deben estar en estado `Running` antes de continuar.

### 4.5 Instalar Rancher

```bash
export FQDN="rancher.example.com"
export RANCHERPASS="changeme"

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=${FQDN} \
  --set bootstrapPassword=${RANCHERPASS} \
  --set global.cattle.psp.enabled=false
```

> La instalación puede tardar varios minutos según la velocidad de internet y el hardware.

Verificar progreso:

```bash
kubectl get pods -n cattle-system -w
```

---

## 5. Acceder a Rancher desde Windows con VirtualBox NAT

### 5.1 Regla de reenvío de puertos en VirtualBox

En la VM → Configuración → Red → Adaptador 1 (NAT) → Reenvío de puertos:

| Nombre        | Protocolo | IP anfitrión | Puerto anfitrión | IP invitado | Puerto invitado |
|---------------|-----------|--------------|------------------|-------------|-----------------|
| Rancher-HTTPS | TCP       | 127.0.0.1    | 443             | 10.0.2.15   | 443             |

### 5.2 Agregar entrada en el archivo hosts de Windows

Abrir **PowerShell como Administrador** y ejecutar:

```powershell
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 rancher.example.com"
```

Verificar:

```powershell
Get-Content "C:\Windows\System32\drivers\etc\hosts" | Select-String "rancher"
```

Limpiar caché DNS:

```cmd
ipconfig /flushdns
```

En Edge/Chrome: `edge://net-internals/#dns` → **Clear host cache**

### 5.3 Acceder a Rancher

```
https://rancher.example.com
```

> Acepta la advertencia del certificado autofirmado. La contraseña inicial es `changeme` (o la que definiste en `RANCHERPASS`).

---

## 6. Verificación general

```bash
# Nodos del clúster
kubectl get nodes

# Pods de Rancher
kubectl get pods -n cattle-system

# Ingress de Rancher (hostname configurado)
kubectl get ingress -n cattle-system

# Servicios de Rancher
kubectl get svc -n cattle-system
```
