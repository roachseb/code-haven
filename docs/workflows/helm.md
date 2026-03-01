# Helm / Kubernetes

**Workflow:** [`_helm.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_helm.yml)  
**Triggered by:** `.helmignore`

## Jobs

| Job | Description |
|-----|-------------|
| `helm-lint` | Validates chart syntax |
| `helm-package` | Packages and pushes to GHCR OCI registry (default branch + tags) |

## Configuration

```yaml
with:
  helm_chart_path: 'deploy/helm'
  helm_values_files: 'values.yaml,values-prod.yaml'
```

## Deployment

For actual Kubernetes deployment, use the [k8s-deploy composite action](../actions/k8s-deploy.md).
