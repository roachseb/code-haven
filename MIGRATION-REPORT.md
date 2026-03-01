# GitLab CI → GitHub Actions Migration Report

## Executive Summary

This report maps the entire **Code Haven Farm CI Templates** library (37 GitLab CI templates,
~80 jobs, ~200 variables) to a GitHub Actions equivalent. The goal: a reusable workflow
library that consumers include with one line, auto-detects their stack, and runs the right
jobs — exactly like the GitLab version.

**Verdict: Fully achievable**, but the architecture must change fundamentally because
GitHub Actions and GitLab CI have different reuse models.

---

## Part 1 — Concept Mapping

### 1.1 The Reuse Model (biggest difference)

| GitLab | GitHub Actions |
|--------|----------------|
| `include: project: code-haven-farm/ci-templates` — pulls in YAML, merges into consumer's pipeline | `uses: code-haven-farm/ci-templates/.github/workflows/workflow.yml@main` — calls a **reusable workflow** |
| One `include` loads everything; auto-detection via `rules: exists:` | Must use a **dispatcher workflow** that detects files and conditionally calls sub-workflows |
| Hidden jobs (`.template`) inherited via `extends:` | **Composite actions** (reusable steps) replace hidden jobs |
| Variables override everything | `workflow_call` inputs + secrets replace variables |

**GitLab's `include` merges all jobs into one pipeline. GitHub doesn't do this.**
In GitHub Actions, you either:
- **(A)** One mega reusable workflow with conditional jobs (simpler, matches GitLab mental model)
- **(B)** Multiple reusable workflows called from a dispatcher (more modular, more GitHub-native)

**Recommendation**: Option A — one primary reusable workflow (`devsecops.yml`) with conditional
jobs, mirroring `DevSecOps.gitlab-ci.yml`. Consumers call it once.

### 1.2 Core Mechanism Mapping

| GitLab CI Concept | GitHub Actions Equivalent |
|---|---|
| `stages:` (ordered list) | `jobs.<id>.needs:` (DAG-based) — no stages, use `needs` for ordering |
| `rules: exists: [pom.xml]` | `if: hashFiles('pom.xml') != ''` on job-level `if:` |
| `rules: if: $MAVEN_DISABLED` | `if: inputs.maven_disabled != true` or env check |
| `extends: .template` | Composite action (`uses: ./actions/toolkit`) |
| `services: [docker:dind]` | `services:` in workflow (only on Linux runners) OR use pre-installed Docker |
| `artifacts: paths:` | `actions/upload-artifact` / `actions/download-artifact` |
| `artifacts: reports: junit:` | Upload + `dorny/test-reporter` or `mikepenz/action-junit-report` |
| `cache: paths:` | `actions/cache` |
| `variables:` | `env:` at workflow/job level + `inputs:` for reusable workflows |
| `needs: [job]` (optional) | `needs: [job]` + `if: always()` for soft dependencies |
| `allow_failure: true` | `continue-on-error: true` |
| `coverage: /regex/` | Parse in script, set as output, display via badge/summary |
| `environment: name:` | `environment:` on job |
| `trigger: project:` | `workflow_dispatch` + `repository_dispatch` |
| `id_tokens:` (OIDC) | `permissions: id-token: write` + cloud-specific login actions |
| `interruptible: true` | `concurrency: { group: ..., cancel-in-progress: true }` |
| GitLab Pages | GitHub Pages (`actions/deploy-pages`) |
| `_redirects` (GitLab Pages) | `404.html` or configure in Pages settings |
| Container Registry (`$CI_REGISTRY`) | `ghcr.io` (GitHub Container Registry) |
| `$CI_COMMIT_SHA`, `$CI_COMMIT_REF_NAME` | `${{ github.sha }}`, `${{ github.ref_name }}` |
| `$CI_MERGE_REQUEST_ID` | `${{ github.event.pull_request.number }}` |
| `$CI_DEFAULT_BRANCH` | `${{ github.event.repository.default_branch }}` |
| `$CI_PROJECT_PATH` | `${{ github.repository }}` |
| `$CI_JOB_TOKEN` | `${{ secrets.GITHUB_TOKEN }}` |

