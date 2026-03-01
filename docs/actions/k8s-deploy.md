# K8s Deploy Action

**Path:** `actions/k8s-deploy/action.yml`

Deploys to Kubernetes via Helm with automatic rollback on failure.

## Usage

```yaml
- uses: code-haven/code-haven/actions/k8s-deploy@main
  with:
    kubeconfig: ${{ secrets.KUBE_CONFIG }}
    namespace: my-app
    chart-path: deploy/helm
    values-files: 'values.yaml,values-prod.yaml'
    image-tag: ${{ github.sha }}
    atomic: 'true'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `kubeconfig` | Yes | — | Base64-encoded kubeconfig |
| `namespace` | Yes | — | Kubernetes namespace |
| `release-name` | No | repo name | Helm release name |
| `chart-path` | No | `.` | Helm chart or OCI URL |
| `values-files` | No | `values.yaml` | Comma-separated values files |
| `image-tag` | No | — | Container image tag |
| `timeout` | No | `5m` | Helm timeout |
| `atomic` | No | `true` | Auto-rollback on failure |
| `extra-args` | No | — | Extra Helm arguments |
