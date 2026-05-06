# Code Haven — Project Audit & Expansion Proposal

## Table of Contents

1. [Current State Audit](#1-current-state-audit)
2. [C/C++ Integration Proposal](#2-cc-integration-proposal)
3. [GCP Deployment & Registry Strategy](#3-gcp-deployment--registry-strategy)
4. [SSH Deployment Strategy](#4-ssh-deployment-strategy)
5. [Branch-Based Packaging Strategy](#5-branch-based-packaging-strategy)
6. [Cross-Project Dependency Management](#6-cross-project-dependency-management)
7. [Implementation Roadmap](#7-implementation-roadmap)

---

## 1. Current State Audit

### What's Working Well

| Area | Status | Notes |
|------|--------|-------|
| Auto-detection model | ✅ Excellent | File-based detection is elegant and zero-config |
| Language coverage | ✅ Good | 8 languages + Docker + Helm + E2E |
| Security scanning | ✅ Comprehensive | 10+ scan types, SARIF integration |
| Architecture docs | ✅ Solid | Clear separation, good examples |
| Modular design | ✅ Clean | 50-130 lines per workflow, maintainable |
| Dog-fooding | ✅ Smart | Self-validates the framework |

### Quirks & Issues Found

| # | Issue | Severity | Recommendation |
|---|-------|----------|----------------|
| 1 | **Example 05 uses `cloud: aws`** but action.yml defines `provider: aws` | 🟡 Medium | Fix examples to match action input names |
| 2 | **No monorepo guidance** | 🟡 Medium | Add docs or polyglot detection strategy |
| 3 | **Artifact retention hardcoded** at 1 day | 🟠 Low | Add `artifact_retention_days` input |
| 4 | **No explicit release/packaging workflow** in repo | 🟡 Medium | `_release.yml` is mentioned in architecture diagram but doesn't exist in repo root |
| 5 | **Missing languages: C/C++, Swift, Kotlin (native)** | 🔴 High | C/C++ is a major gap (this proposal addresses it) |
| 6 | **No alternative registry support** (only GHCR) | 🔴 High | Need GCP Artifact Registry, AWS ECR, etc. |
| 7 | **No SSH/bare-metal deployment** | 🟡 Medium | Common for small-to-mid teams |
| 8 | **Branch-level packaging is implicit** — only default branch + tags publish | 🟡 Medium | Needs finer-grained branch strategy |
| 9 | **No cross-project dependency model** | 🔴 High | Libraries can't easily consume sibling repos |
| 10 | **Self-hosted runner section** missing | 🟠 Low | Docker isn't guaranteed on self-hosted |

### Missing Files (Referenced But Don't Exist)

- `_release.yml` — referenced in architecture docs but not in repo
- No `.github/workflows/` directory visible — only actions/ and docs/

---

## 2. C/C++ Integration Proposal

### 2.1 Philosophy

C/C++ projects need:
- **Build systems**: CMake (most common), Meson, Make, Bazel
- **Package management**: Conan 2.x (industry standard, like Maven for C++)
- **Compilers**: GCC, Clang (NOT "Alchemy" — you likely mean **CMake** or **vcpkg**)
- **Cross-compilation**: Target different OS/architectures from Linux runners
- **Static analysis**: clang-tidy, cppcheck, include-what-you-use
- **Formatting**: clang-format
- **Testing**: GoogleTest, Catch2, CTest
- **Packaging**: Conan packages, .deb/.rpm, static/shared libraries (.a/.so/.dll)

> **Note on "Alchemy"**: There isn't a well-known C++ build tool called Alchemy. Your developers may be referring to one of:
> - **CMake** — the de facto standard build system generator
> - **vcpkg** — Microsoft's C++ package manager (similar to Conan)
> - **Meson** — a faster alternative to CMake
> - **Bazel** — Google's polyglot build system
>
> **Recommendation**: Use **CMake + Conan 2.x** as the default. This is the most widely adopted combination and mirrors how Maven/Gradle works for Java.

### 2.2 Detection Rules

| What | Detected By | Depth |
|------|-------------|-------|
| CMake | `CMakeLists.txt` | root |
| Meson | `meson.build` | root |
| Make | `Makefile` (with C/C++ source files) | root |
| Conan | `conanfile.py` or `conanfile.txt` | root |
| vcpkg | `vcpkg.json` | root |

### 2.3 Workflow Design: `_build-cpp.yml`

```yaml
# ═══════════════════════════════════════════════════════════════
# C/C++ Build — CMake + Conan + Testing + Static Analysis
# ═══════════════════════════════════════════════════════════════

# Jobs:
#   cpp-build        — CMake configure + build (Release & Debug)
#   cpp-test         — CTest / GoogleTest with JUnit output
#   cpp-lint         — clang-tidy + cppcheck (soft-fail)
#   cpp-format       — clang-format --dry-run (soft-fail)
#   cpp-package      — Conan create + upload to registry
```

#### Jobs Breakdown

| Job | Tool | Description | Soft-Fail |
|-----|------|-------------|-----------|
| `cpp-build` | CMake + Conan | Configure, resolve deps via Conan, build | No |
| `cpp-test` | CTest / GoogleTest | Run tests, produce JUnit XML + coverage (gcov/lcov) | No |
| `cpp-lint` | clang-tidy, cppcheck | Static analysis → SARIF | Yes |
| `cpp-format` | clang-format | Code style enforcement | Yes |
| `cpp-package` | Conan 2.x | `conan create .` + `conan upload` to registry | No |

### 2.4 Configuration Inputs

```yaml
with:
  # C/C++ Settings
  cpp_compiler: 'gcc'          # gcc, clang
  cpp_compiler_version: '13'   # GCC 13 / Clang 17
  cpp_standard: '20'           # C++ standard (17, 20, 23)
  cpp_build_type: 'Release'    # Release, Debug, RelWithDebInfo
  cpp_build_system: 'cmake'    # cmake, meson, make
  cpp_package_manager: 'conan' # conan, vcpkg, none
  cpp_conan_remote: ''         # Custom Conan remote URL (default: conancenter)
  cpp_test_framework: 'ctest'  # ctest, gtest, catch2
  cpp_cross_compile: ''        # target triple (e.g., aarch64-linux-gnu)
  cpp_disabled: false
```

### 2.5 The Library Workflow (Your Primary Use Case)

```
Project A: my-math-lib (C++ library)
─────────────────────────────────────
conanfile.py defines: name="my-math-lib", version="1.0.0"
CMakeLists.txt builds the library

Pipeline:
  1. detect → finds CMakeLists.txt + conanfile.py
  2. cpp-build → cmake --build (produces .a / .so)
  3. cpp-test → ctest (unit tests)
  4. cpp-lint → clang-tidy
  5. cpp-package → conan create . → conan upload to registry
     ↓
     Package is now at: ghcr.io/org/my-math-lib:1.0.0 (Conan remote)
     or: https://pkg.dev/org/my-math-lib (GCP Artifact Registry)

Project B: my-app (consumes my-math-lib)
────────────────────────────────────────
conanfile.py/txt declares: requires = "my-math-lib/1.0.0"
  
Pipeline:
  1. detect → finds CMakeLists.txt + conanfile.py  
  2. cpp-build → conan install . (fetches my-math-lib from registry)
                 cmake --build (links against my-math-lib)
  3. cpp-test → runs app tests
  4. cpp-package → conan create . (if it's also a library)
     OR docker build (if it's a binary/service)
```

### 2.6 Conan 2.x as the Dependency Backbone

Why Conan:
- **It's the Maven of C++** — handles transitive deps, version resolution, binary compatibility
- **Remote registries**: Works with GitHub Packages, GCP Artifact Registry, JFrog Artifactory, self-hosted
- **Profile system**: Build for Linux/Windows/macOS/ARM from the same recipe
- **GitHub Actions integration**: `conan-io/setup-conan@v1` official action exists
- **Binary caching**: Don't rebuild deps on every CI run

```python
# Example conanfile.py for a library
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout

class MyMathLib(ConanFile):
    name = "my-math-lib"
    version = "1.0.0"
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"
    exports_sources = "CMakeLists.txt", "src/*", "include/*"

    def layout(self):
        cmake_layout(self)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
```

### 2.7 C/C++ Linting & Static Analysis Stack

| Tool | Purpose | Output | Integration |
|------|---------|--------|-------------|
| **clang-tidy** | LLVM static analyzer (checks 300+ patterns) | SARIF → GitHub Security tab | Primary lint |
| **cppcheck** | Complementary static analysis | SARIF | Secondary lint |
| **clang-format** | Code formatting (Google, LLVM, Mozilla styles) | Pass/fail | Format check |
| **include-what-you-use** | Header dependency hygiene | Report | Optional |
| **Valgrind / ASan** | Memory leak detection | Report | Optional (Debug builds) |
| **gcov / lcov** | Code coverage | HTML → Pages | Coverage report |

### 2.8 Cross-Compilation Matrix (Future)

```yaml
strategy:
  matrix:
    include:
      - os: ubuntu-latest
        compiler: gcc-13
        target: x86_64-linux-gnu
      - os: ubuntu-latest
        compiler: gcc-13
        target: aarch64-linux-gnu  # ARM64
      - os: windows-latest
        compiler: msvc
        target: x86_64-windows
      - os: macos-latest
        compiler: clang
        target: x86_64-apple-darwin
```

---

## 3. GCP Deployment & Registry Strategy

### 3.1 GCP Artifact Registry vs GitHub Packages

| Feature | GitHub Packages (GHCR) | GCP Artifact Registry |
|---------|----------------------|----------------------|
| **Container images** | ✅ OCI images | ✅ OCI images |
| **Maven/Gradle** | ✅ (hidden as "packages") | ✅ Maven repository |
| **npm** | ✅ | ✅ npm repository |
| **Python (PyPI)** | ❌ (not supported) | ✅ Python repository |
| **NuGet** | ✅ | ❌ |
| **Conan (C++)** | ❌ (not native) | ✅ Via generic or custom remote |
| **Apt/Yum (deb/rpm)** | ❌ | ✅ Apt & Yum repositories |
| **Generic files** | ❌ | ✅ Generic repository |
| **Format distinction** | ❌ Hidden — all in "packages" tab | ✅ **Separate repos per format** |
| **Vulnerability scanning** | ✅ Dependabot | ✅ Container Analysis (automatic) |
| **Regional** | Global | ✅ Multi-region (us, eu, asia) |
| **IAM** | GitHub permissions | ✅ Fine-grained GCP IAM |

**Key Insight**: GCP Artifact Registry does NOT "cheat" like GitHub — **it creates separate repositories per format type**:
- `us-docker.pkg.dev/my-project/containers/` — Docker images only
- `us-maven.pkg.dev/my-project/java-libs/` — Maven artifacts only
- `us-npm.pkg.dev/my-project/npm-libs/` — npm packages only
- `us-python.pkg.dev/my-project/python-libs/` — Python packages only
- `us-apt.pkg.dev/my-project/deb-packages/` — Debian packages only

This is actually **better** for your use case — you can clearly distinguish what type of package you're dealing with.

### 3.2 Dual Registry Support Design

Add a new input layer for registry routing:

```yaml
with:
  # ── Registry Configuration ────────────────────────
  package_registry: 'github'          # github, gcp, both
  
  # GCP-specific (when package_registry includes 'gcp')
  gcp_project_id: 'my-gcp-project'
  gcp_region: 'us-central1'           # Artifact Registry region
  gcp_docker_repo: 'containers'       # AR Docker repo name
  gcp_maven_repo: 'java-libs'         # AR Maven repo name
  gcp_npm_repo: 'npm-libs'            # AR npm repo name
  gcp_python_repo: 'python-libs'      # AR Python repo name
  gcp_conan_repo: 'cpp-libs'          # AR generic repo (for Conan)
  gcp_apt_repo: 'deb-packages'        # AR apt repo name
```

### 3.3 GCP Deployment Options

#### Option A: GCP Cloud Run (Serverless Containers)
```yaml
# Simplest container deployment — no K8s needed
deploy-cloud-run:
  steps:
    - uses: google-github-actions/auth@v2
    - uses: google-github-actions/deploy-cloudrun@v2
      with:
        service: my-service
        image: ${{ env.IMAGE }}
        region: us-central1
```

#### Option B: GKE (Kubernetes)
```yaml
# Already supported via k8s-deploy action — just need GCP auth first
deploy-gke:
  steps:
    - uses: code-haven/code-haven/actions/cloud-login@main
      with:
        provider: gcp
        gcp_workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
        gcp_service_account: ${{ secrets.GCP_SA_EMAIL }}
    
    - uses: google-github-actions/get-gke-credentials@v2
      with:
        cluster_name: my-cluster
        location: us-central1
    
    - uses: code-haven/code-haven/actions/k8s-deploy@main
      with:
        namespace: my-app
        chart-path: deploy/helm
        image-tag: ${{ github.sha }}
```

#### Option C: GCP Compute Engine (VM via SSH)
See Section 4 — SSH Deployment.

### 3.4 GCP Source Repository Mirroring

GCP Cloud Source Repositories can **mirror GitHub repos automatically**. This is a native GCP feature:

```
GitHub Repo ──(auto-mirror)──► Cloud Source Repositories
                                      │
                                      ├── Triggers Cloud Build (optional)
                                      └── Available for GCP-internal references
```

**Recommendation**: Don't build a custom sync — just document that users can enable GCP's native GitHub mirroring. Code Haven's pipeline stays on GitHub Actions; GCP mirror is for teams that need GCP-internal references.

For teams that genuinely want GCP as their primary CI:
- That's Cloud Build territory, not GitHub Actions
- Out of scope for Code Haven (which is a GitHub Actions framework)
- But we CAN push artifacts/images to GCP registries from GitHub Actions ✅

---

## 4. SSH Deployment Strategy

### 4.1 Use Case

Deploy to bare-metal servers, VMs, or any machine accessible via SSH. Common for:
- Legacy infrastructure
- On-premise machines
- Small VPS deployments (DigitalOcean, Hetzner, etc.)
- GCP Compute Engine instances
- AWS EC2 instances

### 4.2 New Composite Action: `actions/ssh-deploy/`

```yaml
# actions/ssh-deploy/action.yml
name: SSH Deploy
description: >
  Securely connect to a remote machine via SSH and execute a deployment
  script defined in the project repository.

inputs:
  host:
    description: 'Target hostname or IP'
    required: true
  user:
    description: 'SSH username'
    required: true
    default: 'deploy'
  ssh_key:
    description: 'Private SSH key (stored as secret)'
    required: true
  port:
    description: 'SSH port'
    required: false
    default: '22'
  deploy_script:
    description: 'Path to deployment script in repo (relative)'
    required: false
    default: 'deploy/deploy.sh'
  deploy_path:
    description: 'Remote deployment directory'
    required: false
    default: '/opt/app'
  pre_deploy_script:
    description: 'Commands to run before deployment'
    required: false
  artifact_path:
    description: 'Local artifact to transfer (tar.gz, binary, etc.)'
    required: false
  known_hosts:
    description: 'SSH known_hosts content (for host key verification)'
    required: false
  environment_file:
    description: 'Path to .env file to transfer'
    required: false

runs:
  using: composite
  steps:
    - name: Setup SSH
      shell: bash
      run: |
        mkdir -p ~/.ssh
        echo "${{ inputs.ssh_key }}" > ~/.ssh/deploy_key
        chmod 600 ~/.ssh/deploy_key
        
        # Host key verification
        if [ -n "${{ inputs.known_hosts }}" ]; then
          echo "${{ inputs.known_hosts }}" > ~/.ssh/known_hosts
        else
          ssh-keyscan -p ${{ inputs.port }} -H ${{ inputs.host }} >> ~/.ssh/known_hosts
        fi

    - name: Transfer Artifact
      if: inputs.artifact_path != ''
      shell: bash
      run: |
        scp -P ${{ inputs.port }} -i ~/.ssh/deploy_key \
          "${{ inputs.artifact_path }}" \
          "${{ inputs.user }}@${{ inputs.host }}:${{ inputs.deploy_path }}/"

    - name: Transfer Environment File
      if: inputs.environment_file != ''
      shell: bash
      run: |
        scp -P ${{ inputs.port }} -i ~/.ssh/deploy_key \
          "${{ inputs.environment_file }}" \
          "${{ inputs.user }}@${{ inputs.host }}:${{ inputs.deploy_path }}/.env"

    - name: Execute Deployment
      shell: bash
      run: |
        ssh -p ${{ inputs.port }} -i ~/.ssh/deploy_key \
          "${{ inputs.user }}@${{ inputs.host }}" \
          "cd ${{ inputs.deploy_path }} && bash -s" < "${{ inputs.deploy_script }}"

    - name: Cleanup SSH
      if: always()
      shell: bash
      run: rm -f ~/.ssh/deploy_key
```

### 4.3 Project-Defined Deploy Script Pattern

Each project defines its own deployment logic in a predictable location:

```
my-project/
├── deploy/
│   ├── deploy.sh          # Main deployment script
│   ├── rollback.sh        # Rollback script
│   └── health-check.sh    # Post-deploy verification
├── src/
└── ...
```

Example `deploy/deploy.sh`:
```bash
#!/bin/bash
set -euo pipefail

APP_NAME="my-app"
DEPLOY_DIR="/opt/app"

echo "🚀 Deploying $APP_NAME..."

# Stop current service
sudo systemctl stop "$APP_NAME" || true

# Extract new version
tar -xzf "$DEPLOY_DIR/app.tar.gz" -C "$DEPLOY_DIR/"

# Install/update dependencies if needed
cd "$DEPLOY_DIR"
# For a C++ binary — it's already compiled, just copy
cp build/my-app /usr/local/bin/my-app

# Restart service
sudo systemctl start "$APP_NAME"

# Health check
sleep 5
if curl -sf http://localhost:8080/health > /dev/null; then
  echo "✅ Deployment successful"
else
  echo "❌ Health check failed — triggering rollback"
  bash "$DEPLOY_DIR/rollback.sh"
  exit 1
fi
```

### 4.4 Consumer Usage

```yaml
deploy-production:
  needs: ci
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  environment: production
  steps:
    - uses: actions/checkout@v4
    - uses: actions/download-artifact@v4
      with:
        name: build-output
        path: ./dist

    - uses: code-haven/code-haven/actions/ssh-deploy@main
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        user: deploy
        ssh_key: ${{ secrets.DEPLOY_SSH_KEY }}
        deploy_script: deploy/deploy.sh
        artifact_path: ./dist/app.tar.gz
        deploy_path: /opt/my-app
        known_hosts: ${{ secrets.KNOWN_HOSTS }}
```

---

## 5. Branch-Based Packaging Strategy

### 5.1 The Problem

Currently: Only default branch + tags get published. But you want:
- Feature branches → package built (available for testing/integration), but NOT deployed
- Main/develop → package built + optional deployment
- Tags → full release + deployment

### 5.2 Proposed Branch Strategy

```
Branch Type          │ Build │ Test │ Scan │ Package │ Deploy │ Registry
─────────────────────┼───────┼──────┼──────┼─────────┼────────┼──────────
fix/* hotfix/*       │  ✅   │  ✅  │  ✅  │   ❌    │   ❌   │ —
chore/* docs/*       │  ✅   │  ✅  │  ❌  │   ❌    │   ❌   │ —
feature/*            │  ✅   │  ✅  │  ✅  │   ✅    │   ❌   │ :feature-name
develop              │  ✅   │  ✅  │  ✅  │   ✅    │ opt-in │ :develop
release/*            │  ✅   │  ✅  │  ✅  │   ✅    │ opt-in │ :rc-X.Y.Z
main                 │  ✅   │  ✅  │  ✅  │   ✅    │  ✅    │ :latest
tags (v*)            │  ✅   │  ✅  │  ✅  │   ✅    │  ✅    │ :X.Y.Z
```

### 5.3 Configuration

```yaml
with:
  # ── Packaging Strategy ────────────────────────
  package_on_feature: true            # Package feature branches (no deploy)
  package_branches: 'feature/*,develop,release/*,main'  # Which branches get packaged
  deploy_branches: 'main,release/*'   # Which branches trigger deployment
  deploy_enabled: false               # Master switch — override to enable deployment
  deploy_type: 'k8s'                  # k8s, cloud-run, ssh, none
```

### 5.4 How It Works in Practice

```
Developer pushes feature/payment-api:
  1. detect → finds CMakeLists.txt
  2. cpp-build → compiles
  3. cpp-test → runs tests
  4. cpp-package → conan create . 
     → uploads as my-lib/1.0.0@feature-payment-api/latest
     → Docker image tagged: ghcr.io/org/my-app:feature-payment-api
  5. NO deploy (feature branch)

Developer merges to main:
  1. Same build/test/scan cycle
  2. Package → conan upload my-lib/1.0.0@_/_  (stable channel)
     → Docker image tagged: ghcr.io/org/my-app:latest + :sha-abc123
  3. Deploy triggered (if deploy_enabled: true)
```

### 5.5 The "Should it be deployed?" Decision Tree

```
                ┌─────────────────┐
                │ Is deploy_enabled│
                │    = true?       │
                └───────┬─────────┘
                        │
                   No ──┤── Yes
                   │         │
              ┌────▼────┐   ┌▼──────────────────┐
              │ Package  │   │ Is branch in       │
              │ only     │   │ deploy_branches?   │
              └──────────┘   └───────┬────────────┘
                                     │
                                No ──┤── Yes
                                │         │
                           ┌────▼────┐   ┌▼──────────────┐
                           │ Package  │   │ Run deploy_type│
                           │ only     │   │ (k8s/ssh/etc.) │
                           └──────────┘   └────────────────┘
```

---

## 6. Cross-Project Dependency Management

### 6.1 The Problem Statement

You have:
- **Repo A**: C++ library (e.g., `math-utils`)
- **Repo B**: C++ application that depends on `math-utils`
- Both use Code Haven pipelines
- You need Repo B to easily reference and consume Repo A's output

### 6.2 Solution: Registry-Based Dependency Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    REGISTRY (Source of Truth)                     │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Conan Remote  │  │ Docker/OCI   │  │ Maven/npm    │          │
│  │ (C++ libs)    │  │ (containers) │  │ (JVM/JS)     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
     ┌────┴────┐        ┌───┴────┐        ┌───┴────┐
     │ Repo A  │        │ Repo C │        │ Repo D │
     │ (lib)   │        │ (svc)  │        │ (svc)  │
     └────┬────┘        └───┬────┘        └───┬────┘
          │                  │                  │
          │   produces       │  consumes        │  consumes
          ▼                  ▼                  ▼
   math-utils/1.0.0    needs math-utils    needs math-utils
   → uploaded to        → conan install     → conan install
     registry             fetches it          fetches it
```

### 6.3 C++ Specific: Conan Registry Options

| Option | Where to Host | Pros | Cons |
|--------|--------------|------|------|
| **GitHub Packages** | `ghcr.io` + Conan remote | Free for public, integrated | Conan support is via custom server |
| **GCP Artifact Registry** | `us-python.pkg.dev` (generic) | Native GCP, IAM | Not a native Conan remote |
| **JFrog Artifactory (Cloud)** | `*.jfrog.io` | Native Conan support, free tier | External service |
| **Conan Center** | `conancenter` | Public packages | Only for open-source |
| **Self-hosted conan_server** | Your infra | Full control | Maintenance burden |
| **GitHub Actions Cache** | Workflow cache | Fast, free | Non-persistent, not a registry |

**Recommended approach for your case**:

1. **For private C++ libraries**: Use **JFrog Artifactory Cloud** (free tier: 2GB) or a self-hosted Conan server. GCP Artifact Registry's "generic" format can also work with a custom Conan remote adapter.

2. **For containerized outputs**: Continue with GHCR or GCP Artifact Registry (Docker format).

3. **For public libraries**: Use Conan Center (open-source contribution model).

### 6.4 How Repo B Finds Repo A's Library

**In `conanfile.py` or `conanfile.txt`:**
```ini
# conanfile.txt (simple consumer)
[requires]
math-utils/1.0.0

[generators]
CMakeDeps
CMakeToolchain
```

**In CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.20)
project(my-app)

find_package(math-utils REQUIRED)

add_executable(my-app src/main.cpp)
target_link_libraries(my-app math-utils::math-utils)
```

**Pipeline automatically**:
1. `conan install .` → resolves `math-utils/1.0.0` from configured remote
2. Downloads pre-built binary (or builds from source if binary not available for that config)
3. CMake finds it via generated `Find*.cmake` files
4. Build links against it

### 6.5 Local Development Experience

For local development, developers just:
```bash
# Configure Conan remote once
conan remote add code-haven https://your-registry.example.com

# Install deps and build (same as CI does)
conan install . --output-folder=build --build=missing
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .
```

This is the same flow whether running locally or in CI — **consistent and reproducible**.

### 6.6 Multi-Language Dependency Map

| Producer Language | Package Format | Registry | Consumer Fetches Via |
|-------------------|---------------|----------|---------------------|
| C/C++ library | Conan package | Conan remote | `conan install` |
| C/C++ binary | Docker image / tar.gz | GHCR / AR | `docker pull` / download |
| Java library | Maven artifact (.jar) | GitHub Packages / AR Maven | `pom.xml` dependency |
| Node library | npm package | GitHub Packages / AR npm | `package.json` |
| Python library | wheel/sdist | PyPI / AR Python | `pip install` |
| Go library | Go module | Git tag (no registry needed) | `go get` |
| Rust library | crate | crates.io / private registry | `Cargo.toml` |
| .NET library | NuGet package | GitHub Packages / nuget.org | `*.csproj` PackageReference |

---

## 7. Implementation Roadmap

### Phase 1: C/C++ Foundation (Priority: HIGH)

```
Files to Create:
├── .github/workflows/_build-cpp.yml       # C/C++ build workflow
├── actions/cpp-package/action.yml         # Conan package + upload composite action
├── docs/workflows/cpp.md                  # Documentation
└── examples/08-cpp-conan-lib.yml          # Example: C++ library with Conan
```

**Detection additions to `devsecops.yml`:**
- Add `has_cmake` output (detects `CMakeLists.txt`)
- Add `has_conan` output (detects `conanfile.py` or `conanfile.txt`)
- Add `cpp_disabled` toggle

### Phase 2: Registry Expansion (Priority: HIGH)

```
Files to Modify/Create:
├── actions/cloud-login/action.yml         # Add GCP Artifact Registry auth
├── docs/configuration.md                  # Add registry config section
└── docs/workflows/docker.md              # Add GCP AR push option
```

**New inputs on orchestrator:**
- `package_registry`: `github` | `gcp` | `both`
- `gcp_project_id`, `gcp_region`, `gcp_*_repo`

### Phase 3: SSH Deployment (Priority: MEDIUM)

```
Files to Create:
├── actions/ssh-deploy/action.yml          # SSH deployment composite action
├── docs/actions/ssh-deploy.md             # Documentation
└── examples/09-cpp-ssh-deploy.yml         # Example: Build C++ → deploy via SSH
```

### Phase 4: Branch-Based Packaging (Priority: MEDIUM)

```
Files to Modify:
├── .github/workflows/devsecops.yml        # Add branch-level logic
└── docs/configuration.md                  # Document new toggle
```

**New inputs:**
- `package_on_feature`, `package_branches`, `deploy_branches`, `deploy_enabled`, `deploy_type`

### Phase 5: Cross-Project Dependencies (Priority: HIGH — completes C++ story)

```
Files to Create:
├── docs/cross-project-deps.md             # Guide: consuming libraries across repos  
├── examples/08b-cpp-consumer-app.yml      # Example: app consuming a Conan library
└── docs/workflows/cpp.md                  # Extended with library consumption section
```

---

## Summary Table: What Gets Added

| Component | Type | Status |
|-----------|------|--------|
| `_build-cpp.yml` | Workflow | **NEW** |
| `actions/ssh-deploy/` | Composite Action | **NEW** |
| `actions/cpp-package/` | Composite Action | **NEW** |
| `actions/cloud-login/` | Composite Action | MODIFY (add AR Docker auth) |
| `devsecops.yml` | Orchestrator | MODIFY (add C++ detection + branch logic) |
| `docs/workflows/cpp.md` | Docs | **NEW** |
| `docs/actions/ssh-deploy.md` | Docs | **NEW** |
| `docs/cross-project-deps.md` | Docs | **NEW** |
| `examples/08-cpp-conan-lib.yml` | Example | **NEW** |
| `examples/09-cpp-ssh-deploy.yml` | Example | **NEW** |
| `examples/10-gcp-artifact-registry.yml` | Example | **NEW** |
| Configuration reference | Docs | MODIFY (new inputs) |

---

## Appendix A: GCP Artifact Registry — Format Comparison

```
┌────────────────────────────────────────────────────────────────┐
│                GitHub Packages (current)                         │
│                                                                  │
│  ┌──────────────────────────────────────┐                       │
│  │    "Packages" Tab (all mixed)         │                      │
│  │    • Docker images                    │  ← All look the same │
│  │    • Maven JARs                       │  ← from outside      │
│  │    • npm packages                     │                       │
│  │    • NuGet packages                   │                       │
│  └──────────────────────────────────────┘                       │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│            GCP Artifact Registry (proposed addition)             │
│                                                                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │ Docker  │ │ Maven   │ │ npm     │ │ Python  │ │ Apt/Yum │ │
│  │ Repo    │ │ Repo    │ │ Repo    │ │ Repo    │ │ Repo    │ │
│  │         │ │         │ │         │ │         │ │         │ │
│  │ images  │ │ .jar    │ │ .tgz   │ │ wheels  │ │ .deb    │ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ │
│       ↑ Clearly separated by format type                        │
└────────────────────────────────────────────────────────────────┘
```

**Answer to your question**: GCP does NOT cheat like GitHub. Each format gets its own clearly separated repository. This is better for knowing exactly what type of artifact you're dealing with.

---

## Appendix B: Recommended C++ Project Template

For teams starting a new C++ project with Code Haven:

```
my-cpp-project/
├── CMakeLists.txt              # Build system
├── conanfile.py                # Package definition + dependencies
├── .clang-format               # Formatting rules
├── .clang-tidy                 # Linting rules
├── .github/
│   └── workflows/
│       └── ci.yml              # uses: code-haven/devsecops.yml@main
├── deploy/
│   ├── deploy.sh              # SSH deployment script (optional)
│   ├── Dockerfile             # Container packaging (optional)
│   └── helm/                  # K8s deployment (optional)
├── include/
│   └── mylib/
│       └── mylib.h            # Public headers (if library)
├── src/
│   ├── main.cpp               # Entry point (if binary)
│   └── mylib.cpp              # Implementation
├── tests/
│   ├── CMakeLists.txt
│   └── test_mylib.cpp         # GoogleTest tests
└── README.md
```

---

## Appendix C: "Alchemy" Clarification

After research, the tool your developers may be referring to could be:

1. **CMake** — The most likely candidate. It "generates" build files for different platforms (Makefiles on Linux, Visual Studio projects on Windows, Xcode on macOS). It's the de facto standard.

2. **Meson** — A newer, faster build system. Python-based configuration.

3. **Bazel** — Google's build system. Hermetic, reproducible, but complex.

4. **vcpkg** — Microsoft's C++ package manager (alternative to Conan).

5. **Emscripten** — Compiles C/C++ to WebAssembly (for browser targets).

6. **Zig CC** — Using Zig as a cross-compiler for C/C++ (gaining popularity for its ease of cross-compilation).

**If they literally mean cross-compiling to different OS targets**, the best options in CI are:
- **CMake + Conan profiles** — Different profiles per target OS/arch
- **Zig CC as a drop-in cross-compiler** — `CC="zig cc" CXX="zig c++"` compiles to any target from Linux
- **Docker multiplatform builds** — QEMU emulation for ARM, etc.

**Recommendation**: Start with CMake + GCC/Clang as the standard. Add cross-compilation as a future matrix option. If "Alchemy" is a proprietary/internal tool, we can adapt the pipeline to call it as a custom build step.
