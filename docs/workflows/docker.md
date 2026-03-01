# Docker

**Workflow:** [`_docker.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_docker.yml)  
**Triggered by:** `Dockerfile`

## Jobs

| Job | Description |
|-----|-------------|
| `docker-build` | Buildx multi-platform build, push to GHCR with smart tags |
| `hadolint` | Dockerfile best-practice linting → SARIF (soft-fail) |
| `container-scan` | Trivy vulnerability scan of built image → SARIF |

## Smart Tagging

The Docker build automatically generates these tags:

| Tag | When |
|-----|------|
| `sha-<commit>` | Always |
| `<branch>` | Branch push |
| `pr-<number>` | Pull request |
| `<version>` | Semantic version tag |
| `<major>.<minor>` | Semantic version tag |
| `latest` | Default branch push |

## Configuration

```yaml
with:
  dockerfile_path: 'Dockerfile'
  docker_context: '.'
  docker_tag_extra: 'latest'
  docker_registry: 'ghcr.io'
```
