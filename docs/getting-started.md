# Getting Started

Get a full CI/CD pipeline running in under 5 minutes — no configuration needed.

## Prerequisites

- A GitHub repository with source code
- GitHub Actions enabled (default on all repos)

That's it. Docker, security scanning, and everything else is handled automatically.

---

## Step 1 — Add the workflow file

Create `.github/workflows/ci.yml` in your repository:

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'feat/**']
  pull_request:
    branches: [main]

permissions:
  contents: write          # Checkout, releases, and tagging
  checks: write            # Test result annotations on PRs
  pull-requests: write     # PR status comments
  packages: write          # Docker push to GHCR
  pages: write             # GitHub Pages deployment
  id-token: write          # OIDC tokens (Pages, cloud logins)
  security-events: write   # SARIF uploads (CodeQL, Trivy, KICS)
  actions: read            # Pages deployment token

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    secrets: inherit
```

!!! tip "That's the entire file"
    No `with:` block needed. Code Haven auto-detects your languages, tools,
    and frameworks. You only add configuration when you want to override defaults.

---

## Step 2 — Push and watch

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add Code Haven pipeline"
git push
```

Open your repository's **Actions** tab. You'll see:

1. **Detect** — scans your repo for languages and tools
2. **Build/Test** — one job per detected language, running in parallel
3. **Security** — SAST, secret detection, dependency scanning, container scanning
4. **Quality** — code metrics and link checks
5. **Pages** — aggregates all reports into a single dashboard (if enabled)

!!! note "First run takes longer"
    GitHub Actions caches dependencies after the first run. Subsequent
    runs are significantly faster.

---

## Step 3 — Customize (optional)

Only configure what you need to change. Everything has sensible defaults.

=== "Override language versions"

    ```yaml
    jobs:
      ci:
        uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
        with:
          java_version: '17'
          python_version: '3.12'
          node_version: '20'
        secrets: inherit
    ```

=== "Force-disable a detected stack"

    ```yaml
    jobs:
      ci:
        uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
        with:
          npm_disabled: true   # I have package.json but don't want Node CI
        secrets: inherit
    ```

    !!! note "You rarely need disable flags"
        Code Haven auto-detects your stack — if your project doesn't have
        `pom.xml`, Java won't run. Disable flags are only needed to override
        a *detected* stack (e.g., a `package.json` that exists only for tooling).

=== "Add SonarQube"

    ```yaml
    jobs:
      ci:
        uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
        with:
          sonar_host_url: 'https://sonarqube.example.com'
          sonar_project_key: 'my-project'
        secrets: inherit
    ```

    Requires the `SONAR_TOKEN` secret in your repository settings.

---

## Step 4 — Enable GitHub Pages (optional)

Pages deployment is **disabled by default**. To enable the reports dashboard:

1. Go to **Settings → Pages**
2. Set **Source** to **GitHub Actions**
3. Add `pages_disabled: false` to your workflow:

```yaml
with:
  pages_disabled: false
```

After the next push to your default branch, Code Haven will deploy a
dashboard with test results, coverage reports, API docs, and security findings.

---

## Step 5 — Set up secrets (if needed)

Secrets are only needed for optional integrations. Add them at
**Settings → Secrets and variables → Actions**.

| Secret | When needed | Notes |
|--------|-------------|-------|
| `SONAR_TOKEN` | SonarQube integration | Generate in SonarQube → My Account → Security |
| `CHECKMARX_TOKEN` | Checkmarx SAST | Provided by your Checkmarx admin |
| `KUBE_CONFIG` | Kubernetes deployments | Base64-encoded kubeconfig |
| `CC_TEST_REPORTER_ID` | CodeClimate quality reports | From CodeClimate → Repo Settings → Test Coverage |
| `CYPRESS_RECORD_KEY` | Cypress Dashboard recording | From Cypress Cloud → Project Settings |
| `DEPLOY_SSH_KEY` | SSH deployments to VMs | Private key (ed25519 recommended) |
| `GCP_WIF_PROVIDER` | GCP authentication | Workload Identity Federation provider |
| `GCP_SA_EMAIL` | GCP authentication | Service account email |

!!! note "`GITHUB_TOKEN` is automatic"
    The `GITHUB_TOKEN` is provided by GitHub Actions and used for GHCR login,
    NuGet publishing, Helm OCI push, and Gitleaks scanning. No setup needed.

---

## What gets auto-detected?

Code Haven scans your repository and activates workflows based on what it finds:

