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
| `pages_disabled` | GitHub Pages portal deployment (default: **true** — opt-in) |

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
| `semgrep_disabled` | Semgrep open-source SAST |
| `osv_disabled` | Google OSV vulnerability scanner |
| `license_check_disabled` | License compliance check |
| `scorecard_disabled` | OSSF Scorecard supply chain security |
| `links_check_disabled` | Lychee link checker |
| `code_quality_disabled` | CodeClimate quality |
| `code_metrics_disabled` | SCC code metrics |
| `hadolint_disabled` | Dockerfile linting |
| `actionlint_disabled` | GitHub Actions workflow linting |

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
| `DEPLOY_HOST` | No | SSH deployment target hostname |
| `DEPLOY_SSH_KEY` | No | SSH private key for deployment |
| `KNOWN_HOSTS` | No | SSH known_hosts for host verification |
| `CONAN_REMOTE_URL` | No | Conan package registry URL (C++) |
| `CONAN_LOGIN_USERNAME` | No | Conan remote authentication |
| `CONAN_LOGIN_PASSWORD` | No | Conan remote authentication |
| `GCP_WIF_PROVIDER` | No | GCP Workload Identity Federation provider |
| `GCP_SA_EMAIL` | No | GCP service account email |

!!! note "GITHUB_TOKEN"
    The `GITHUB_TOKEN` is automatically available and used for GHCR login,
    NuGet publishing, Helm OCI push, and Gitleaks scanning. No configuration needed.

## C/C++ Options

| Input | Default | Description |
|-------|---------|-------------|
| `cpp_compiler` | `gcc` | Compiler: `gcc` or `clang` |
| `cpp_compiler_version` | `13` | Compiler version (GCC 13, Clang 17, etc.) |
| `cpp_standard` | `20` | C++ standard: `14`, `17`, `20`, `23` |
| `cpp_build_type` | `Release` | CMake build type: Release, Debug, RelWithDebInfo |
| `cpp_build_system` | `cmake` | Build system: `cmake`, `meson` |
| `cpp_package_manager` | `conan` | Package manager: `conan`, `vcpkg`, `none` |
| `cpp_conan_remote` | *(empty)* | Custom Conan remote URL |
| `cpp_test_framework` | `ctest` | Test framework: `ctest`, `gtest`, `catch2` |
| `cpp_coverage_enabled` | `true` | Generate gcov/lcov coverage reports |
| `cpp_cross_compile` | *(empty)* | Target triple for cross-compilation |
| `cpp_disabled` | `false` | Disable entire C/C++ pipeline |

## GCP / Registry Options

| Input | Default | Description |
|-------|---------|-------------|
| `package_registry` | `github` | Target registry: `github`, `gcp`, `both` |
| `gcp_project_id` | *(empty)* | GCP project ID (for Artifact Registry) |
| `gcp_region` | `us-central1` | GCP Artifact Registry region |
| `gcp_docker_repo` | `containers` | GCP AR Docker repository name |
| `gcp_maven_repo` | `java-libs` | GCP AR Maven repository name |
| `gcp_npm_repo` | `npm-libs` | GCP AR npm repository name |
| `gcp_python_repo` | `python-libs` | GCP AR Python repository name |
| `gcp_conan_repo` | `cpp-libs` | GCP AR generic/Conan repository name |

## Branch Packaging & Deployment

| Input | Default | Description |
|-------|---------|-------------|
| `package_on_feature` | `false` | Enable packaging on feature branches |
| `package_branches` | `main` | Glob patterns for branches that produce packages |
| `deploy_enabled` | `false` | Master switch for deployment |
| `deploy_branches` | `main` | Branches that trigger deployment |
| `deploy_type` | `none` | Deployment method: `k8s`, `cloud-run`, `ssh`, `none` |

## SSH Deployment

| Input | Default | Description |
|-------|---------|-------------|
| `ssh_host` | *(empty)* | Target hostname for SSH deployment |
| `ssh_user` | `deploy` | SSH username |
| `ssh_port` | `22` | SSH port |
| `ssh_deploy_script` | `deploy/deploy.sh` | Path to deployment script in repo |
| `ssh_deploy_path` | `/opt/app` | Remote deployment directory |
