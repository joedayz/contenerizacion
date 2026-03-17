# Ejemplos Secrets y ConfigMaps — Guía 06

## Orden de aplicación

```bash
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml
```

## Comprobar

```bash
kubectl get configmap app-config -o yaml
kubectl get secret db-credentials -o yaml   # valores en base64
kubectl logs -l app=app-con-config
```

En los logs deberían aparecer `LOG_LEVEL`, `API_URL` y el usuario de DB (no la contraseña en producción). El archivo `/etc/app/config.json` contendrá el JSON del ConfigMap.

```bash
echo 'Y2hhbmdlbWUtaW4tcHJvZHVjdGlvbg==' | base64 -d   
echo 'YXBwdXNlcg==' | base64 -d 
```


```Powershell
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Y2hhbmdlbWUtaW4tcHJvZHVjdGlvbg=='))
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('YXBwdXNlcg=='))
```
