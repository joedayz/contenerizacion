# Demos Consul + Vault - Guía Práctica Completa

Este directorio contiene demos progresivas que muestran cómo **Consul** y **Vault** trabajan juntos en un entorno de microservicios en Kubernetes.

## 🎯 Objetivos de Aprendizaje

Al completar estas demos, tus alumnos entenderán:

1. **Service Discovery**: Cómo los servicios se encuentran entre sí sin hardcodear IPs
2. **Health Checks**: Cómo Consul garantiza que solo servicios saludables reciben tráfico
3. **Secrets Management**: Cómo Vault inyecta secretos de forma segura
4. **Configuración Dinámica**: Cómo usar Consul KV junto con Vault para configuración en tiempo real

## 📚 Demos Incluidas

### Demo 1: Service Discovery Básico
**Carpeta**: `demo-01-discovery/`  
**Duración**: 20-30 minutos  
**Conceptos**: Service registration, DNS resolution, Consul API

Dos microservicios simples (Quarkus):
- **product-service**: API que devuelve productos
- **order-service**: API que consume product-service usando Consul DNS

Los alumnos verán cómo los servicios se descubren automáticamente sin configuración estática.

### Demo 2: Health Checks Dinámicos
**Carpeta**: `demo-02-health-checks/`  
**Duración**: 25-35 minutos  
**Conceptos**: Health checks HTTP, circuit breaking, failover automático

Servicios con health checks que pueden "enfermarse":
- Endpoint para cambiar el estado de salud
- Consul automáticamente quita servicios no saludables del pool
- Los clientes solo reciben instancias saludables

### Demo 3: Vault + Consul Integrados
**Carpeta**: `demo-03-vault-consul/`  
**Duración**: 30-40 minutos  
**Conceptos**: Vault Agent Injector, Kubernetes auth, service mesh

Aplicación completa que usa:
- **Vault**: Para credenciales de base de datos
- **Consul**: Para descubrir la base de datos y otros servicios
- **PostgreSQL**: Base de datos con credenciales desde Vault

### Demo 4: Configuración Dinámica
**Carpeta**: `demo-04-dynamic-config/`  
**Duración**: 25-35 minutos  
**Conceptos**: Consul KV store, config reload, feature flags

Aplicación que:
- Lee configuración no sensible desde Consul KV
- Lee secretos desde Vault
- Recarga configuración sin reiniciar (hot reload)

## 🚀 Prerequisitos

### Software Necesario

**Linux/macOS:**
```bash
# Verificar que tienes todo instalado
kubectl version --client
helm version
consul version  # Opcional, para CLI
vault version   # Opcional, para CLI
```

**Windows (PowerShell):**
```powershell
# Verificar que tienes todo instalado
kubectl version --client
helm version
consul version  # Opcional, para CLI
vault version   # Opcional, para CLI
```

> **💡 Para usuarios de Windows:** Todas las demos incluyen **scripts PowerShell** (`.ps1`) además de bash. Ve a [DOCKER-DESKTOP-WINDOWS.md](DOCKER-DESKTOP-WINDOWS.md) para la guía completa de setup en Windows.

### Clúster Kubernetes

Cualquiera de estos:
- **Docker Desktop con Kubernetes habilitado** (recomendado para Windows)
- Kind
- Minikube
- AKS/EKS (para ambiente cloud)

> **Para Docker Desktop en Windows:** Lee [DOCKER-DESKTOP-WINDOWS.md](DOCKER-DESKTOP-WINDOWS.md) antes de continuar.

### Instalar Consul

**Linux/macOS:**
```bash
# Agregar repo de Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Instalar Consul con valores por defecto para desarrollo
helm install consul hashicorp/consul \
  --set global.name=consul \
  --set server.replicas=1 \
  --set ui.enabled=true \
  --set connectInject.enabled=true \
  --create-namespace \
  --namespace consul
```

**Windows (PowerShell):**
```powershell
# O simplemente usa el script preparado:
cd scripts
.\setup-consul.ps1
```

