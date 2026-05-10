# Configuration Reference

All inputs are passed via `with:` when calling the orchestrator workflow.
Every input is optional — the pipeline works with zero configuration.

```yaml title="Example"
jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      java_version: '21'
      docker_registry: 'ghcr.io'
      rust_disabled: true
    secrets: inherit
```

---

## Global Settings

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `runner` | string | `ubuntu-latest` | GitHub-hosted or self-hosted runner label |
| `debug` | boolean | `false` | Enable verbose debug logging across all jobs |

## Language / Feature Toggles

Set any toggle to `true` to skip that stack entirely — saves runner minutes.

| Toggle | What it disables |
|--------|-----------------|
| `maven_disabled` | Maven build, format check, Javadoc |
| `gradle_disabled` | Gradle build, Javadoc |
| `npm_disabled` | Node.js install, build, test |
| `angular_disabled` | Angular build, test, lint |
| `python_disabled` | Python build, test, tox, Django, PyPI deploy |
| `golang_disabled` | Go build, test, lint, fmt, vet |
| `rust_disabled` | Rust build, test, fmt, clippy, doc |
| `cpp_disabled` | C/C++ build, test, clang-tidy, clang-format, Conan |
| `dotnet_disabled` | .NET build, test, format, NuGet publish |
| `php_disabled` | PHP test, Twig lint |
| `docker_disabled` | Docker build, push, Hadolint, Trivy |
| `helm_disabled` | Helm lint, package, OCI push |
| `cypress_disabled` | Cypress E2E tests |
| `playwright_disabled` | Playwright E2E tests |
| `hurl_disabled` | Hurl API tests |
| `pages_disabled` | GitHub Pages report deployment (**default: true** — opt-in) |

## Security Toggles

Security scans run by default and **soft-fail** — they report findings but
don't block the pipeline. Set any toggle to `true` to skip that scanner entirely.

!!! info "What does soft-fail mean?"
    A soft-failing scan uploads its results (SARIF reports, annotations) but
    won't cause the workflow to fail. This lets teams see findings without
    blocking deployments. To enforce hard-fail, configure branch protection
    rules that require specific status checks.

| Toggle | What it disables |
|--------|-----------------|
| `sast_disabled` | CodeQL SAST analysis |
| `secret_detection_disabled` | Gitleaks secret detection |
| `dependency_scan_disabled` | Trivy filesystem dependency scan |
| `container_scan_disabled` | Trivy container image scan |
| `iac_scan_disabled` | KICS Infrastructure-as-Code scan |
| `sonar_disabled` | SonarQube analysis |
| `checkmarx_disabled` | Checkmarx SAST |
| `sqlfluff_disabled` | SQLFluff SQL linting |
| `semgrep_disabled` | Semgrep open-source SAST |
| `osv_disabled` | Google OSV vulnerability scanner |
| `license_check_disabled` | License compliance check |
| `scorecard_disabled` | OSSF Scorecard supply chain security |
| `links_check_disabled` | Lychee link checker |
| `code_quality_disabled` | CodeClimate quality analysis |
| `code_metrics_disabled` | SCC code metrics (lines, complexity) |
| `hadolint_disabled` | Dockerfile best-practice linting |
| `actionlint_disabled` | GitHub Actions workflow syntax linting |

## Language-Specific Options

### Java

| Input | Default | Description |
|-------|---------|-------------|
| `java_version` | `21` | JDK version for `setup-java` |
| `java_distribution` | `temurin` | JDK distribution (`temurin`, `corretto`, `zulu`, `liberica`) |
| `maven_cli_opts` | `--batch-mode --errors --fail-at-end --show-version` | Maven CLI options |
| `maven_build_cmd` | `install` | Maven build goal (`install`, `verify`, `package`) |
| `java_formatter` | `revelc` | Java formatter: `revelc`, `spotify`, or `disabled` |
| `gradle_build_cmd` | `build` | Gradle build task |
| `java_doc_enabled` | `false` | Enable Javadoc generation and artifact upload |

### Node.js

| Input | Default | Description |
|-------|---------|-------------|
| `node_version` | `lts/*` | Node.js version |
| `node_build_args` | `run build` | npm/yarn/pnpm build command |
| `node_test_args` | `run test` | npm/yarn/pnpm test command |