### 1.3 Auto-Detection Translation

GitLab's `rules: exists:` has no direct GitHub equivalent, but `hashFiles()` works:

```yaml
# GitLab
rules:
  - exists: [pom.xml]

# GitHub Actions
jobs:
  maven-build:
    if: hashFiles('pom.xml') != ''
```

For glob patterns like `exists: [**/*.go]`, use:
```yaml
    if: hashFiles('**/*.go') != ''
```

### 1.4 Services (DinD) Translation

GitLab uses Docker-in-Docker as a service. GitHub-hosted runners come with Docker
pre-installed — no DinD needed. Self-hosted runners may need Docker setup.

```yaml
# GitLab
services:
  - docker:28.5.2-dind

# GitHub Actions — nothing needed on ubuntu-latest
# For self-hosted, use: docker/setup-buildx-action
```

---

## Part 2 — Architecture Design

### 2.1 Repository Structure

```
code-haven-farm/ci-templates/
├── github-actions/
│   ├── .github/
│   │   └── workflows/
│   │       ├── devsecops.yml          # Main reusable workflow (the "one include")
│   │       ├── ci.yml                 # This repo's own CI
│   │       └── demo-triggers.yml      # Trigger demos (like .gitlab-ci.yml)
│   │
│   ├── actions/                       # Composite actions (replace hidden jobs)
│   │   ├── toolkit/
│   │   │   └── action.yml             # .cr-toolkit-init equivalent
│   │   ├── docker-build/
│   │   │   └── action.yml             # docker-publish equivalent
│   │   ├── cloud-login/
│   │   │   └── action.yml             # AWS/Azure/GCP unified login
│   │   ├── k8s-deploy/
│   │   │   └── action.yml             # Helm deploy equivalent
│   │   └── pages-deploy/
│   │       └── action.yml             # Pages aggregation + deploy
│   │
│   ├── docs/                          # MkDocs documentation (mirrored)
│   ├── quality/                       # CodeClimate config generator
│   │   ├── Dockerfile
│   │   ├── main.py
│   │   └── action.yml                 # Composite action to run it
│   │
│   └── README.md
```

### 2.2 Consumer Experience

**GitLab (current):**
```yaml
include:
  - project: code-haven-farm/ci-templates
    file: DevSecOps.gitlab-ci.yml
```

**GitHub Actions (target):**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  devsecops:
    uses: code-haven-farm/ci-templates/.github/workflows/devsecops.yml@main
    secrets: inherit
    with:
      # All optional — auto-detection handles the rest
      sonar_host_url: ${{ vars.SONAR_HOST_URL }}
```

One line. Same philosophy.

### 2.3 The Dispatcher Pattern

The main `devsecops.yml` reusable workflow must:

1. **Detect** what's in the repo (check for `pom.xml`, `package.json`, `Cargo.lock`, etc.)
2. **Conditionally run** only the relevant jobs
3. **Aggregate** artifacts into Pages at the end

```yaml
# devsecops.yml (simplified structure)
on:
  workflow_call:
    inputs:
      maven_disabled:    { type: boolean, default: false }
      docker_disabled:   { type: boolean, default: false }
      sonar_host_url:    { type: string,  default: '' }
      # ... ~50 inputs mapping to GitLab variables
    secrets:
      SONAR_TOKEN:       { required: false }
      CHECKMARX_TOKEN:   { required: false }
      # ...

