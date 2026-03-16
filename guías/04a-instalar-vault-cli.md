# Guía 04a — Instalar el CLI de HashiCorp Vault

Esta guía explica cómo instalar el **cliente de línea de comandos de Vault (`vault`)** en tu máquina, para que puedas ejecutar comandos como `vault status` o `vault kv put ...` contra un servidor Vault (por ejemplo, el que desplegamos en Kubernetes).

> Objetivo: que el comando `vault version` funcione sin errores en tu terminal.

---

## 1. Comprobar si ya tienes Vault CLI

En cualquier sistema:

```bash
vault version
```

Si ves algo como:

```text
Vault v1.x.x (...)
```

ya tienes el CLI instalado y puedes pasar a las otras guías (`04b`, `04-hashicorp-vault.md`, etc.).  
Si aparece `command not found` o error similar, sigue las instrucciones para tu sistema operativo.

---

## 2. Instalación en Windows

### 2.1. Con Chocolatey (recomendado)

En **PowerShell** con permisos de administrador (o CMD):

```powershell
choco install vault
```

Para actualizar más adelante:

```powershell
choco upgrade vault
```

### 2.2. Descarga manual (ZIP)

1. Ir a la página oficial de descargas de Vault: `https://developer.hashicorp.com/vault/downloads`.
2. Descargar el ZIP de Windows (por ejemplo `vault_1.x.x_windows_amd64.zip`).
3. Descomprimir el archivo.
4. Copiar el binario `vault.exe` a una carpeta incluida en el `PATH` (por ejemplo `C:\Users\<tu-usuario>\bin` o `C:\Tools\bin`).
5. Cerrar y abrir una nueva ventana de PowerShell o CMD.
6. Probar:

```powershell
vault version
```

Si el comando funciona, la instalación está correcta.

---

## 3. Instalación en macOS

### 3.1. Con Homebrew (recomendado)

Si usas macOS y tienes [Homebrew](https://brew.sh/) instalado:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/vault
```

Actualizar más adelante:

```bash
brew upgrade hashicorp/tap/vault
```

### 3.2. Descarga manual (tar.gz)

1. Ir a `https://developer.hashicorp.com/vault/downloads`.
2. Descargar el tarball de macOS (por ejemplo `vault_1.x.x_darwin_amd64.zip` o `darwin_arm64`).
3. Descomprimir y mover el binario `vault` a una carpeta del `PATH` (por ejemplo `/usr/local/bin`).

```bash
sudo mv vault /usr/local/bin/
vault version
```

---

## 4. Instalación en Linux

### 4.1. Script oficial (cualquier distro)

La forma más directa es usar el script oficial de HashiCorp:

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
curl https://raw.githubusercontent.com/hashicorp/vault/main/scripts/install.sh | sudo bash
```

O bien, usar el script estándar de instalación (cuando esté disponible):

```bash
curl https://raw.githubusercontent.com/hashicorp/vault/main/scripts/install.sh | sudo bash
```

> Revisa el contenido del script si quieres ver qué hace exactamente.

### 4.2. Paquetes por distribución (alternativa)

Consulta la documentación oficial para tu distro en `https://developer.hashicorp.com/vault/install`.  
Por ejemplo, en Ubuntu/Debian se puede usar el repositorio APT de HashiCorp.

---

## 5. Verificación final

Tras la instalación, abre una nueva terminal y ejecuta:

```bash
vault version
```

Si ves la versión de Vault, el CLI está listo.

En combinación con las demás guías del módulo:

- Usa **`04b-hashicorp-vault-k8s-docker-desktop.md`** para desplegar Vault en Kubernetes.
- Configura las variables `VAULT_ADDR` y `VAULT_TOKEN` como se indica allí.
- Luego ya podrás ejecutar comandos como:

```bash
vault status
vault kv put secret/mi-app/db username="appuser" password="changeme"
vault kv get secret/mi-app/db
```

