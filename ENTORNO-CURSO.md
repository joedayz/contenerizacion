# Entorno del curso — ¿Todo en local o hace falta nube?

**Respuesta corta:** **Sí, se puede instalar y ejecutar todo en local** sin contratar servicios en la nube. La nube es opcional si quieres evitar gestionar máquinas o dar acceso remoto a los alumnos.

---

## Opción 1: Todo en local (recomendada para el curso)

### Qué hace falta

- **Un PC o portátil** (o uno por alumno) con:
  - **RAM:** mínimo 8 GB; recomendable **16 GB** si corres varias VMs (RKE2 + Rancher + Vault + Consul).
  - **CPU:** 4 núcleos o más recomendable.
  - **Disco:** 50–100 GB libres.
- **Software de virtualización** (elegir uno):
  - **Multipass** (Ubuntu en VMs ligeras, muy cómodo en macOS/Linux/Windows).
  - **VirtualBox** o **VMware** (varias VMs con Linux).
  - **Docker Desktop** solo para el módulo Docker; para RKE2 harán falta VMs o un único nodo.

### Cómo queda el stack en local

| Componente | Dónde corre | Notas |
|------------|-------------|--------|
| **Docker** | En el propio portátil/PC | Instalación estándar (Docker Engine o Docker Desktop). |
| **RKE2** | En una VM (o 2–3 VMs para HA) con Linux | Instalación oficial RKE2 (script `rke2-install.sh`). Puedes usar **un solo nodo** para el curso. |
| **Rancher** | Dentro del clúster RKE2 (como workload) o en otra VM | Helm en el clúster: `helm install rancher ...`. Rancher gestiona el mismo clúster donde se instala. |
| **HashiCorp Vault** | Dentro del clúster (Deployment) o en una VM | En K8s: Helm chart oficial. Modo dev para prácticas; en “producción” se usa modo servidor. |
| **HashiCorp Consul** | Dentro del clúster (Helm) | Chart oficial de Consul para Kubernetes. |

No hace falta AWS, GCP, Azure ni ningún servicio de nube de pago. Todo puede estar en tu red local (localhost o IPs de las VMs).

### Esquema mínimo (un solo servidor)

```
[Tu PC]
  ├── Docker (Módulo 1)
  └── 1 VM con Linux (Ubuntu 22.04, etc.)
        └── RKE2 (single-node cluster)
              ├── Rancher (Helm)
              ├── Vault (Helm, dev o server)
              └── Consul (Helm)
```

Los alumnos usan `kubectl` y el navegador contra la IP de esa VM (o contra `localhost` si todo está en su portátil).

### Recursos si hay poco RAM

- **RKE2 single-node** con 1 nodo: ~4 GB RAM para el clúster.
- **Rancher:** ~1–2 GB.
- **Vault y Consul:** ~512 MB–1 GB cada uno si se limitan recursos en los manifests.
- Con **8 GB** se puede hacer un entorno “todo en uno” reducido; con **16 GB** va sobrado.

---

## Opción 2: Híbrido (profesor en local, alumnos en nube)

- El **profesor** monta un clúster RKE2 en su máquina (o en un servidor local).
- **Rancher** expuesto por tunnel (ngrok, tailscale) o por IP pública si el centro tiene una.
- Los **alumnos** no instalan RKE2; solo Docker en su PC y acceso a Rancher (navegador + kubeconfig descargado desde Rancher).
- Sigue sin ser necesario pagar por AWS/GCP/Azure si usas un servidor propio o del centro.

---

## Opción 3: Nube (opcional)

Si prefieres no mantener VMs:

- **RKE2** se puede instalar en VMs de AWS, GCP, Azure o de cualquier proveedor (misma instalación que en local).
- **Rancher** también puede gestionar clústeres en la nube (EKS, GKE, AKS) además de RKE2.
- Vault y Consul se despliegan dentro del clúster (igual que en local).

La nube no es obligatoria; es una cuestión de quién administra las máquinas y si quieres acceso remoto sin configurar tú el túnel.

---

## Resumen para tus alumnos

Puedes decirles:

- **Módulo 1 (Docker):** solo necesitan Docker instalado en su equipo (Windows, Mac o Linux).
- **Módulos 2–6:** pueden usar un clúster **compartido** (el que tú montes en local o en un servidor) al que se conectan con Rancher y/o `kubectl`, **o** montar cada uno su propio RKE2 en local si tienen RAM suficiente (por ejemplo 16 GB).

No es necesario tener cuenta en AWS, Google Cloud ni Azure para seguir el curso; **todo puede hacerse en local**.