jobs:
  # ── Detection ──────────────────────────────────
  detect:
    runs-on: ubuntu-latest
    outputs:
      has_pom:         ${{ steps.check.outputs.has_pom }}
      has_gradle:      ${{ steps.check.outputs.has_gradle }}
      has_package:     ${{ steps.check.outputs.has_package }}
      has_angular:     ${{ steps.check.outputs.has_angular }}
      has_cargo:       ${{ steps.check.outputs.has_cargo }}
      has_go:          ${{ steps.check.outputs.has_go }}
      has_python:      ${{ steps.check.outputs.has_python }}
      has_dotnet:      ${{ steps.check.outputs.has_dotnet }}
      has_php:         ${{ steps.check.outputs.has_php }}
      has_dockerfile:  ${{ steps.check.outputs.has_dockerfile }}
      has_helm:        ${{ steps.check.outputs.has_helm }}
      has_mkdocs:      ${{ steps.check.outputs.has_mkdocs }}
      has_sql:         ${{ steps.check.outputs.has_sql }}
      has_hurl:        ${{ steps.check.outputs.has_hurl }}
    steps:
      - uses: actions/checkout@v4
      - id: check
        run: |
          echo "has_pom=$([[ -f pom.xml ]] && echo true || echo false)" >> $GITHUB_OUTPUT
          echo "has_gradle=$([[ -f build.gradle || -f build.gradle.kts ]] && echo true || echo false)" >> $GITHUB_OUTPUT
          # ... etc

  # ── Build Jobs ─────────────────────────────────
  maven-build:
    needs: detect
    if: needs.detect.outputs.has_pom == 'true' && !inputs.maven_disabled
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
      - run: mvn ${{ inputs.maven_cli_opts || '--batch-mode' }} install
      - uses: actions/upload-artifact@v4
        with: { name: maven-target, path: '**/target' }

  gradle-build:
    needs: detect
    if: needs.detect.outputs.has_gradle == 'true' && !inputs.gradle_disabled
    # ...

  npm-install:
    needs: detect
    if: needs.detect.outputs.has_package == 'true' && !inputs.npm_disabled
    # ... auto-detect yarn/pnpm/npm

  # ── Test Jobs ──────────────────────────────────
  # ... (parallel, depend on build jobs)

  # ── Security ───────────────────────────────────
  sast:
    if: ${{ !inputs.sast_disabled }}
    uses: github/codeql-action/analyze@v3    # GitHub native SAST

  secret-detection:
    if: ${{ !inputs.secret_detection_disabled }}
    # gitleaks/gitleaks-action

  dependency-scan:
    # github/codeql-action or trivy

  # ── Deploy ─────────────────────────────────────
  pages:
    needs: [all-test-jobs]
    if: github.ref == format('refs/heads/{0}', github.event.repository.default_branch)
    # Aggregate artifacts → deploy to GitHub Pages
