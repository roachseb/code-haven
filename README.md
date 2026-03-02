# 🌾 Code Haven — CI/CD Pipeline Templates

> **One line to rule them all.** A zero-config, auto-detecting CI/CD pipeline system for GitHub Actions.
> Drop your code, add one workflow line, and the pipeline figures out the rest.

[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://roachseb.github.io/code-haven/)

---

## ⚡ Quick Start

Add this to your repo at `.github/workflows/ci.yml`:

```yaml
name: CI/CD
on:
  push:
    branches: [main, develop, 'feat/**']
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: code-haven/.github/workflows/devsecops.yml@main
    secrets: inherit
```

**That's it.** The pipeline will:
1. 🔍 **Detect** your languages (Java, Go, Python, Rust, .NET, PHP, Node.js, Angular)
2. 🔨 **Build & test** everything it finds
3. 🔒 **Scan** for security issues (SAST, secrets, dependencies, containers, IaC)
4. 🐳 **Containerize** and push Docker images to GHCR
5. 📄 **Deploy** reports to GitHub Pages

---

## 🏗️ Architecture

The pipeline is **modular by design**. One slim orchestrator delegates to domain-specific workflows:

```
Consumer Repo
  │
  │  uses: devsecops.yml@main
  ▼
┌─────────────────────────────────────────────────────────┐
│  devsecops.yml  (Orchestrator)                          │
│                                                         │
│  detect ─┬─► _build-java.yml      ☕ Maven + Gradle    │
│          ├─► _build-node.yml      📦 npm + Angular     │
│          ├─► _build-python.yml    🐍 Python + Django   │
│          ├─► _build-go.yml        🐹 Go                │
│          ├─► _build-rust.yml      🦀 Rust              │
│          ├─► _build-dotnet.yml    🔷 .NET              │
│          ├─► _build-php.yml       🐘 PHP               │
│          ├─► _docker.yml          🐳 Docker            │
│          ├─► _test-e2e.yml        🧪 Cypress/PW/Hurl  │
│          ├─► _security.yml        🛡 Security scans    │
│          ├─► _quality.yml         ✨ Quality & metrics │
│          ├─► _helm.yml            ⎈ Helm / K8s        │
│          └─► _pages.yml           📄 GitHub Pages      │
└─────────────────────────────────────────────────────────┘
```

Each sub-workflow is **50–130 lines**, focused on **one domain**. No more 1,400-line monoliths.

---

## 📋 Supported Languages & Tools

| Category | Jobs | Trigger |
|----------|------|---------|
| **☕ Java (Maven)** | Build, Format, Javadoc | `pom.xml` |
| **🐘 Java (Gradle)** | Build, Javadoc | `build.gradle(.kts)` |
| **📦 Node.js** | Install, Build, Test | `package.json` |
| **🅰 Angular** | Build, Test, Lint | `angular.json` |
| **🐍 Python** | Build, Test, Tox, Django, MkDocs, PyPI | `setup.py` / `pyproject.toml` |
| **🐹 Go** | Build, Test, Lint, Fmt, Vet | `*.go` files |
| **🦀 Rust** | Build, Test, Fmt, Clippy, Doc | `Cargo.lock` |
| **🔷 .NET** | Build, Test, Format, NuGet | `*.sln` / `*.csproj` |
| **🐘 PHP** | Test, Twig Lint | `phpunit*` |
| **🐳 Docker** | Build/Push, Hadolint, Trivy scan | `Dockerfile` |
| **🧪 E2E** | Cypress, Playwright, Hurl | Config files |
| **🛡 Security** | CodeQL, Gitleaks, Trivy, KICS, Sonar, Checkmarx | Always |
| **✨ Quality** | CodeClimate, SCC, Link check | Always |
| **⎈ Helm** | Lint, Package/Push | `.helmignore` |
| **📄 Pages** | Aggregate reports → deploy | Default branch |

---

## 📁 Project Structure

```
.github/workflows/
├── devsecops.yml          # 🎯 Entry point — the orchestrator (~300 lines)
├── _build-java.yml        # ☕ Maven + Gradle builds
├── _build-node.yml        # 📦 npm / Angular builds
├── _build-python.yml      # 🐍 Python / Django / MkDocs
├── _build-go.yml          # 🐹 Go build / test / lint
├── _build-rust.yml        # 🦀 Rust build / test / clippy
├── _build-dotnet.yml      # 🔷 .NET build / test / publish
├── _build-php.yml         # 🐘 PHP test / Twig lint
├── _docker.yml            # 🐳 Docker build + security scan
├── _test-e2e.yml          # 🧪 Cypress + Playwright + Hurl
├── _security.yml          # 🛡 SAST + secrets + deps + IaC
├── _quality.yml           # ✨ Quality + metrics + links
├── _helm.yml              # ⎈ Helm lint + package
├── _pages.yml             # 📄 Report aggregation + deploy
├── _release.yml           # 🚀 Tag → Release + packaging + registry
└── ci.yml                 # 🐕 Dog-fooding — this repo uses its own pipeline!

actions/
├── toolkit/               # 🔧 Environment init (CA certs, debug)
├── cloud-login/           # ☁️ AWS / Azure / GCP authentication
├── k8s-deploy/            # 🚀 Helm deployment with rollback
└── code-quality/          # ✨ CodeClimate config generator

docs/                      # 📖 Full documentation site (MkDocs Material)
examples/                  # 📝 Ready-to-use workflow examples
```

---

## ⚙️ Configuration

Override defaults when calling the workflow:

```yaml
jobs:
  ci:
    uses: code-haven/.github/workflows/devsecops.yml@main
    with:
      java_version: '17'
      python_version: '3.12'
      sonar_host_url: 'https://sonarqube.example.com'
      # Disable what you don't need
      rust_disabled: true
      php_disabled: true
    secrets: inherit
```

### Toggles

All stacks can be disabled with `<stack>_disabled: true`:

`maven_disabled` · `gradle_disabled` · `npm_disabled` · `angular_disabled` · `python_disabled` · `golang_disabled` · `rust_disabled` · `dotnet_disabled` · `php_disabled` · `docker_disabled` · `helm_disabled` · `cypress_disabled` · `playwright_disabled` · `hurl_disabled` · `pages_disabled`

### Security Toggles

`sast_disabled` · `secret_detection_disabled` · `dependency_scan_disabled` · `container_scan_disabled` · `iac_scan_disabled` · `sonar_disabled` · `checkmarx_disabled` · `sqlfluff_disabled` · `links_check_disabled` · `code_quality_disabled` · `code_metrics_disabled` · `hadolint_disabled`

### Secrets

| Secret | Used by |
|--------|---------|
| `SONAR_TOKEN` | SonarQube |
| `CHECKMARX_TOKEN` | Checkmarx |
| `KUBE_CONFIG` | K8s deploy |
| `CC_TEST_REPORTER_ID` | CodeClimate |
| `CYPRESS_RECORD_KEY` | Cypress Dashboard |

→ Full reference: [Configuration docs](docs/configuration.md)

---

## 🧩 Composite Actions

| Action | Purpose |
|--------|---------|
| [`actions/toolkit`](actions/toolkit) | Environment init — CA certs, debug, post-init scripts |
| [`actions/cloud-login`](actions/cloud-login) | AWS / Azure / GCP OIDC authentication |
| [`actions/k8s-deploy`](actions/k8s-deploy) | Helm deployment with auto-rollback |
| [`actions/code-quality`](actions/code-quality) | Auto-generates `.codeclimate.yml` |

---

## 📖 Documentation

Full docs are available at the [documentation site](https://code-haven.github.io/code-haven) (powered by MkDocs Material), or browse the [`docs/`](docs/) folder directly.

### External review

A structured improvement review is available at [`docs/review-2026-03.md`](docs/review-2026-03.md).

---

## 🔄 Pipeline Lifecycle

The pipeline behaves differently depending on **how** it was triggered:

| Trigger | What Happens |
|---------|--------------|
| **Pull Request** | Build → Test → Security scan → Quality metrics. No deploy, no publish. |
| **Push to default branch** | Everything above **+** GitHub Pages deploy (docs, reports, coverage). |
| **Tag push (`v*`)** | Everything above **+** GitHub Release + package publishing + container versioning. |

```
PR ──────────► build + test + scan

main push ──► build + test + scan + deploy docs to Pages

tag (v1.2.3) ► build + test + scan + deploy docs
               + create GitHub Release
               + push Docker image as v1.2.3
               + publish packages (Maven/npm/PyPI/NuGet/crates/Go)
```

To create a release, just push a tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 🐕 Dog-Fooding

Code Haven **uses its own pipeline** to build, scan, and deploy itself.
The [`ci.yml`](.github/workflows/ci.yml) in this repo calls `devsecops.yml` —
the exact same entry point every consumer uses:

```yaml
# .github/workflows/ci.yml (simplified)
jobs:
  yaml-lint: ...            # Template-specific: validate YAML syntax
  actionlint: ...           # Template-specific: validate action syntax

  pipeline:
    needs: [yaml-lint, actionlint]
    uses: ./.github/workflows/devsecops.yml   # 🐕 Eating our own dog food
    secrets: inherit
```

The orchestrator detects `mkdocs.yml`, builds the documentation, runs security
scans, and deploys to GitHub Pages — all through the same system your repos use.

---

## 🔀 Coming from GitLab?

This project is the GitHub Actions equivalent of the Code Haven Farm GitLab CI templates. See the [Migration Guide](docs/migration.md) and [MIGRATION-REPORT.md](MIGRATION-REPORT.md) for the full mapping.

---

## 🚦 Getting Started Checklist

1. [ ] Add the one-line workflow to your repo
2. [ ] Enable GitHub Pages (Settings → Pages → GitHub Actions)
3. [ ] Set up secrets for SonarQube, Checkmarx, etc. (if needed)
4. [ ] Configure branch protection rules
5. [ ] Push and watch the magic ✨