| File / Pattern | What runs |
|----------------|-----------|
| `pom.xml` | Maven build, test, format check, Javadoc |
| `build.gradle` / `build.gradle.kts` | Gradle build, test, Javadoc |
| `package.json` | npm/yarn/pnpm install, build, test |
| `angular.json` | Angular build, test, lint |
| `setup.py` / `pyproject.toml` | Python build, pytest, coverage |
| `*.go` files | Go build, test, lint, fmt, vet |
| `Cargo.lock` | Rust build, test, fmt, clippy, doc |
| `CMakeLists.txt` | C/C++ build (CMake), test, clang-tidy, clang-format |
| `*.sln` / `*.csproj` | .NET build, test, format |
| `phpunit*` | PHP test with coverage |
| `Dockerfile` | Docker build, push to GHCR, Hadolint, Trivy scan |
| `.helmignore` | Helm lint, package, OCI push |
| `mkdocs.yml` | MkDocs documentation build |
| `*.sql` | SQLFluff SQL lint |
| `cypress.config.*` | Cypress E2E tests |
| `playwright.config.*` | Playwright E2E tests |
| `*.hurl` | Hurl API tests |
| `tox.ini` / `tox.toml` | Python tox multi-environment testing |
| `manage.py` | Django test runner |
| `deploy.yml` | Intent-based infrastructure deployment |

---

## Pipeline behavior by trigger

The pipeline adjusts its behavior based on how it was triggered:

| Trigger | What happens |
|---------|--------------|
| **Pull Request** | Build, test, security scan, quality metrics — no deploy, no publish |
| **Push to default branch** | Everything above + GitHub Pages + Docker `latest` tag |
| **Tag push (`v*`)** | Everything above + GitHub Release + package publishing + versioned images |

---

## Alternative: Segmented Mode

Instead of one unified workflow, you can split your pipeline into **concern-level workflows** — each with its own visibility and history in the GitHub Actions UI.

!!! info "When to use Segmented Mode"
    - You want to click "Security" and see **only** security results
    - You want separate run histories for build vs. deploy vs. quality
    - You don't want to see 17 nodes in a single workflow graph
    - You prefer declaring what you **ARE** rather than disabling what you're NOT

### Setup

Create multiple small workflow files in `.github/workflows/`:

=== "build.yml"

    ```yaml
    name: "🏗️ Build"
    on: [push, pull_request]
    permissions: { contents: read, checks: write, pull-requests: write }
    jobs:
      build:
        uses: code-haven/code-haven/.github/workflows/_orchestrate-build.yml@main
        secrets: inherit
    ```

=== "security.yml"

    ```yaml
    name: "🔒 Security"
    on: [push, pull_request]
    permissions: { contents: read, security-events: write, actions: read }
    jobs:
      security:
        uses: code-haven/code-haven/.github/workflows/_orchestrate-security.yml@main
        secrets: inherit
    ```

=== "quality.yml"

    ```yaml
    name: "📊 Quality"
    on: [push, pull_request]
    permissions: { contents: read, checks: write }
    jobs:
      quality:
        uses: code-haven/code-haven/.github/workflows/_orchestrate-quality.yml@main
        secrets: inherit
    ```

=== "deploy.yml (after build)"

    ```yaml
    name: "🚀 Deploy"
    on:
      workflow_run:
        workflows: ["🏗️ Build"]
        types: [completed]
        branches: [main]
    permissions: { contents: read, packages: write, id-token: write }
    jobs:
      deploy:
        if: github.event.workflow_run.conclusion == 'success'
        uses: code-haven/code-haven/.github/workflows/_orchestrate-deploy.yml@main
        secrets: inherit
    ```

### Result in GitHub Actions

```
🏗️ Build       ✓  (detected C++ → ran CMake build + tests)
🔒 Security    ✓  (ran Gitleaks + CodeQL + OSV)
📊 Quality     ✓  (ran linting + metrics)
🚀 Deploy      —  (no Dockerfile → completed in 5s)
```

Each is independently clickable with isolated run history. No disable flags needed.

!!! tip "Full templates"
    See [`examples/segmented/`](https://github.com/roachseb/code-haven/tree/main/examples/segmented) for ready-to-copy workflow files with comments.

---

## What next?

- **[Configuration](configuration.md)** — All available inputs, toggles, and secrets
- **[Architecture](architecture.md)** — How the modular pipeline works under the hood
- **[Examples](examples.md)** — Real-world configurations for common stacks
- **[Deploy (Intent-Based)](workflows/deploy.md)** — Declare infrastructure in YAML, deploy with Terraform