```

---

## Part 3 — Template-by-Template Migration Plan

### 3.1 Build Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **Maven.gitlab-ci.yml** | `actions/setup-java` + `mvn` | Java setup is native; no DinD needed for plain builds. Testcontainers works natively on ubuntu-latest |
| **Gradle.gitlab-ci.yml** | `actions/setup-java` + `gradle/actions/setup-gradle` | Gradle wrapper support built-in |
| **Npm.gitlab-ci.yml** | `actions/setup-node` + npm/yarn/pnpm | Auto-detect lockfile, use `actions/cache` for node_modules |
| **Angular.gitlab-ci.yml** | Same as Npm + `ng` commands | Split into build/test/lint jobs |
| **Python.gitlab-ci.yml** | `actions/setup-python` + pip/tox/build | `coverage` + `pytest` + `twine` |
| **Golang.gitlab-ci.yml** | `actions/setup-go` + `golangci-lint-action` | Lint via dedicated action |
| **Rust.gitlab-ci.yml** | `dtolnay/rust-toolchain` + `cargo` | Nightly + grcov for coverage |
| **Dotnet.gitlab-ci.yml** | `actions/setup-dotnet` + `dotnet` CLI | NuGet push to GitHub Packages |
| **Php.gitlab-ci.yml** | `shivammathur/setup-php` + composer | PHPUnit, pecl extensions |

### 3.2 Docker Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **Docker.gitlab-ci.yml** (docker-publish) | `docker/build-push-action` + `docker/login-action` | Push to GHCR by default; supports ECR/ACR via inputs |
| **container_scanning** | `aquasecurity/trivy-action` | Industry standard; outputs SARIF for GitHub Security tab |
| **hadolint** | `hadolint/hadolint-action` | Native GitHub Action exists |

### 3.3 Security Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **SAST.gitlab-ci.yml** | `github/codeql-action` | GitHub's native SAST; uploads to Security tab |
| **Secret-Detection.gitlab-ci.yml** | `gitleaks/gitleaks-action` | Same tool, native action |
| **Dependency-Scanning.gitlab-ci.yml** | `github/codeql-action` + Dependabot | Dependabot is GitHub-native; also `aquasecurity/trivy-action` for SBOMs |
| **SAST-IaC.gitlab-ci.yml** (KICS) | `checkmarx/kics-github-action` | Official KICS action exists |
| **SonarQube.gitlab-ci.yml** | `SonarSource/sonarqube-scan-action` | Official action; or `sonarcloud-github-action` for SonarCloud |
| **Checkmarx.gitlab-ci.yml** | `checkmarx-ts/checkmarx-cxflow-github-action` | Official CxFlow action |
| **SqlFluff.gitlab-ci.yml** | `sqlfluff/sqlfluff-github-actions/lint` | Official action |

### 3.4 Quality / Metrics Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **Code-Quality.gitlab-ci.yml** | Custom composite action wrapping the quality Docker image | Same `main.py` → CodeClimate approach, or switch to `super-linter` |
| **Scc.gitlab-ci.yml** | `boyter/scc-action` (if exists) or inline `go install github.com/boyter/scc/v3` | Run + publish as job summary |
| **Markdown.gitlab-ci.yml** (links-check) | `lycheeverse/lychee-action` | Official GitHub Action |

### 3.5 Testing Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **Cypress.gitlab-ci.yml** | `cypress-io/github-action` | Official; supports Firefox/Chrome/Edge matrix |
| **Playwright.gitlab-ci.yml** | `microsoft's playwright container` + `npx playwright test` | Use matrix for browsers |
| **Hurl.gitlab-ci.yml** | `orange-opensource/hurl` container + `hurl --test` | No official action; run in container |

### 3.6 Deployment Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **Kubernetes.gitlab-ci.yml** | `azure/k8s-deploy`, `aws-actions/amazon-eks`, or raw `helm upgrade` | Cloud-specific login actions |
| **Pages.gitlab-ci.yml** | `actions/deploy-pages` | Aggregate artifacts → deploy. GitHub Pages has native support |
| **Renovate.gitlab-ci.yml** | `renovatebot/github-action` | Official action; or just enable Renovate GitHub App |
| **Triage.gitlab-ci.yml** | `github/issue-labeler` + custom actions | GitLab Triage has no direct equivalent; use GitHub's built-in labeling |
| **GitLab.gitlab-ci.yml** (GitLabForm) | N/A — GitHub-specific: use `github/safe-settings` or Terraform | Different paradigm |

### 3.7 Cloud Login Templates

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **aws.toolkit** | `aws-actions/configure-aws-credentials` | OIDC native support |
| **azure.toolkit** | `azure/login` | Service principal or OIDC |
| **gcp.toolkit** | `google-github-actions/auth` | Workload identity federation |

### 3.8 Workflow Template

| GitLab Template | GitHub Action | Notes |
|---|---|---|
| **Workflow.gitlab-ci.yml** | `on:` trigger block + `concurrency:` | Pipeline dedup via `concurrency: { group: ${{ github.ref }}, cancel-in-progress: true }` |

---

## Part 4 — Key Differences & Gotchas

### 4.1 The 20-Job Limit (Reusable Workflows)

GitHub reusable workflows can call at most **20 reusable workflows** from a single caller,
and nesting is limited to **4 levels**. Since we have ~80 jobs, everything must be defined
as jobs within ONE reusable workflow (not calling sub-workflows).

