# Getting Started

## Prerequisites

- A GitHub repository with source code
- GitHub Actions enabled (default for all repos)
- For Docker: GitHub Container Registry access (automatic with `GITHUB_TOKEN`)
- For security scans: GitHub Advanced Security (free for public repos)

## Step 1 — Add the workflow

Create `.github/workflows/ci.yml` in your repository:

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

!!! tip "That's the entire file"
    No configuration needed. The pipeline auto-detects your stack.

## Step 2 — Push and watch

Commit and push. The pipeline will:

1. Run the **Detect** job to scan your repo
2. Launch **build/test** jobs for every detected language
3. Run **security scans** in parallel
4. Build **Docker images** if a Dockerfile exists
5. Aggregate and **deploy reports** to GitHub Pages

## Step 3 — Customize (optional)

Override defaults for your specific needs:

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

## Step 4 — Enable GitHub Pages

1. Go to **Settings → Pages**
2. Set **Source** to **GitHub Actions**
3. Reports will auto-deploy on pushes to your default branch

## Step 5 — Set up secrets (if needed)

| Secret | When needed |
|--------|-------------|
| `SONAR_TOKEN` | SonarQube integration |
| `CHECKMARX_TOKEN` | Checkmarx SAST |
| `KUBE_CONFIG` | Kubernetes deployments |
| `CC_TEST_REPORTER_ID` | CodeClimate quality reports |
| `CYPRESS_RECORD_KEY` | Cypress Dashboard recording |

---

## What gets auto-detected?

| File | Triggers |
|------|----------|
| `pom.xml` | Maven build, test, format, Javadoc |
| `build.gradle` / `build.gradle.kts` | Gradle build, test, Javadoc |
| `package.json` | npm/yarn/pnpm install, build, test |
| `angular.json` | Angular build, test, lint |
| `setup.py` / `pyproject.toml` | Python build, pytest, coverage |
| `*.go` files | Go build, test, lint, fmt, vet |
| `Cargo.lock` | Rust build, test, fmt, clippy, doc |
| `*.sln` / `*.csproj` | .NET build, test, format |
| `phpunit*` | PHP test with coverage |
| `Dockerfile` | Docker build, push, scan |
| `.helmignore` | Helm lint, package |
| `mkdocs.yml` | MkDocs site build |
| `*.sql` | SQLFluff lint |
| `cypress.config.*` | Cypress E2E tests |
| `playwright.config.*` | Playwright E2E tests |
| `*.hurl` | Hurl API tests |
| `tox.ini` / `tox.toml` | Python tox testing |
| `manage.py` | Django test runner |
