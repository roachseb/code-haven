# Branch-Based Packaging & Deployment

## Overview

Code Haven supports intelligent branch-based decisions about what gets packaged and what gets deployed. This ensures feature branches produce testable artifacts without accidentally deploying unfinished work.

## Branch Strategy

```
Branch Type          │ Build │ Test │ Scan │ Package │ Deploy │ Registry Tag
─────────────────────┼───────┼──────┼──────┼─────────┼────────┼──────────────
fix/* hotfix/*       │  ✅   │  ✅  │  ✅  │   ❌    │   ❌   │ —
chore/* docs/*       │  ✅   │  ✅  │  ❌  │   ❌    │   ❌   │ —
feature/*            │  ✅   │  ✅  │  ✅  │   ✅    │   ❌   │ :feature-name
develop              │  ✅   │  ✅  │  ✅  │   ✅    │ opt-in │ :develop
release/*            │  ✅   │  ✅  │  ✅  │   ✅    │ opt-in │ :rc-X.Y.Z
main                 │  ✅   │  ✅  │  ✅  │   ✅    │  ✅    │ :latest
tags (v*)            │  ✅   │  ✅  │  ✅  │   ✅    │  ✅    │ :X.Y.Z
```

## Configuration

```yaml
with:
  # ── Packaging Strategy ────────────────────────────────────
  package_on_feature: true               # Package feature branches
  package_branches: 'feature/**,develop,release/**,main'
  deploy_enabled: false                  # Master switch for deployment
  deploy_branches: 'main,release/**'     # Which branches trigger deploy
  deploy_type: 'k8s'                     # k8s, cloud-run, ssh, none
```

### Inputs Reference

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `package_on_feature` | boolean | `false` | Enable packaging on feature branches |
| `package_branches` | string | `main` | Glob patterns for branches that produce packages |
| `deploy_enabled` | boolean | `false` | Master switch — must be `true` for any deployment |
| `deploy_branches` | string | `main` | Branches that trigger deployment (when `deploy_enabled`) |
| `deploy_type` | string | `none` | Deployment method: `k8s`, `cloud-run`, `ssh`, `none` |

## How It Works

### Decision Flow

```
Push event received
      │
      ▼
┌─────────────────┐
│ Always: Build,  │
│ Test, Scan      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Does branch match       │
│ package_branches?       │──── No ──► Stop (build/test only)
└────────┬────────────────┘
         │ Yes
         ▼
┌─────────────────────────┐
│ Package artifact:       │
│ • Docker image tag      │
│ • Conan package         │
│ • npm/Maven/PyPI        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Is deploy_enabled?      │──── No ──► Stop (packaged, not deployed)
└────────┬────────────────┘
         │ Yes
         ▼
┌─────────────────────────┐
│ Does branch match       │
│ deploy_branches?        │──── No ──► Stop (packaged, not deployed)
└────────┬────────────────┘
         │ Yes
         ▼
┌─────────────────────────┐
│ Execute deploy_type:    │
│ • k8s (Helm)            │
│ • cloud-run             │
│ • ssh                   │
└─────────────────────────┘
```

### Tag Generation per Branch

| Branch | Docker Tag | Conan Channel | npm Tag |
|--------|-----------|---------------|---------|
| `feature/payment-api` | `:feature-payment-api` | `@feature/latest` | `feature` |
| `develop` | `:develop` | `@develop/latest` | `next` |
| `release/1.2.0` | `:rc-1.2.0` | `@rc/latest` | `rc` |
| `main` | `:latest` + `:sha-abc123` | `@_/_` (stable) | `latest` |
| `v1.2.0` (tag) | `:1.2.0` + `:1.2` + `:1` | Version pinned | `latest` |

## Examples

### Feature branch — package only, no deploy

```yaml
# Developer pushes feature/payment-api
# Pipeline does:
#   1. Build ✅
#   2. Test ✅
#   3. Security scan ✅
#   4. Package → ghcr.io/org/my-app:feature-payment-api ✅
#   5. Deploy ❌ (not in deploy_branches)
#
# The image is available for manual testing or integration tests
# but nothing is deployed to any environment.
```

### Main branch — full pipeline

```yaml
# Push to main (via merge)
# Pipeline does:
#   1. Build ✅
#   2. Test ✅
#   3. Security scan ✅
#   4. Package → ghcr.io/org/my-app:latest + :sha-abc123 ✅
#   5. Deploy → production (k8s/cloud-run/ssh) ✅
```

### Develop — package + optional staging deploy

```yaml
with:
  package_on_feature: true
  deploy_enabled: true
  deploy_branches: 'main,develop'  # Deploy develop to staging
  deploy_type: 'k8s'

# Push to develop triggers deploy
# But uses a separate environment (staging vs production)
# Configured via GitHub Environments
```

## Why Package Feature Branches?

1. **Integration testing**: Other services can pull `my-lib:feature-payment-api` to test compatibility
2. **QA environments**: Spin up preview environments with the feature build
3. **Dependency chains**: When Repo B depends on Repo A, Repo B can test against Repo A's feature branch package
4. **No surprises at merge**: If it packages and tests fine on feature, it'll work on main

## Deploy Types

### `k8s` — Kubernetes (Helm)

Uses the `k8s-deploy` composite action. Requires:
- `KUBE_CONFIG` secret (base64-encoded kubeconfig)
- Helm chart in `deploy/helm/`
- Namespace configuration

### `cloud-run` — GCP Cloud Run

Serverless container deployment. Requires:
- GCP authentication (Workload Identity Federation)
- Docker image in GCP Artifact Registry or GHCR

### `ssh` — Bare metal / VM

Uses the `ssh-deploy` composite action. Requires:
- `DEPLOY_HOST`, `DEPLOY_SSH_KEY` secrets
- `deploy/deploy.sh` script in repo

### `none` — No deployment

Package only. Useful for libraries that are consumed by other projects.
