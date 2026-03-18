# Guía Docker Desktop Windows con PowerShell

Esta guía cubre la configuración específica para Docker Desktop en Windows usando PowerShell.

---

## 📋 Pre-requisitos

### 1. Instalar Docker Desktop

1. Descarga desde: https://www.docker.com/products/docker-desktop
2. Ejecuta el instalador
3. Reinicia tu computadora cuando te lo pida

### 2. Habilitar Kubernetes en Docker Desktop

1. Abre Docker Desktop
2. Click en el icono de engranaje (Settings)
3. Navega a **Kubernetes**
4. Marca ✅ **Enable Kubernetes**
5. Click **Apply & Restart**
6. Espera ~2-3 minutos hasta que veas "Kubernetes is running"

![Docker Desktop Kubernetes Settings](https://kubernetes.io/images/docs/docker-for-mac-enable-kubernetes.png)

### 3. Instalar Chocolatey (gestor de paquetes)

Abre PowerShell **como Administrador** y ejecuta:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Cierra y vuelve a abrir PowerShell.

### 4. Instalar herramientas con Chocolatey

```powershell
# Instalar kubectl
choco install kubernetes-cli -y

# Instalar Helm
choco install kubernetes-helm -y

# Instalar Consul CLI (opcional pero recomendado)
choco install consul -y

# Instalar Vault CLI (opcional pero recomendado)
choco install vault -y
```

### 5. Verificar instalación

```powershell
kubectl version --client
helm version
docker --version
consul version
vault version
```

**Resultado esperado:**
```
Client Version: v1.28.x
version.BuildInfo{Version:"v3.13.x"...
Docker version 24.x.x
Consul v1.17.x
Vault v1.15.x
```

---

## 🛠️ Configuración de kubectl para Docker Desktop

Docker Desktop configura kubectl automáticamente, pero verifica:

```powershell
# Ver contextos disponibles
kubectl config get-contexts

# Debe mostrar algo como:
# CURRENT   NAME                 CLUSTER          AUTHINFO         NAMESPACE
# *         docker-desktop       docker-desktop   docker-desktop

# Si no está activo, actívalo:
kubectl config use-context docker-desktop

# Verificar conectividad
kubectl cluster-info
kubectl get nodes
```

---

## 🚀 Ejecución de los scripts

### Política de ejecución de PowerShell

Si recibes error `cannot be loaded because running scripts is disabled`, ejecuta:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Ejecutar scripts de setup

```powershell
# Navega a la carpeta de scripts
cd ejemplos\05-consul\scripts

# Ejecutar scripts (el orden importa)
.\setup-consul.ps1
.\setup-vault.ps1
.\verify-setup.ps1
```

### Port-forwarding en segundo plano

Para mantener un port-forward activo en background:

```powershell
# Iniciar en background
$job = Start-Job -ScriptBlock { kubectl port-forward -n consul svc/consul-ui 8500:80 }

# Verificar estado
Get-Job

# Detener cuando termines
Stop-Job -Job $job
Remove-Job -Job $job
```

O usa nuestro script dedicado:
```powershell
.\port-forward-ui.ps1
# Ctrl+C para detener
```

---

## 💡 Diferencias Windows vs Linux/macOS

### Rutas de archivo

```powershell
# Windows usa backslash
cd ejemplos\05-consul\scripts

# Pero kubectl acepta ambos
kubectl apply -f demo-01-discovery/
kubectl apply -f demo-01-discovery\
```

### Variables de entorno

```powershell
# PowerShell usa $env:
$env:CONSUL_HTTP_ADDR = "http://localhost:8500"
$env:VAULT_ADDR = "http://localhost:8200"
$env:VAULT_TOKEN = "root"

# Ver todas las variables
Get-ChildItem Env:

# Eliminar variable
Remove-Item Env:\CONSUL_HTTP_ADDR
```

### Comandos equivalentes

| Bash/Linux | PowerShell | Descripción |
|------------|------------|-------------|
| `curl` | `Invoke-RestMethod` o `Invoke-WebRequest` | HTTP requests |
| `cat file.txt` | `Get-Content file.txt` | Leer archivo |
| `grep pattern` | `Select-String -Pattern pattern` | Buscar texto |
| `export VAR=value` | `$env:VAR = "value"` | Variables de entorno |
| `sleep 5` | `Start-Sleep -Seconds 5` | Pausar |
| `ps aux \| grep consul` | `Get-Process \| Select-String consul` | Buscar proceso |

### Curl vs Invoke-RestMethod

```powershell
# Bash/curl
curl http://localhost:8500/v1/status/leader

# PowerShell equivalente
Invoke-RestMethod -Uri http://localhost:8500/v1/status/leader

# Para ver headers y status code completo
Invoke-WebRequest -Uri http://localhost:8500/v1/status/leader
```

---

## 🔧 Configuración específica de Docker Desktop

### Límites de recursos

Docker Desktop permite configurar recursos dedicados:

1. Settings > Resources > Advanced
2. Configura:
   - **CPUs:** Mínimo 4 (recomendado para estas demos)
   - **Memory:** Mínimo 8GB (recomendado para estas demos)
   - **Disk image size:** Mínimo 60GB

### StorageClass por defecto

Docker Desktop viene con un `StorageClass` llamado `hostpath`:

```powershell
kubectl get storageclass
# NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   
# hostpath (default)   docker.io/hostpath   Delete          Immediate
```

Nuestros manifests usan `storageClassName: hostpath` que es compatible con Docker Desktop.

### Networking

Docker Desktop usa el hostname `host.docker.internal` para acceder al host:

```yaml
# Para conectarte desde un pod a servicios en tu laptop
- name: HOST_API
  value: "http://host.docker.internal:3000"
```

### Kubernetes API Server

En Docker Desktop, el Kubernetes API Server está en:
- **Internal:** `https://10.96.0.1:443` (usado por pods)
- **External:** `https://kubernetes.docker.internal:6443` (usado por kubectl)

---

## 🐛 Troubleshooting específico de Windows

### "kubectl: command not found" después de instalar

Cierra y vuelve a abrir PowerShell para recargar el PATH.

### Port-forward se desconecta constantemente

Deshabilita Windows Defender Firewall temporalmente o agrega una regla:

```powershell
# Como Administrador
New-NetFirewallRule -DisplayName "Kubectl Port Forward" `
    -Direction Inbound -Protocol TCP -LocalPort 8200,8500 -Action Allow
```

### Docker Desktop no inicia

1. Verifica que WSL2 esté instalado:
   ```powershell
   wsl --status
   ```
2. Si no está instalado:
   ```powershell
   wsl --install
   ```
3. Reinicia tu computadora

### Pods en "Pending" o "ImagePullBackOff"

```powershell
# Ver detalles del pod
kubectl describe pod <pod-name>

# Verificar eventos del cluster
kubectl get events --sort-by='.lastTimestamp'
```

**Solución común:** Docker Desktop puede tener límites de recursos muy bajos. Aumenta CPU/Memory en Settings.

### "Unable to connect to the server"

```powershell
# Reiniciar Kubernetes en Docker Desktop
# Settings > Kubernetes > Reset Kubernetes Cluster

# Luego espera 2-3 minutos y verifica
kubectl cluster-info
```

### Helm install falla con timeout

Docker Desktop puede ser lento al descargar imágenes la primera vez:

```powershell
# Ver progreso de download de imágenes
kubectl get events --watch

# Aumentar timeout en los scripts
# En setup-consul.ps1 y setup-vault.ps1, cambia:
--timeout 5m
# a:
--timeout 10m
```

---

## 🎯 Comandos útiles para debugging

```powershell
# Ver todos los recursos en todos los namespaces
kubectl get all --all-namespaces

# Ver logs de múltiples pods
kubectl logs -l app=backend-service --all-containers=true --tail=50

# Ejecutar comando en un pod
kubectl exec -it <pod-name> -- sh

# Ver consumo de recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Ver definición completa de un recurso
kubectl get pod <pod-name> -o yaml

# Ver solo ciertos campos
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

---

## 📚 Recursos adicionales

- **Docker Desktop docs:** https://docs.docker.com/desktop/kubernetes/
- **kubectl en Windows:** https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
- **Helm en Windows:** https://helm.sh/docs/intro/install/#from-chocolatey-windows
- **PowerShell 101:** https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction

---

## ✅ Checklist final

Antes de empezar las demos, verifica:

- [ ] Docker Desktop está running (ícono verde en la bandeja)
- [ ] Kubernetes está habilitado (Settings > Kubernetes)
- [ ] `kubectl cluster-info` funciona
- [ ] `helm version` funciona
- [ ] Tienes al menos 8GB RAM asignado a Docker Desktop
- [ ] Puedes ejecutar scripts PowerShell (ExecutionPolicy configurado)
- [ ] `.\verify-setup.ps1` pasa todos los checks

**Si todo está ✅, ¡estás listo para empezar con las demos!**

Continúa con [QUICK-START-POWERSHELL.md](QUICK-START-POWERSHELL.md) para ejecutar los 4 demos.
