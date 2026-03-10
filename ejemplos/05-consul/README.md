# Ejemplos HashiCorp Consul — Guía 05

Consul se despliega en el clúster (Helm o manifests oficiales). Aquí se incluyen ejemplos de **definición de servicio** y **health check** para entender las relaciones entre servicios.

## Registro de servicios

En Consul, los servicios se pueden registrar por:

- **Archivo de configuración** en los nodos del agente.
- **API HTTP** desde la aplicación o un sidecar.
- **Kubernetes**: Consul tiene un *sync catalog* que puede registrar Services de K8s en Consul.

El archivo `service-definition.json` es un ejemplo de definición en formato JSON que usaría un agente Consul (por ejemplo en un sidecar o en un nodo que corre el servicio).

## Health check

El health check en la definición comprueba que HTTP en el puerto del servicio devuelva 200. Consul marca el servicio como *passing* o *failing* y solo devuelve instancias *passing* en las consultas DNS o API.

## Práctica

1. Desplegar Consul en el clúster (ver [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)).
2. Desplegar dos aplicaciones con health checks (por ejemplo dos Deployments con `livenessProbe`).
3. Registrarlas en Consul (vía sync con K8s o definición manual).
4. Desde un Pod de prueba: `nslookup mi-servicio.service.consul` o llamar a la API de Consul para listar instancias.
