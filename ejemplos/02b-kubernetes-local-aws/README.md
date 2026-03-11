## Demo 02b: Kubernetes local + AWS (EKS/ECR)

Este directorio es el “mellizo” de `02a-kubernetes-local-azure`, pero pensando en **AWS**:

- `docker-desktop/` y `podman/`: mismos ejemplos locales (kind / Docker Desktop) para probar Kubernetes en tu máquina.
- `aws/`: aquí va la parte de nube usando **EKS + ECR**, equivalente a lo que en `02a` haces con **AKS + ACR**.

### 1. Local (igual que en 02a)

Puedes usar exactamente los mismos comandos que en `02a-kubernetes-local-azure`:

- Para Docker Desktop: entra a `docker-desktop/` y usa:

```bash
scripts/cluster-up.sh
scripts/build-and-load-all.sh
scripts/deploy-all.sh
```

- Para Kind + Podman: entra a `podman/` y usa:

```bash
scripts/kind-up.sh
scripts/build-and-load-all.sh
scripts/deploy-all-kind.sh
```

La diferencia principal de este directorio está en la carpeta `aws/`.

### 2. Nube en AWS (EKS + ECR) – carpeta `aws/`

Dentro de `aws/` crearemos:

- Manifiestos Kubernetes equivalentes a `azure/k8s/expenses-all.yaml` pero apuntando a imágenes en **ECR**.
- Scripts tipo:
  - `aws-setup.sh`: crea ECR + EKS (similar a `azure-setup.sh`).
  - `build-and-push-all-aws.sh`: construye y sube imágenes a ECR (similar a `build-and-push-all.sh`).
  - `deploy-all-aws.sh`: aplica los manifiestos en EKS (similar a `deploy-all.sh`).

Los comandos base que usarán esos scripts serán muy parecidos a:

```bash
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Crear repositorios ECR
aws ecr create-repository --repository-name expense-service --region $AWS_REGION
aws ecr create-repository --repository-name expense-client --region $AWS_REGION

# Crear cluster EKS (con eksctl)
eksctl create cluster \
  --name expense-eks \
  --region $AWS_REGION \
  --nodes 2 \
  --node-type t3.small

# Login a ECR (Docker)
aws ecr get-login-password --region $AWS_REGION \
  | docker login \
    --username AWS \
    --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

La idea es que tengas:

- `02a-kubernetes-local-azure`: local + Azure (AKS/ACR).
- `02b-kubernetes-local-aws`: local + AWS (EKS/ECR).

Cuando quieras, puedo rellenar también los scripts en `aws/` para que sean un **clon 1:1 de los de Azure pero usando AWS CLI / eksctl / ECR**.