**Impact**: The `devsecops.yml` file will be large (~2000 lines). This is fine — it's the
same as GitLab's approach where all includes merge into one pipeline.

### 4.2 Artifact Passing

GitLab auto-passes artifacts between stages. GitHub requires explicit upload/download:

```yaml
# Upload in build job
- uses: actions/upload-artifact@v4
  with: { name: maven-target, path: '**/target', retention-days: 1 }

# Download in test job
- uses: actions/download-artifact@v4
  with: { name: maven-target }
```

**Impact**: Every job that needs another job's output needs explicit artifact handling.

### 4.3 Conditional Jobs

GitHub evaluates `if:` on a job **before** the job starts, but `hashFiles()` only works
in `runs-on` context — not in job-level `if:` for reusable workflows. Solution: use a
`detect` job that outputs booleans.

### 4.4 Docker-in-Docker

GitHub-hosted runners have Docker pre-installed. No DinD service needed. Testcontainers
work out of the box.

**Impact**: Simplifies everything. The `.dind` / `services: docker:dind` pattern disappears entirely.

### 4.5 Security Reports

GitLab has native `artifacts: reports: sast:` that populate the Security Dashboard.
GitHub equivalent: upload SARIF files to the Security tab:

```yaml
- uses: github/codeql-action/upload-sarif@v3
  with: { sarif_file: results.sarif }
```

### 4.6 Pages

GitLab Pages uses artifacts named `public`. GitHub Pages uses `actions/deploy-pages`:

```yaml
- uses: actions/upload-pages-artifact@v3
  with: { path: ./public }
- uses: actions/deploy-pages@v4
```

No `_redirects` support — use `index.html` redirects or configure in repo Settings.

### 4.7 Container Registry

| GitLab | GitHub |
|--------|--------|
| `$CI_REGISTRY` → `registry.gitlab.com` | `ghcr.io` |
| `$CI_REGISTRY_USER` / `$CI_REGISTRY_PASSWORD` | `${{ github.actor }}` / `${{ secrets.GITHUB_TOKEN }}` |
| `$CI_REGISTRY_IMAGE` → `registry.gitlab.com/<project>` | `ghcr.io/${{ github.repository }}` |

### 4.8 Missing GitHub Equivalents (Manual Implementation Needed)

| GitLab Feature | Gap | Workaround |
|---|---|---|
| `rules: exists:` (glob) | `hashFiles()` only returns hash, not boolean | `detect` job with `find` / `test -f` |
| `environment: on_stop:` | No auto-stop environments | Manual dispatch or scheduled cleanup |
| `resource_group:` | No native resource locking | `concurrency:` group (close but not identical) |
| `dotenv` artifact reports | No native equivalent | Write to `$GITHUB_OUTPUT` / `$GITHUB_ENV` |
| GitLab Triage | No equivalent | Build custom action or use `actions/stale` |
| GitLabForm | No equivalent | Use `github/safe-settings` or skip |
| `$CI_JOB_NAME` in trigger | No dynamic dispatch | Use matrix or workflow_dispatch |

---

## Part 5 — Implementation Roadmap

### Phase 1: Foundation (Week 1)
1. ☐ Create repo structure under `github-actions/`
2. ☐ Build `detect` job (file existence detection)
3. ☐ Build `toolkit` composite action (logging, CA certs)
4. ☐ Build `cloud-login` composite action (AWS OIDC, Azure SP, GCP WIF)
5. ☐ Create base `devsecops.yml` reusable workflow skeleton with all inputs

### Phase 2: Build Jobs (Week 2)
6. ☐ Maven build + test + format + Javadoc
7. ☐ Gradle build + test + doc
8. ☐ NPM install + build + test (auto-detect yarn/pnpm)
9. ☐ Angular build + test + lint
10. ☐ Python build + test + tox + mkdocs + deploy
11. ☐ Go build + test + lint + fmt + vet
12. ☐ Rust build + nightly + fmt + lint + doc
13. ☐ .NET build + test + format + publish
14. ☐ PHP unit + twig-lint

