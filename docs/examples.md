# Examples

Real-world workflow configurations for common scenarios.

## 1. Zero-Config (Auto-detect Everything)

The simplest possible configuration. The pipeline discovers your stack automatically.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'feat/**']
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    secrets: inherit
```

---

## 2. Java (Maven) + Docker + SonarQube

A typical Spring Boot microservice pipeline.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'release/**']
  pull_request:
    branches: [main]
  release:
    types: [published]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      java_version: '21'
      java_distribution: 'temurin'
      maven_build_cmd: 'verify'
      java_formatter: 'spotify'
      sonar_host_url: 'https://sonarqube.example.com'
      sonar_project_key: 'my-spring-boot-app'
      # Disable stacks we don't use
      npm_disabled: true
      python_disabled: true
      golang_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
    secrets: inherit
```

---

## 3. Angular + E2E Tests

A frontend application with Cypress and Playwright.

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
    with:
      node_version: '20'
      cypress_browsers: 'chrome,firefox'
      # Only frontend
      maven_disabled: true
      python_disabled: true
      golang_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
    secrets: inherit
```

---

## 4. Python + Django + Docker + Helm Deploy

A full-stack Python deployment pipeline.

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
    with:
      python_version: '3.12'
      helm_chart_path: 'deploy/helm'
      helm_values_files: 'values.yaml,values-prod.yaml'
      maven_disabled: true
      golang_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
    secrets: inherit
```

---

## 5. Multi-Cloud Go Service

A Go microservice deploying to multiple cloud providers.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      golang_version: '1.22'
      docker_registry: 'ghcr.io'
      maven_disabled: true
      npm_disabled: true
      python_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
    secrets: inherit
```

---

## 6. Rust + Hurl API Tests

A Rust backend with API contract testing.

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
    with:
      rust_toolchain: 'stable'
      hurl_extra_args: '--variable host=http://localhost:8080'
      maven_disabled: true
      npm_disabled: true
      python_disabled: true
      golang_disabled: true
      dotnet_disabled: true
      php_disabled: true
    secrets: inherit
```

---

## 7. .NET + Checkmarx + SQLFluff

An enterprise .NET application with advanced security scanning.

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
    with:
      dotnet_version: '8.0.x'
      checkmarx_base_url: 'https://checkmarx.example.com'
      sqlfluff_dialect: 'tsql'
      sonar_host_url: 'https://sonarqube.example.com'
      maven_disabled: true
      npm_disabled: true
      python_disabled: true
      golang_disabled: true
      rust_disabled: true
      php_disabled: true
    secrets: inherit
```

---

## 8. C++ Library with Conan Publishing

A C++ library that builds, tests, and publishes a Conan package.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      cpp_compiler: 'gcc'
      cpp_compiler_version: '13'
      cpp_standard: '20'
      cpp_coverage_enabled: true
      cpp_conan_remote: ${{ vars.CONAN_REMOTE_URL }}
      maven_disabled: true
      gradle_disabled: true
      npm_disabled: true
      python_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
      golang_disabled: true
    secrets: inherit
```

---

## 9. C++ App with SSH Deployment

A C++ binary deployed to a remote server via SSH.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      cpp_compiler: 'gcc'
      cpp_standard: '20'
      cpp_coverage_enabled: true
      docker_registry: 'ghcr.io'
      maven_disabled: true
      npm_disabled: true
      python_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
      golang_disabled: true
    secrets: inherit
```

---

## 10. Python + GCP Artifact Registry + Cloud Run

Push Docker images to GCP Artifact Registry and deploy to Cloud Run.

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
    with:
      python_version: '3.12'
      docker_registry: 'ghcr.io'
      maven_disabled: true
      npm_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
      golang_disabled: true
    secrets: inherit
```

---

## 11. C++ Consumer App (Cross-Project Dependency)

An application that depends on a Conan library published by another Code Haven project.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      cpp_compiler: 'gcc'
      cpp_standard: '20'
      cpp_conan_remote: ${{ vars.CONAN_REMOTE_URL }}
      docker_registry: 'ghcr.io'
      maven_disabled: true
      npm_disabled: true
      python_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
      golang_disabled: true
    secrets: inherit
```

---

## 12. Quarkus (Red Hat) with Native Build

A Java Quarkus microservice with optional GraalVM native image compilation.
The standard pipeline handles JVM builds via Maven; a separate job builds the native binary.

```yaml title=".github/workflows/ci.yml"
name: CI/CD
on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main]
  release:
    types: [published]

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      java_version: '21'
      maven_build_cmd: 'install'
      java_doc_enabled: true
      docker_registry: 'ghcr.io'
      npm_disabled: true
      python_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
      golang_disabled: true
      cpp_disabled: true
    secrets: inherit

  native:
    needs: ci
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: graalvm/setup-graalvm@v1
        with:
          java-version: '21'
          distribution: 'graalvm-community'
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - run: mvn package -Pnative -DskipTests -B
```

---

## 13. Fullstack Monorepo (React + API)

A monorepo with frontend and backend packages. Uses npm workspaces for unified CI,
then smart change-detection to only rebuild & deploy modified services.

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
    with:
      node_version: '20'
      node_build_args: 'run build'
      node_test_args: 'run test'
      docker_disabled: true      # Per-service Docker below
      maven_disabled: true
      gradle_disabled: true
      python_disabled: true
      rust_disabled: true
      dotnet_disabled: true
      php_disabled: true
      golang_disabled: true
      cpp_disabled: true
    secrets: inherit

  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      api: ${{ steps.check.outputs.api }}
      frontend: ${{ steps.check.outputs.frontend }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - id: check
        run: |
          BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
          if ! git cat-file -e "$BASE" 2>/dev/null; then
            echo "api=true" >> "$GITHUB_OUTPUT"
            echo "frontend=true" >> "$GITHUB_OUTPUT"
            exit 0
          fi
          DIFF=$(git diff --name-only "$BASE" HEAD)
          echo "api=$(echo "$DIFF" | grep -q '^packages/api/' && echo true || echo false)" >> "$GITHUB_OUTPUT"
          echo "frontend=$(echo "$DIFF" | grep -q '^packages/frontend/' && echo true || echo false)" >> "$GITHUB_OUTPUT"

  docker-api:
    needs: [ci, detect-changes]
    if: needs.ci.result == 'success' && needs.detect-changes.outputs.api == 'true'
    # ... build & push packages/api Docker image

  docker-frontend:
    needs: [ci, detect-changes]
    if: needs.ci.result == 'success' && needs.detect-changes.outputs.frontend == 'true'
    # ... build & push packages/frontend Docker image
```

---

## Tips

!!! tip "Disable what you don't need"
    The pipeline will skip detection for disabled stacks, saving runner minutes.

!!! tip "Use `secrets: inherit`"
    This passes all repository secrets to the reusable workflow. Required for
    SonarQube, Checkmarx, Kubernetes, and other integrations.

!!! tip "Branch protection"
    Set up required status checks on your default branch to enforce the pipeline.
