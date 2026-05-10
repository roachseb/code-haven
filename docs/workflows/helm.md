# Helm / Kubernetes

**Workflow:** [`_helm.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_helm.yml)  
**Triggered by:** `.helmignore`

## Jobs

| Job | When | Description |
|-----|------|-------------|
| `helm-lint` | Always | Validates chart syntax and structure |
| `helm-package` | Default branch + tags | Packages chart and pushes to GHCR OCI registry |

## Configuration

```yaml
with:
  helm_chart_path: 'deploy/helm'
  helm_values_files: 'values.yaml,values-prod.yaml'
```

## How it works

1. **Lint** — runs `helm lint` against your chart directory, catching template
   errors, missing values, and syntax issues
2. **Package** — on default branch pushes and tag pushes, packages the chart
   as an OCI artifact and pushes to `ghcr.io/<org>/<repo>/charts/<chart-name>`

### Typical chart structure

```
deploy/helm/
├── .helmignore             ← Triggers Helm detection
├── Chart.yaml
├── values.yaml
├── values-prod.yaml        ← Optional per-environment overrides
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    └── _helpers.tpl
```

## Deployment to Kubernetes

Helm lint and package run automatically. For **actual deployment** to a
Kubernetes cluster, use the [`k8s-deploy` composite action](../actions/k8s-deploy.md):

```yaml
with:
  deploy_enabled: true
  deploy_type: 'k8s'
  helm_chart_path: 'deploy/helm'
  helm_values_files: 'values.yaml,values-prod.yaml'
  k8s_namespace: 'my-app'
```

This requires the `KUBE_CONFIG` secret with a base64-encoded kubeconfig.

!!! info "Helm vs intent-based deploy"
    **Helm + k8s-deploy** is for teams that manage their own Kubernetes manifests.
    **[Intent-based deploy](deploy.md)** is for teams that want Code Haven to
    generate and manage all infrastructure from a `deploy.yml` file.
