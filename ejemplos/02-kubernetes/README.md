# Ejemplos Kubernetes (RKE2) — Guía 02

## Orden de aplicación

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## Comandos útiles

```bash
kubectl get pods,svc,ingress
kubectl describe deployment mi-app
kubectl logs -l app=mi-app --tail=50
```

## Probar desde dentro del clúster

Crear un Pod temporal y hacer curl al Service:

```bash
kubectl run curl --rm -it --restart=Never --image=curlimages/curl -- curl http://mi-servicio.default.svc.cluster.local
```