!!! note "Package manager auto-detection"
    Code Haven detects `pnpm-lock.yaml`, `yarn.lock`, or `package-lock.json`
    and uses the matching package manager. Precedence: pnpm > yarn > npm.

### Python

| Input | Default | Description |
|-------|---------|-------------|
| `python_version` | `3.x` | Python version |

Python auto-detects `pytest.ini`, `pyproject.toml`, `setup.py`, `tox.ini`,
`manage.py` (Django), and `mkdocs.yml` to decide which jobs to run.

### Go

| Input | Default | Description |
|-------|---------|-------------|
| `golang_version` | `stable` | Go version |

### Rust

| Input | Default | Description |
|-------|---------|-------------|
| `rust_toolchain` | `stable` | Rust toolchain (`stable`, `nightly`, `1.78`) |

### .NET

| Input | Default | Description |
|-------|---------|-------------|
| `dotnet_version` | `8.0.x` | .NET SDK version |

### PHP

| Input | Default | Description |
|-------|---------|-------------|
| `php_version` | `8.3` | PHP version |
| `php_extensions` | `mbstring, xml, xdebug` | PHP extensions to install |

## Docker Options

| Input | Default | Description |
|-------|---------|-------------|
| `dockerfile_path` | `Dockerfile` | Path to Dockerfile |
| `docker_context` | `.` | Docker build context directory |
| `docker_tag_extra` | `latest` | Extra tag applied on default branch pushes |
| `docker_registry` | `ghcr.io` | Container registry (`ghcr.io` or GCP Artifact Registry) |

!!! info "Tagging strategy"
    Code Haven applies smart tags automatically:

    - **PR**: `pr-42`
    - **Branch push**: `sha-abc1234` + `latest` (default branch only)
    - **Tag push** (`v1.2.3`): `1.2.3` + `1.2` + `1` + `latest`

## Helm / Kubernetes

| Input | Default | Description |
|-------|---------|-------------|
| `helm_chart_path` | `.` | Path to Helm chart directory |
| `helm_values_files` | `values.yaml` | Comma-separated Helm values files for deployment |
| `k8s_namespace` | *(empty)* | Kubernetes namespace for deployment |

## E2E Testing

| Input | Default | Description |
|-------|---------|-------------|
| `cypress_browsers` | `chrome` | Comma-separated browsers for Cypress |
| `hurl_extra_args` | *(empty)* | Extra CLI arguments for Hurl |

## Security Tool Options

| Input | Default | Description |
|-------|---------|-------------|
| `sonar_host_url` | *(empty)* | SonarQube server URL — enables scan when set |
| `sonar_project_key` | *(repo name)* | SonarQube project key |
| `checkmarx_base_url` | *(empty)* | Checkmarx server URL — enables scan when set |
| `sqlfluff_dialect` | `ansi` | SQL dialect for SQLFluff (`ansi`, `tsql`, `postgres`, `mysql`) |

---

## Secrets

Add secrets at **Settings → Secrets and variables → Actions**.
All secrets are optional — only configure what you use.

| Secret | Used by |
|--------|---------|
| `SONAR_TOKEN` | SonarQube analysis |
| `CHECKMARX_TOKEN` | Checkmarx SAST |
| `CHECKMARX_USERNAME` | Checkmarx authentication (alternative to token) |
| `CHECKMARX_PASSWORD` | Checkmarx authentication (alternative to token) |
| `KUBE_CONFIG` | Kubernetes deployments via `k8s-deploy` action |
| `AWS_ROLE_ARN` | AWS OIDC authentication via `cloud-login` action |
| `CC_TEST_REPORTER_ID` | CodeClimate quality reporting |
| `CYPRESS_RECORD_KEY` | Cypress Dashboard recording |
| `DEPLOY_HOST` | SSH deployment target hostname |
| `DEPLOY_SSH_KEY` | SSH private key for deployment |
| `KNOWN_HOSTS` | SSH known_hosts for host verification |
| `CONAN_REMOTE_URL` | Conan package registry URL (C++) |
| `CONAN_LOGIN_USERNAME` | Conan remote authentication |
| `CONAN_LOGIN_PASSWORD` | Conan remote authentication |
| `GCP_WIF_PROVIDER` | GCP Workload Identity Federation provider resource |
| `GCP_SA_EMAIL` | GCP service account email |

!!! note "`GITHUB_TOKEN` is automatic"
    The `GITHUB_TOKEN` is provided by GitHub Actions and handles GHCR login,
    NuGet publishing, Helm OCI push, and Gitleaks scanning. No setup needed.