### Phase 3: Docker & Registry (Week 3)
15. ☐ Docker build + push (GHCR default, ECR/ACR optional)
16. ☐ Container scanning (Trivy)
17. ☐ Hadolint
18. ☐ Quality image build + push to GHCR

### Phase 4: Security (Week 3-4)
19. ☐ CodeQL SAST (replaces semgrep/spotbugs/etc.)
20. ☐ Gitleaks secret detection
21. ☐ Dependency scanning (Dependabot + Trivy)
22. ☐ KICS IaC scanning
23. ☐ SonarQube / SonarCloud
24. ☐ Checkmarx CxFlow
25. ☐ SQLFluff linting

### Phase 5: Quality & Metrics (Week 4)
26. ☐ Code Quality (CodeClimate via custom image)
27. ☐ SCC code metrics
28. ☐ Markdown link checking (Lychee)

### Phase 6: Testing Frameworks (Week 4)
29. ☐ Cypress (browser matrix)
30. ☐ Playwright
31. ☐ Hurl

### Phase 7: Deployment (Week 5)
32. ☐ Helm lint + package + deploy
33. ☐ K8s deploy (review/staging/production environments)
34. ☐ GitHub Pages aggregation
35. ☐ NuGet / PyPI / npm package publishing

### Phase 8: Housekeeping (Week 5)
36. ☐ Renovate (or just enable the GitHub App)
37. ☐ Stale issue management (replaces Triage)
38. ☐ Workflow concurrency + dedup (replaces Workflow.gitlab-ci.yml)
39. ☐ Documentation (MkDocs site for the GH Actions version)
40. ☐ Demo repos / testing

---

## Part 6 — Effort Estimate

| Category | Jobs | Effort | Complexity |
|---|---|---|---|
| Foundation (detect, toolkit, cloud) | 4 composite actions | 2 days | Medium — OIDC mapping is tricky |
| Build jobs (9 languages) | ~25 jobs | 3-4 days | Low-Medium — mostly `setup-*` actions |
| Docker & Registry | 3 jobs | 1 day | Low — native Docker on runners |
| Security | 7 jobs | 2 days | Medium — SARIF format mapping |
| Quality & Metrics | 3 jobs | 1 day | Low |
| Testing frameworks | 3 jobs | 1 day | Low — official actions exist |
| Deployment (Helm/K8s/Pages) | 8 jobs | 2-3 days | High — environment management differs significantly |
| Documentation & testing | — | 2 days | Low |
| **Total** | **~80 jobs** | **~15 working days** | |

---

## Part 7 — What Gets Simpler in GitHub

1. **No DinD** — Docker is pre-installed. Massive simplification.
2. **No `extends` / `!reference` gymnastics** — Composite actions are cleaner.
3. **Native OIDC** — `permissions: id-token: write` is simpler than GitLab's `id_tokens:`.
4. **Dependabot** — Replaces Renovate (zero config, GitHub-native).
5. **Security tab** — SARIF upload gives you a security dashboard for free.
6. **Job summaries** — `$GITHUB_STEP_SUMMARY` provides rich Markdown output per job.
7. **Matrix builds** — Cypress multi-browser becomes a matrix instead of 3 copy-paste jobs.

## Part 8 — What Gets Harder

1. **No `rules: exists:` on job level** — Requires a detection job.
2. **No automatic artifact passing** — Explicit upload/download everywhere.
3. **No ordered stages** — Must manually define `needs:` DAG.
4. **20-workflow nesting limit** — Everything in one file.
5. **No `environment: on_stop`** — Review app cleanup needs manual dispatch.
6. **No dotenv reports** — Must use `$GITHUB_OUTPUT` between jobs.
7. **Pages is simpler but less flexible** — No `_redirects`, no branch-specific deploys by default.
8. **Variable scoping** — GitHub has `vars` (repo-level) + `secrets` + `inputs`, no group-level variables.
