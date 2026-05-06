# 🌾 Code Haven

## One line to rule them all

**Code Haven** is a zero-config, auto-detecting CI/CD pipeline system for GitHub Actions. Drop your code into a repo, add one line to your workflow file, and the pipeline figures out the rest — what language you're using, what to build, what to test, what to scan, and what to deploy.

> **Built for developers who don't want to think about DevSecOps plumbing.**

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

That's it. The pipeline will:

1. 🔍 **Detect** your languages (Java, Go, Python, Rust, C/C++, .NET, PHP, Node.js, Angular)
2. 🔨 **Build & test** everything it finds
3. 🔒 **Scan** for security issues (SAST, secrets, dependencies, containers, IaC)
4. 🐳 **Containerize** and push Docker images to GHCR
5. 📄 **Deploy** reports to GitHub Pages

---

## Supported Stacks

| Language | Build | Test | Lint/Format | Docs | Deploy |
|----------|-------|------|-------------|------|--------|
| ☕ Java (Maven) | ✅ | ✅ | ✅ revelc/spotify | ✅ Javadoc | — |
| 🐘 Java (Gradle) | ✅ | ✅ | — | ✅ Javadoc | — |
| 📦 Node.js | ✅ | ✅ | — | — | — |
| 🅰 Angular | ✅ | ✅ | ✅ ng lint | — | — |
| 🐍 Python | ✅ | ✅ pytest | ✅ tox | ✅ MkDocs | ✅ PyPI |
| 🐹 Go | ✅ | ✅ gotestsum | ✅ golangci-lint, gofmt, vet | — | — |
| 🦀 Rust | ✅ | ✅ | ✅ clippy, rustfmt | ✅ rustdoc | — |
| � C/C++ | ✅ CMake | ✅ CTest/GTest | ✅ clang-tidy, clang-format | — | ✅ Conan |
| 🔷 .NET | ✅ | ✅ | ✅ dotnet format | — | ✅ NuGet |
| 🐘 PHP | — | ✅ PHPUnit | ✅ Twig lint | — | — |
| 🐳 Docker | ✅ Buildx | — | ✅ Hadolint | — | ✅ GHCR / GCP AR |
| ⎈ Helm | ✅ lint | — | — | — | ✅ OCI push |

---

## Deployment Targets

| Target | Method | Action |
|--------|--------|--------|
| GitHub Container Registry | Docker push | Built-in |
| GCP Artifact Registry | Docker push | `cloud-login` |
| GCP Cloud Run | Serverless container | `cloud-login` |
| Kubernetes (any cloud) | Helm deploy | `k8s-deploy` |
| Bare metal / VMs | SSH + script | `ssh-deploy` |
| AWS EKS | Helm deploy | `cloud-login` + `k8s-deploy` |
| Azure AKS | Helm deploy | `cloud-login` + `k8s-deploy` |

---

## Quick Links

- [Getting Started](getting-started.md) — Set up in 5 minutes
- [Architecture](architecture.md) — How the modular system works
- [Configuration](configuration.md) — All inputs, secrets, and toggles
- [Branch Packaging](branch-packaging.md) — Control what gets packaged vs deployed
- [Cross-Project Dependencies](cross-project-deps.md) — Consume libraries across repos
- [Examples](examples.md) — Real-world pipeline configurations
- [Migration Guide](migration.md) — Coming from GitLab CI?
