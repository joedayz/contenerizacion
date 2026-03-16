# AGENTS.md

## Purpose and scope
- This repository is course material (39h) organized by module, not a single deployable app: `guías/` (theory) + `ejemplos/` (hands-on manifests/scripts).
- Follow module order `01 -> 06` from `README.md`; each module is intentionally self-contained.

## Big picture architecture
- Core stack taught here: `RKE2` (orchestrator) + `Rancher` (cluster ops) + `Vault` (secrets) + `Consul` (service discovery).
- Kubernetes examples are scenario-based (`ejemplos/02-kubernetes/{guestbook,frontend-backend,ingress-demo,voting-app}`), not one shared platform.
- The most complete service flow is in `ejemplos/02a-kubernetes-local-azure/`:
  - `expense-service` (backend) + `expense-client` (consumer/frontend)
  - in-cluster communication via ConfigMap key `EXPENSE_SVC=http://expense-service:8080`
  - same app, different targets: `docker-desktop/`, `podman/`, `azure/`.

## Critical workflows (use target-specific scripts)
- Docker intro demo: `ejemplos/01-docker/README.md` (`docker build`, `docker run`, `curl :3000`).
- Kubernetes local (Docker Desktop): run in `ejemplos/02a-kubernetes-local-azure/docker-desktop/`
  - `scripts/cluster-up.sh`
  - `scripts/build-and-load-all.sh`
  - `scripts/deploy-all.sh`
- Kubernetes local (Podman/Kind): run in `ejemplos/02a-kubernetes-local-azure/podman/`
  - `scripts/kind-up.sh`
  - `scripts/build-and-load-all.sh`
  - `scripts/deploy-all-kind.sh`
- AKS path: run in `ejemplos/02a-kubernetes-local-azure/azure/`
  - `./scripts/azure-setup.sh`, `./scripts/build-and-push-all.sh`, `./scripts/deploy-all.sh`
  - diagnostics live in `scripts/diagnose.sh`, `scripts/cluster-info.sh`, `scripts/test-probes.sh`.

## Project-specific conventions to preserve
- Keep manifests environment-specific; image refs differ by target:
  - Azure: `${ACR_NAME}.azurecr.io/...` (`azure/k8s/expenses-all.yaml`)
  - Docker Desktop: `expense-service:latest` (`docker-desktop/k8s/expenses-all.yaml`)
  - Podman: `localhost/expense-service:latest` (`podman/k8s/expenses-all.yaml`).
- Security posture in `02a` manifests is deliberate: `runAsNonRoot`, `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`.
- Health probes (Quarkus endpoints) are part of AKS reliability setup: `/q/health/live` and `/q/health/ready`.
- Vault integration uses injector annotations (do not replace with plain env secrets) in `ejemplos/04-vault/deployment-with-vault-annotations.yaml`.

## Integration points and gotchas
- `expense-client` depends on DNS name `expense-service` and ConfigMap wiring; if client returns empty data, inspect `EXPENSE_SVC` and service endpoints first.
- Several README snippets reference generic files (e.g., `demo-kafka-microservices.yaml`) that may not exist in that folder; validate against actual directory contents before applying.
- `spring-kafka-microservices/` is an imported standalone demo (Kafka/Saga) with its own Maven lifecycle; treat it independently from course module scripts.

## How to contribute changes as an AI agent
- Prefer minimal, surgical edits inside the relevant module; avoid cross-module refactors.
- When adding commands/docs, provide Linux/macOS and PowerShell variants if sibling docs already do.
- Reference concrete file paths in explanations so instructors/students can map changes to the session material quickly.

