# Ejemplos HashiCorp Consul + Vault — Guía 05

Este directorio contiene **demos prácticas completas** que muestran cómo **Consul** y **Vault** trabajan juntos en un entorno de microservicios en Kubernetes.

> **💡 Para usuarios de Windows:** Todas las demos incluyen **scripts PowerShell** (`.ps1`) además de bash. Lee [DOCKER-DESKTOP-WINDOWS.md](DOCKER-DESKTOP-WINDOWS.md) para configuración en Windows.

## 🚀 Inicio Rápido

**Linux/macOS:**
```bash
# 1. Instalar Consul y Vault
cd scripts/
./setup-consul.sh
./setup-vault.sh
./verify-setup.sh

# 2. Acceder a las UIs (en terminal separada)
./port-forward-ui.sh
# Consul: http://localhost:8500
# Vault:  http://localhost:8200 (token: root)

# 3. Ejecutar demos
cd ../demo-01-discovery/
kubectl apply -f .
```

**Windows (PowerShell):**
```powershell
# 1. Instalar Consul y Vault
cd scripts
.\setup-consul.ps1
.\setup-vault.ps1
.\verify-setup.ps1

# 2. Acceder a las UIs (en terminal separada)
.\port-forward-ui.ps1
# Consul: http://localhost:8500
# Vault:  http://localhost:8200 (token: root)

# 3. Ejecutar demos
cd ..\demo-01-discovery
kubectl apply -f .
```

**Ver guías de inicio rápido:**
- **Linux/macOS:** [QUICK-START.md](QUICK-START.md)
- **Windows/PowerShell:** [QUICK-START-POWERSHELL.md](QUICK-START-POWERSHELL.md)
- **Documentación completa:** [DEMOS-README.md](DEMOS-README.md)

## 📚 Demos Disponibles

| Demo | Descripción | Tiempo | Dificultad |
|------|-------------|--------|------------|
| **[Demo 1](demo-01-discovery/)** | Service Discovery básico | 20-30 min | ⭐ Básico |
| **[Demo 2](demo-02-health-checks/)** | Health Checks dinámicos | 25-35 min | ⭐⭐ Intermedio |
| **[Demo 3](demo-03-vault-consul/)** | Integración Vault + Consul | 30-40 min | ⭐⭐⭐ Avanzado |
| **[Demo 4](demo-04-dynamic-config/)** | Configuración dinámica | 25-35 min | ⭐⭐⭐ Avanzado |

## 🎯 ¿Qué Aprenderás?

- ✅ **Service Discovery**: Cómo los servicios se encuentran sin hardcodear IPs
- ✅ **Health Checks**: Resiliencia automática basada en salud de servicios
- ✅ **Secrets Management**: Cómo Vault inyecta credenciales de forma segura
- ✅ **Dynamic Configuration**: Cambiar configuración sin reiniciar aplicaciones

## 🔧 Prerequisitos

- Kubernetes cluster:
  - **Windows:** Docker Desktop con Kubernetes habilitado ([guía aquí](DOCKER-DESKTOP-WINDOWS.md))
  - **Linux/macOS:** Docker Desktop, Kind, Minikube, o AKS/EKS  
- `kubectl` instalado
- `helm` instalado
- (Opcional) `consul` CLI y `vault` CLI para comandos avanzados

> **Para Windows:** Consulta [DOCKER-DESKTOP-WINDOWS.md](DOCKER-DESKTOP-WINDOWS.md) para instrucciones completas de instalación.

## 📋 Registro de servicios

En Consul, los servicios se pueden registrar por:

- **Archivo de configuración** en los nodos del agente.
- **API HTTP** desde la aplicación o un sidecar.
- **Kubernetes**: Consul tiene un *sync catalog* que puede registrar Services de K8s en Consul automáticamente.

El archivo `service-definition.json` es un ejemplo de definición en formato JSON que usaría un agente Consul (por ejemplo en un sidecar o en un nodo que corre el servicio).

## 💡 Health check

El health check en la definición comprueba que HTTP en el puerto del servicio devuelva 200. Consul marca el servicio como *passing* o *failing* y solo devuelve instancias *passing* en las consultas DNS o API.

## 🛠️ Scripts Útiles

La carpeta `scripts/` contiene utilidades:

- **setup-consul.sh**: Instala Consul
- **setup-vault.sh**: Instala Vault en dev mode
- **verify-setup.sh**: Verifica que todo esté listo
- **port-forward-ui.sh**: Expone las UIs localmente
- **cleanup.sh**: Limpia todos los recursos

## 📖 Recursos Adicionales

- [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)
- [Vault on Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Learn Consul](https://learn.hashicorp.com/consul)
- [Learn Vault](https://learn.hashicorp.com/vault)

---

**¡Empieza con [DEMOS-README.md](DEMOS-README.md)!** 🚀