### Instalar Vault (si ya no lo tienes)

**Linux/macOS:** **en bash (.sh) y PowerShell (.ps1)**:

- `setup-consul`: Instala Consul con configuración optimizada para demos
- `setup-vault`: Configura Vault con las policies necesarias
- `verify-setup`: Verifica que todo está funcionando
- `cleanup`: Limpia todos los recursos de las demos
- `port-forward-ui`: Expone las UIs de Consul y Vault localmente

### Uso rápido (Linux/macOS):

```bash
# Setup completo
cd scripts/
./setup-consul.sh
./setup-vault.sh
./verify-setup.sh

# Acceder a las UIs
./port-forward-ui.sh
# Consul UI: http://localhost:8500
# Vault UI: http://localhost:8200

# Limpieza al final
./cleanup.sh
```

### Uso rápido (Windows/PowerShell):

```powershell
# Setup completo
cd scripts
.\setup-consul.ps1
.\setup-vault.ps1
.\verify-setup.ps1

# Acceder a las UIs
.\port-forward-ui.ps1
# Consul UI: http://localhost:8500
# Vault UI: http://localhost:8200

# Limpieza al final
.\cleanup.ps1
```

## ⚡ Quick Start

¿Quieres empezar rápido sin leer toda la documentación?

- **Para Linux/macOS:** Ve a [QUICK-START.md](QUICK-START.md)
- **Para Windows/PowerShell:** Ve a [QUICK-START-POWERSHELL.md](QUICK-START-POWERSHELL.md)**Demo 3**: Integrar Vault para ver el flujo completo
4. **Demo 4**: Configuración avanzada (opcional, para grupos avanzados)

## 🛠️ Scripts Útiles

La carpeta `scripts/` contiene utilidades comunes:

- `setup-consul.sh`: Instala Consul con configuración optimizada para demos
- `setup-vault.sh`: Configura Vault con las policies necesarias
- `verify-setup.sh`: Verifica que todo está funcionando
- `cleanup.sh`: Limpia todos los recursos de las demos
- `port-forward-ui.sh`: Expone las UIs de Consul y Vault localmente

### Uso rápido:

```bash
# Setup completo
cd scripts/
./setup-consul.sh
./setup-vault.sh
./verify-setup.sh

# Acceder a las UIs
./port-forward-ui.sh
# Consul UI: http://localhost:8500
# Vault UI: http://localhost:8200

# Limpieza al final
./cleanup.sh
```

## 🎓 Notas para Instructores

### Timing Recomendado (sesión de 3 horas)

- **Introducción + Setup** (30 min): Instalar Consul/Vault y verificar
- **Demo 1** (30 min): Service discovery básico
- **Demo 2** (30 min): Health checks
- **Break** (15 min)
- **Demo 3** (45 min): Integración completa Vault + Consul
- **Q&A y Troubleshooting** (30 min)

### Conceptos Clave a Enfatizar

1. **Consul no es un load balancer**, es un service registry
2. **Vault no es una base de datos**, es un secrets manager
3. La combinación de ambos elimina configuración estática y credenciales hardcodeadas
4. En producción, esto se combina con service mesh (Istio, Linkerd, Consul Connect)

### Troubleshooting Común

- **Pod no puede resolver DNS de Consul**: Verificar que el Consul DNS service está corriendo
- **Vault no inyecta secretos**: Verificar el Kubernetes auth method y roles
- **Servicios no aparecen en Consul**: Verificar las anotaciones de sync en los Services de K8s

## 📖 Recursos Adicionales

- [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)
- [Vault on Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Learn Consul](https://learn.hashicorp.com/consul)
- [Learn Vault](https://learn.hashicorp.com/vault)

## 🤝 Contribuciones

Si encuentras mejoras o errores en estas demos, por favor documéntalos para futuras iteraciones del curso.

---

**¡Empecemos con la Demo 1!** 🚀
