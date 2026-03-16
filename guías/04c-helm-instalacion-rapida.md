# Guía rápida: instalar Helm para trabajar con Kubernetes

Esta guía explica cómo instalar **Helm** en los sistemas más habituales (macOS, Windows y Linux) para usarlo en las prácticas del curso (por ejemplo, instalar Vault en Kubernetes).

> Objetivo: que el comando `helm version` funcione sin errores en la terminal del alumno.

---

## 1. Comprobar si ya tienes Helm instalado

Antes de instalar, prueba:

```bash
helm version
```

Si ves algo como:

```text
version.BuildInfo{Version:"v3.x.x", ...}
```

ya lo tienes instalado y puedes pasar a las guías de Vault.  
Si aparece `command not found` o un error similar, sigue las instrucciones de tu sistema operativo.

---

## 2. Instalación en macOS (Homebrew recomendado)

### 2.1. Con Homebrew (recomendado)

Si usas macOS y tienes [Homebrew](https://brew.sh/) instalado:

```bash
brew install helm
```

Actualizar Helm más adelante:

```bash
brew upgrade helm
```

### 2.2. Sin Homebrew (alternativa)

Puedes usar el script oficial:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

> Nota: revisa el script antes de ejecutarlo si quieres ver qué hace exactamente.

---

## 3. Instalación en Windows

### 3.1. Con Chocolatey (PowerShell / CMD)

Si tienes [Chocolatey](https://chocolatey.org/) instalado:

```powershell
choco install kubernetes-helm
```

Para actualizar más adelante:

```powershell
choco upgrade kubernetes-helm
```

### 3.2. Con Scoop (PowerShell)

Si usas [Scoop](https://scoop.sh/):

```powershell
scoop install helm
```

### 3.3. Descarga manual (ZIP)

1. Ir a la página de releases de Helm: `https://github.com/helm/helm/releases`.
2. Descargar el ZIP de Windows (por ejemplo, `helm-v3.x.x-windows-amd64.zip`).
3. Descomprimir y copiar el binario `helm.exe` a una carpeta incluida en el `PATH` (por ejemplo, `C:\Users\<tu-usuario>\bin`).
4. Cerrar y abrir de nuevo la terminal, luego probar:

```powershell
helm version
```

---

## 4. Instalación en Linux

### 4.1. Distribuciones basadas en Debian/Ubuntu

Algunas distros incluyen Helm en sus repositorios, pero la forma más directa y actualizada es usar el script oficial:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Si prefieres paquetes del sistema:

```bash
sudo snap install helm --classic
```

> Ten en cuenta que las versiones de Snap/apt pueden ir un poco por detrás de la última versión oficial.

### 4.2. Otras distribuciones

También puedes usar el script oficial (funciona en la mayoría de sistemas):

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## 5. Verificación final

Después de instalar, abre una terminal nueva y ejecuta:

```bash
helm version
```

Si ves la versión sin errores, ya puedes seguir las guías:

- `04b-hashicorp-vault-k8s-docker-desktop.md` (instalar Vault en Kubernetes),
- y el resto de ejemplos del curso que usan `helm`.

En caso de problemas habituales:

- **`command not found`**: revisa que la carpeta donde está el binario de `helm` esté en tu variable `PATH`.
- **Permisos**: en Linux/macOS, puede que necesites `chmod +x /ruta/a/helm` si el binario no es ejecutable.

