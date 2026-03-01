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
    uses: code-haven/.github/workflows/devsecops.yml@main
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
    uses: code-haven/.github/workflows/devsecops.yml@main
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
    uses: code-haven/.github/workflows/devsecops.yml@main
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
    uses: code-haven/.github/workflows/devsecops.yml@main
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
    uses: code-haven/.github/workflows/devsecops.yml@main
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
    uses: code-haven/.github/workflows/devsecops.yml@main
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
    uses: code-haven/.github/workflows/devsecops.yml@main
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

## Tips

!!! tip "Disable what you don't need"
    The pipeline will skip detection for disabled stacks, saving runner minutes.

!!! tip "Use `secrets: inherit`"
    This passes all repository secrets to the reusable workflow. Required for
    SonarQube, Checkmarx, Kubernetes, and other integrations.

!!! tip "Branch protection"
    Set up required status checks on your default branch to enforce the pipeline.
