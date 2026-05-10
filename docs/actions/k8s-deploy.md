# K8s Deploy Action

**Path:** `actions/k8s-deploy/action.yml`

Deploys to Kubernetes via Helm with automatic rollback on failure. Designed for
teams that manage their own Helm charts and want safe, atomic deployments.

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
| `kubeconfig` | Yes | — | Base64-encoded kubeconfig file |
| `namespace` | Yes | — | Kubernetes namespace to deploy into |
| `release-name` | No | repo name | Helm release name |
| `chart-path` | No | `.` | Path to local Helm chart or OCI chart URL |
| `values-files` | No | `values.yaml` | Comma-separated Helm values files |
| `image-tag` | No | — | Container image tag to inject via `--set image.tag=` |
| `timeout` | No | `5m` | Helm upgrade timeout |
| `atomic` | No | `true` | Automatically rollback on failure |
| `extra-args` | No | — | Extra `helm upgrade` arguments |

## How it works

1. Decodes the `kubeconfig` secret and writes it to `~/.kube/config`
2. Runs `helm upgrade --install` with the specified chart and values
3. If `atomic: true` (default), Helm rolls back automatically if any deployment fails
4. Reports the release status and deployed revision

## Example: full workflow integration

```yaml title=".github/workflows/ci.yml"
jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      deploy_enabled: true
      deploy_type: 'k8s'
      helm_chart_path: 'deploy/helm'
      helm_values_files: 'values.yaml'
      k8s_namespace: 'my-app'
    secrets: inherit
```

## Kubeconfig setup

The `KUBE_CONFIG` secret should contain a base64-encoded kubeconfig:

```bash
# Generate the secret value
cat ~/.kube/config | base64 -w 0
```

Store the output as a repository secret named `KUBE_CONFIG`.

!!! warning "Least privilege"
    Use a service account with minimal permissions — only the namespaces and
    resources your deployment needs. Avoid cluster-admin for CI.

## Using OCI chart references

Instead of a local chart path, you can deploy from an OCI registry
(e.g., a chart packaged by Code Haven's Helm workflow):

```yaml
- uses: code-haven/code-haven/actions/k8s-deploy@main
  with:
    kubeconfig: ${{ secrets.KUBE_CONFIG }}
    namespace: my-app
    chart-path: 'oci://ghcr.io/my-org/my-repo/charts/my-chart'
    image-tag: ${{ github.sha }}
```
