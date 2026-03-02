# Configuration Reference

All inputs are passed via `with:` when calling the orchestrator workflow.

## Global Settings

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `runner` | string | `ubuntu-latest` | GitHub-hosted or self-hosted runner label |
| `debug` | boolean | `false` | Enable verbose debug logging |

## Language / Feature Toggles

All toggles follow the pattern `<stack>_disabled` — set to `true` to skip:

| Toggle | Disables |
|--------|----------|
| `maven_disabled` | Maven build, format check, Javadoc |
| `gradle_disabled` | Gradle build, Javadoc |
| `npm_disabled` | Node.js install, build, test |
| `angular_disabled` | Angular build, test, lint |
| `python_disabled` | Python build, test, tox, Django, PyPI deploy |
| `golang_disabled` | Go build, test, lint, fmt, vet |
| `rust_disabled` | Rust build, test, fmt, clippy, doc |
| `dotnet_disabled` | .NET build, test, format, NuGet publish |
| `php_disabled` | PHP test, Twig lint |
| `docker_disabled` | Docker build & push |
| `helm_disabled` | Helm lint & package |
| `cypress_disabled` | Cypress E2E tests |
| `playwright_disabled` | Playwright E2E tests |
| `hurl_disabled` | Hurl API tests |
| `pages_disabled` | GitHub Pages report deployment |

## Security Toggles

| Toggle | Disables |
|--------|----------|
| `sast_disabled` | CodeQL SAST analysis |
| `secret_detection_disabled` | Gitleaks secret detection |
| `dependency_scan_disabled` | Trivy filesystem dependency scan |
| `container_scan_disabled` | Trivy container image scan |
| `iac_scan_disabled` | KICS Infrastructure-as-Code scan |
| `sonar_disabled` | SonarQube analysis |
| `checkmarx_disabled` | Checkmarx SAST |
| `sqlfluff_disabled` | SQLFluff SQL linting |
| `links_check_disabled` | Lychee link checker |
| `code_quality_disabled` | CodeClimate quality |
| `code_metrics_disabled` | SCC code metrics |
| `hadolint_disabled` | Dockerfile linting |

## Language-Specific Options

### Java

| Input | Default | Description |
|-------|---------|-------------|
| `java_version` | `21` | JDK version for `setup-java` |
| `java_distribution` | `temurin` | JDK distribution (temurin, corretto, zulu, etc.) |
| `maven_cli_opts` | `--batch-mode --errors --fail-at-end --show-version` | Maven CLI options |
| `maven_build_cmd` | `install` | Maven build goal |
| `java_formatter` | `revelc` | Java formatter: `revelc`, `spotify`, or `disabled` |
| `gradle_build_cmd` | `build` | Gradle build task |
| `java_doc_enabled` | `false` | Run Javadoc job (set to `true` to enable Javadoc generation) |

### Node.js

| Input | Default | Description |
|-------|---------|-------------|
| `node_version` | `lts/*` | Node.js version |
| `node_build_args` | `run build` | npm build command |
| `node_test_args` | `run test` | npm test command |

### Python

| Input | Default | Description |
|-------|---------|-------------|
| `python_version` | `3.x` | Python version |

### Go / Rust / .NET / PHP

| Input | Default | Description |
|-------|---------|-------------|
| `golang_version` | `stable` | Go version |
| `rust_toolchain` | `stable` | Rust toolchain |
| `dotnet_version` | `8.0.x` | .NET SDK version |
| `php_version` | `8.3` | PHP version |
| `php_extensions` | `mbstring, xml, xdebug` | PHP extensions to install |

## Docker Options

| Input | Default | Description |
|-------|---------|-------------|
| `dockerfile_path` | `Dockerfile` | Path to Dockerfile |
| `docker_context` | `.` | Docker build context |
| `docker_tag_extra` | `latest` | Extra tag on default branch pushes |
| `docker_registry` | `ghcr.io` | Container registry |

## Helm / Kubernetes

| Input | Default | Description |
|-------|---------|-------------|
| `helm_chart_path` | `.` | Path to Helm chart directory |
| `helm_values_files` | `values.yaml` | Comma-separated Helm values files |
| `k8s_namespace` | *(empty)* | Kubernetes namespace |

## Security Tool Options

| Input | Default | Description |
|-------|---------|-------------|
| `sonar_host_url` | *(empty)* | SonarQube server URL (enables scan when set) |
| `sonar_project_key` | *(repo name)* | SonarQube project key |
| `checkmarx_base_url` | *(empty)* | Checkmarx server URL (enables scan when set) |
| `sqlfluff_dialect` | `ansi` | SQL dialect for SQLFluff |
| `hurl_extra_args` | *(empty)* | Extra Hurl CLI arguments |
| `cypress_browsers` | `chrome` | Comma-separated browsers for Cypress |

## Secrets

| Secret | Required | Used by |
|--------|----------|---------|
| `SONAR_TOKEN` | No | SonarQube analysis |
| `CHECKMARX_TOKEN` | No | Checkmarx SAST |
| `CHECKMARX_USERNAME` | No | Checkmarx authentication |
| `CHECKMARX_PASSWORD` | No | Checkmarx authentication |
| `KUBE_CONFIG` | No | Kubernetes deployments (via k8s-deploy action) |
| `AWS_ROLE_ARN` | No | AWS OIDC authentication (via cloud-login action) |
| `CC_TEST_REPORTER_ID` | No | CodeClimate quality reporting |
| `CYPRESS_RECORD_KEY` | No | Cypress Dashboard recording |

!!! note "GITHUB_TOKEN"
    The `GITHUB_TOKEN` is automatically available and used for GHCR login,
    NuGet publishing, Helm OCI push, and Gitleaks scanning. No configuration needed.
