# Inicio Rápido - Demos Consul + Vault

Guía rápida de 5 minutos para tener todo funcionando.

## ⚡ Setup Inicial (5 minutos)

### 1. Verificar prerequisitos

```bash
# Verificar que tienes todo instalado
kubectl version --client
helm version

# Verificar que tu cluster está corriendo
kubectl get nodes
```

### 2. Instalar Consul y Vault

```bash
# Desde la raíz de 05-consul/
cd scripts/

# Instalar Consul (2-3 minutos)
./setup-consul.sh

# Instalar Vault (1-2 minutos)
./setup-vault.sh

# Verificar que todo está listo
./verify-setup.sh
```

**Salida esperada**: ✅ Todo está listo para las demos!

### 3. Exponer UIs (Opcional pero recomendado)

```bash
# En una terminal separada
./port-forward-ui.sh

# Ahora puedes acceder a:
# - Consul UI: http://localhost:8500
# - Vault UI:  http://localhost:8200 (token: root)
```

## 🎯 Ejecutar Demos

### Demo 1: Service Discovery (Más Simple)

```bash
cd ../demo-01-discovery/

# Desplegar servicios
kubectl apply -f product-service.yaml
kubectl apply -f order-service.yaml

# Esperar a que estén listos
kubectl wait --for=condition=Ready pod -l app=product-service --timeout=60s
kubectl wait --for=condition=Ready pod -l app=order-service --timeout=60s

# Port-forward para probar
kubectl port-forward svc/order-service 8081:8081

# En otra terminal, probar
curl http://localhost:8081/api/orders
```

**Resultado esperado**: JSON con órdenes que incluyen productos descubiertos vía Consul.

### Demo 2: Health Checks

```bash
cd ../demo-02-health-checks/

# Desplegar
kubectl apply -f backend-service.yaml
kubectl apply -f client-service.yaml

# Esperar
kubectl wait --for=condition=Ready pod -l app=backend-service --timeout=60s
kubectl wait --for=condition=Ready pod -l app=client-service --timeout=60s

# Port-forward
kubectl port-forward svc/client-service 8082:8082

# Probar distribución
for i in {1..5}; do curl -s http://localhost:8082/api/requests | jq '.backend.instance'; done

# Simular falla de un backend
POD=$(kubectl get pods -l app=backend-service -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- touch /tmp/unhealthy

# Esperar 15 segundos y ver que ese pod ya no recibe tráfico
sleep 15
for i in {1..5}; do curl -s http://localhost:8082/api/requests | jq '.backend.instance'; done
```

### Demo 3: Vault + Consul (Más Completa)

```bash
cd ../demo-03-vault-consul/

# Configurar Vault
./01-setup-vault.sh

# Desplegar recursos
kubectl apply -f postgres.yaml
kubectl wait --for=condition=Ready pod -l app=postgres-db --timeout=120s

kubectl apply -f user-service.yaml
kubectl wait --for=condition=Ready pod -l app=user-service --timeout=120s

kubectl apply -f api-gateway.yaml
kubectl wait --for=condition=Ready pod -l app=api-gateway --timeout=60s

# Port-forward
kubectl port-forward svc/api-gateway 8090:8090

# Probar
curl http://localhost:8090/api/users
curl http://localhost:8090/api/discovery/info | jq
```

**Resultado esperado**: Lista de usuarios y metadata de discovery mostrando que usa Consul para discovery y Vault para secretos.

### Demo 4: Dynamic Config (Más Avanzada)

```bash
cd ../demo-04-dynamic-config/

# Configurar Consul KV y Vault
./01-setup-consul-kv.sh
./02-setup-vault-secrets.sh

# Desplegar
kubectl apply -f config-service.yaml
kubectl wait --for=condition=Ready pod -l app=config-service --timeout=120s

# Port-forward
kubectl port-forward svc/config-service 8085:8085

# Ver configuración actual
curl http://localhost:8085/api/config | jq

# Port-forward a Consul (en otra terminal)
kubectl port-forward -n consul svc/consul-server 8500:8500

# Cambiar un feature flag (sin reiniciar la app)
consul kv put demo04/config/features/analytics enabled

# Ver el cambio inmediato
curl http://localhost:8085/api/config/features | jq
```

## 🧹 Limpieza

```bash
cd scripts/
./cleanup.sh
```

## 🐛 Troubleshooting Rápido

### Problema: Pods stuck en Pending

```bash
kubectl describe pod <pod-name>
# Ver eventos para identificar el problema
```

**Solución común**: Falta recursos. Aumenta recursos del cluster o reduce réplicas.

### Problema: Consul/Vault no está listo

```bash
# Ver logs
kubectl logs -n consul -l app=consul
kubectl logs -n vault -l app.kubernetes.io/name=vault

# Reintentar setup
cd scripts/
./cleanup.sh
./setup-consul.sh
./setup-vault.sh
```

### Problema: DNS no resuelve .service.consul

**Causa**: CoreDNS no está configurado para forward a Consul.

**Solución**: El script setup-consul.sh debería configurar esto automáticamente. Verificar:

```bash
kubectl get cm coredns -n kube-system -o yaml | grep consul
```

## 📚 Siguiente Paso

Lee [DEMOS-README.md](DEMOS-README.md) para entender en profundidad cada demo y conceptos avanzados.

## 🎓 Para Instructores

### Timing Sugerido (Sesión 3 horas)

```
00:00 - 00:30  Setup + Introducción
00:30 - 01:00  Demo 1 (Service Discovery)
01:00 - 01:30  Demo 2 (Health Checks)
01:30 - 01:45  Break
01:45 - 02:30  Demo 3 (Vault + Consul)
02:30 - 03:00  Q&A + Troubleshooting
```

### Checklist Pre-Sesión

- [ ] Cluster de Kubernetes funcionando
- [ ] kubectl y helm instalados
- [ ] Ejecutar `./setup-consul.sh` y `./setup-vault.sh`
- [ ] Ejecutar `./verify-setup.sh` para confirmar
- [ ] Tener las UIs abiertas (`./port-forward-ui.sh`)
- [ ] Pre-pull de imágenes (opcional, para velocidad):
  ```bash
  kubectl run test --image=postgres:15-alpine --command sleep 3600
  kubectl run test2 --image=curlimages/curl:8.1.2 --command sleep 3600
  kubectl delete pod test test2
  ```

---

**¡Todo listo para enseñar!** 🚀
