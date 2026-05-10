# Code Haven

## One line to rule them all

**Code Haven** is a zero-config, auto-detecting CI/CD pipeline system for GitHub Actions.
Drop your code into a repo, add one workflow file, and the pipeline figures out the rest —
what languages you use, what to build, what to test, what to scan, and where to deploy.

> **Built for developers who ship code, not plumb pipelines.**

---

## How it works

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    secrets: inherit
```

That's the entire file. The pipeline will:

1. **Detect** your languages (Java, Go, Python, Rust, C/C++, .NET, PHP, Node.js, Angular)
2. **Build & test** everything it finds — in parallel
3. **Scan** for security issues (SAST, secrets, dependencies, containers, IaC)
4. **Containerize** and push Docker images to GHCR
5. **Deploy** reports to GitHub Pages

---

## Supported Stacks

| Language | Build | Test | Lint / Format | Docs | Publish |
|----------|-------|------|---------------|------|---------|
| Java (Maven) | ✅ | ✅ | ✅ revelc / spotify | ✅ Javadoc | ✅ Maven Central |
| Java (Gradle) | ✅ | ✅ | — | ✅ Javadoc | — |
| Node.js | ✅ | ✅ | — | — | ✅ npm |
| Angular | ✅ | ✅ | ✅ ng lint | — | — |
| Python | ✅ | ✅ pytest | ✅ tox | ✅ MkDocs | ✅ PyPI |
| Go | ✅ | ✅ gotestsum | ✅ golangci-lint, gofmt | — | — |
| Rust | ✅ | ✅ | ✅ clippy, rustfmt | ✅ rustdoc | ✅ crates.io |
| C / C++ | ✅ CMake | ✅ CTest / GTest | ✅ clang-tidy, clang-format | — | ✅ Conan |
| .NET | ✅ | ✅ | ✅ dotnet format | — | ✅ NuGet |
| PHP | — | ✅ PHPUnit | ✅ Twig lint | — | — |
| Docker | ✅ Buildx | — | ✅ Hadolint | — | ✅ GHCR / GCP AR |
| Helm | ✅ lint | — | — | — | ✅ OCI push |

---

## Deployment Targets

Code Haven supports two deployment approaches:

### Traditional (via `with:` inputs)

| Target | Method | Action |
|--------|--------|--------|
| GitHub Container Registry | Docker push | Built-in |
| GCP Artifact Registry | Docker push | `cloud-login` |
| Kubernetes (any cloud) | Helm deploy | `k8s-deploy` |
| Bare metal / VMs | SSH + script | `ssh-deploy` |

### Intent-Based (via `deploy.yml`)

Declare infrastructure in a simple YAML file and Code Haven generates Terraform:

| Target | Cloud | Runtime |
|--------|-------|---------|
| GCP Cloud Run | GCP | `cloud-run` |
| GCP GKE (Kubernetes) | GCP | `gke` |
| GCP Compute Engine | GCP | `compute` |
| GCP Cloud Run Jobs | GCP | `worker` / `cronjob` |
| AWS ECS Fargate | AWS | `ecs` |
| Azure Container Apps | Azure | `container-apps` |

See the [Deploy workflow](workflows/deploy.md) for the full intent-based reference.

---

## Quick Links

- [Getting Started](getting-started.md) — Set up in 5 minutes
- [Architecture](architecture.md) — How the modular system works
- [Configuration](configuration.md) — All inputs, secrets, and toggles
- [Deploy (Intent-Based)](workflows/deploy.md) — Declare infrastructure in YAML
- [Examples](examples.md) — Real-world pipeline configurations
- [Testing Guide](testing.md) — How to verify Code Haven itself
- [Branch Packaging](branch-packaging.md) — Control what gets packaged vs deployed
- [Cross-Project Dependencies](cross-project-deps.md) — Consume libraries across repos
- [Migration Guide](migration.md) — Coming from GitLab CI?