## C/C++ Options

| Input | Default | Description |
|-------|---------|-------------|
| `cpp_compiler` | `gcc` | Compiler: `gcc` or `clang` |
| `cpp_compiler_version` | `13` | Compiler version (e.g., GCC 13, Clang 17) |
| `cpp_standard` | `20` | C++ standard: `14`, `17`, `20`, `23` |
| `cpp_build_type` | `Release` | CMake build type: `Release`, `Debug`, `RelWithDebInfo` |
| `cpp_build_system` | `cmake` | Build system: `cmake` or `meson` |
| `cpp_package_manager` | `conan` | Package manager: `conan`, `vcpkg`, or `none` |
| `cpp_conan_remote` | *(empty)* | Custom Conan remote URL for dependency resolution |
| `cpp_test_framework` | `ctest` | Test framework: `ctest`, `gtest`, `catch2` |
| `cpp_coverage_enabled` | `true` | Generate gcov/lcov coverage reports |
| `cpp_cross_compile` | *(empty)* | Target triple for cross-compilation (e.g., `aarch64-linux-gnu`) |

---

## GCP / Registry Options

| Input | Default | Description |
|-------|---------|-------------|
| `package_registry` | `github` | Target registry: `github`, `gcp`, or `both` |
| `gcp_project_id` | *(empty)* | GCP project ID (for Artifact Registry) |
| `gcp_region` | `us-central1` | GCP Artifact Registry region |
| `gcp_docker_repo` | `containers` | GCP AR Docker repository name |
| `gcp_maven_repo` | `java-libs` | GCP AR Maven repository name |
| `gcp_npm_repo` | `npm-libs` | GCP AR npm repository name |
| `gcp_python_repo` | `python-libs` | GCP AR Python repository name |
| `gcp_conan_repo` | `cpp-libs` | GCP AR generic/Conan repository name |

---

## Branch Packaging & Deployment

| Input | Default | Description |
|-------|---------|-------------|
| `package_on_feature` | `false` | Enable packaging on feature branches |
| `package_branches` | `main` | Glob patterns for branches that produce packages |
| `deploy_enabled` | `false` | Master switch for deployment |
| `deploy_branches` | `main` | Branches that trigger deployment |
| `deploy_type` | `none` | Deployment method: `k8s`, `cloud-run`, `ssh`, `none` |

See [Branch Packaging](branch-packaging.md) for the full strategy.

---

## SSH Deployment

| Input | Default | Description |
|-------|---------|-------------|
| `ssh_host` | *(empty)* | Target hostname for SSH deployment |
| `ssh_user` | `deploy` | SSH username |
| `ssh_port` | `22` | SSH port |
| `ssh_deploy_script` | `deploy/deploy.sh` | Path to deployment script in repo |
| `ssh_deploy_path` | `/opt/app` | Remote deployment directory |

See the [SSH Deploy action](actions/ssh-deploy.md) for usage details and security considerations.

---

## Intent-Based Deployment (Advanced)

For infrastructure deployment via Terraform, create a `deploy.yml` at the root
of your repository instead of using `with:` inputs. See the
[Deploy workflow docs](workflows/deploy.md) for the full reference.

```yaml title="deploy.yml (in your repo root)"
team: my-team
cloud: gcp
runtime: cloud-run
project_id: my-gcp-project
region: us-central1
expose: private

environments:
  dev:
    min_instances: 0
    max_instances: 3
  prod:
    min_instances: 2
    max_instances: 10
    cpu: "2"
    memory: 1Gi
```

| Deploy Secret | Used by |
|---------------|---------|
| `DEPLOY_STATE_BUCKET` | Terraform state backend (GCS/S3/Azure Storage) |
| `DEPLOY_GCP_WIF_PROVIDER` | GCP Workload Identity Federation for deploy |
| `DEPLOY_GCP_SA_EMAIL` | GCP service account for deploy |
| `DEPLOY_AWS_ROLE_ARN` | AWS OIDC role for deploy |
| `DEPLOY_AWS_REGION` | AWS region for deploy |
| `DEPLOY_AZURE_CLIENT_ID` | Azure service principal client ID |
| `DEPLOY_AZURE_TENANT_ID` | Azure AD tenant ID |
| `DEPLOY_AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
