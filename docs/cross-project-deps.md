# Cross-Project Dependency Management

## Overview

When multiple repositories produce libraries that other repositories consume, you need a **registry-based dependency flow**. Code Haven supports this pattern natively for all supported languages.

## The Pattern

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
     └─────────┘        └────────┘        └────────┘
```

**Producer** repos build and publish packages to a registry.  
**Consumer** repos declare dependencies and fetch them during build.

## Language-Specific Flows

### C/C++ (Conan)

**Producer** (`my-math-lib` repo):

```python
# conanfile.py
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

    def package_info(self):
        self.cpp_info.libs = ["my-math-lib"]
```

Pipeline: `conan create .` → `conan upload` → package lives in remote registry.

**Consumer** (`my-app` repo):

```ini
# conanfile.txt
[requires]
my-math-lib/1.0.0

[generators]
CMakeDeps
CMakeToolchain
```

```cmake
# CMakeLists.txt
find_package(my-math-lib REQUIRED)
target_link_libraries(my-app my-math-lib::my-math-lib)
```

Pipeline: `conan install .` → fetches `my-math-lib/1.0.0` → builds and links.

### Java (Maven)

**Producer** publishes to GitHub Packages or GCP Artifact Registry:

```xml
<!-- pom.xml — producer -->
<distributionManagement>
  <repository>
    <id>github</id>
    <url>https://maven.pkg.github.com/ORG/my-java-lib</url>
  </repository>
</distributionManagement>
```

**Consumer** references it:

```xml
<!-- pom.xml — consumer -->
<dependencies>
  <dependency>
    <groupId>com.example</groupId>
    <artifactId>my-java-lib</artifactId>
    <version>1.0.0</version>
  </dependency>
</dependencies>

<repositories>
  <repository>
    <id>github</id>
    <url>https://maven.pkg.github.com/ORG/my-java-lib</url>
  </repository>
</repositories>
```

### Node.js (npm)

**Producer** publishes to GitHub Packages or GCP AR:

```json
{
  "name": "@org/my-js-lib",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

**Consumer** references it:

```json
{
  "dependencies": {
    "@org/my-js-lib": "^1.0.0"
  }
}
```

With `.npmrc`:
```
@org:registry=https://npm.pkg.github.com
```

### Python (PyPI / GCP AR)

**Producer** publishes wheel/sdist:

```toml
# pyproject.toml
[project]
name = "my-python-lib"
version = "1.0.0"
```

**Consumer** installs:

```
# requirements.txt
my-python-lib==1.0.0 --index-url https://us-python.pkg.dev/PROJECT/REPO/simple/
```

### Go (Git Tags — No Registry!)

Go is unique: no registry needed. Libraries are consumed directly from Git:

```go
// go.mod — consumer
require github.com/org/my-go-lib v1.0.0
```

The producer just tags a release (`v1.0.0`) and consumers `go get` it directly.

### Rust (crates.io / Private Registry)

**Producer** publishes with `cargo publish`.

**Consumer** references it:

```toml
# Cargo.toml
[dependencies]
my-rust-lib = "1.0.0"
```

For private registries, configure in `.cargo/config.toml`:

```toml
[registries.company]
index = "https://your-registry.example.com/index"
```

### .NET (NuGet)

**Producer** publishes:

```xml
<!-- .csproj -->
<PropertyGroup>
  <PackageId>MyDotnetLib</PackageId>
  <Version>1.0.0</Version>
</PropertyGroup>
```

**Consumer** references:

```xml
<PackageReference Include="MyDotnetLib" Version="1.0.0" />
```

With `nuget.config`:
```xml
<packageSources>
  <add key="github" value="https://nuget.pkg.github.com/ORG/index.json" />
</packageSources>
```

## Registry Options

### GitHub Packages

| Format | Supported | URL Pattern |
|--------|-----------|-------------|
| Docker/OCI | ✅ | `ghcr.io/ORG/IMAGE` |
| Maven | ✅ | `https://maven.pkg.github.com/ORG/REPO` |
| npm | ✅ | `https://npm.pkg.github.com` |
| NuGet | ✅ | `https://nuget.pkg.github.com/ORG/index.json` |
| Python | ❌ | Not supported |
| Conan (C++) | ❌ | Not native |

### GCP Artifact Registry

| Format | Supported | URL Pattern |
|--------|-----------|-------------|
| Docker/OCI | ✅ | `REGION-docker.pkg.dev/PROJECT/REPO` |
| Maven | ✅ | `https://REGION-maven.pkg.dev/PROJECT/REPO` |
| npm | ✅ | `https://REGION-npm.pkg.dev/PROJECT/REPO` |
| Python | ✅ | `https://REGION-python.pkg.dev/PROJECT/REPO/simple/` |
| Apt (deb) | ✅ | `https://REGION-apt.pkg.dev/projects/PROJECT` |
| Yum (rpm) | ✅ | `https://REGION-yum.pkg.dev/projects/PROJECT` |
| Generic | ✅ | `https://REGION-generic.pkg.dev/PROJECT/REPO` |

### Other Registries

| Registry | Best For | Conan Native |
|----------|----------|--------------|
| JFrog Artifactory | Enterprise, all formats | ✅ Yes |
| AWS CodeArtifact | Maven, npm, Python | ❌ |
| Azure Artifacts | NuGet, Maven, npm, Python | ❌ |
| Self-hosted Conan | C++ private packages | ✅ Yes |

## Configuration in Code Haven

### Choosing your registry

```yaml
with:
  package_registry: 'github'    # github, gcp, both
  
  # GCP Artifact Registry settings (when using 'gcp' or 'both')
  gcp_project_id: 'my-project'
  gcp_region: 'us-central1'
  gcp_docker_repo: 'containers'
  gcp_maven_repo: 'java-libs'
  gcp_npm_repo: 'npm-libs'
  gcp_python_repo: 'python-libs'
  gcp_conan_repo: 'cpp-libs'
```

### Conan remote configuration

```yaml
with:
  cpp_conan_remote: 'https://my-conan-server.example.com'
secrets:
  CONAN_LOGIN_USERNAME: ${{ secrets.CONAN_USER }}
  CONAN_LOGIN_PASSWORD: ${{ secrets.CONAN_PASS }}
```

## Local Development

The same dependency resolution works locally. Developers configure their package manager once:

=== "C++ (Conan)"

    ```bash
    conan remote add company https://your-conan-remote.example.com
    conan install . --output-folder=build --build=missing
    cmake -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake
    cmake --build build
    ```

=== "Java (Maven)"

    ```bash
    # settings.xml already configured with GitHub Packages credentials
    mvn install
    ```

=== "Node.js (npm)"

    ```bash
    # .npmrc configured with @org:registry
    npm install
    ```

=== "Python (pip)"

    ```bash
    pip install -r requirements.txt --extra-index-url https://REGION-python.pkg.dev/PROJECT/REPO/simple/
    ```

## Version Strategy

| Branch | Package Version | Channel/Tag |
|--------|----------------|-------------|
| `feature/*` | `1.0.0-feature.123` | Pre-release |
| `develop` | `1.0.0-dev.456` | Development |
| `release/*` | `1.0.0-rc.1` | Release candidate |
| `main` | `1.0.0` | Stable |
| `v*` tag | `1.0.0` | Release |

This ensures consumers can pin to stable versions while developers can test pre-release packages from feature branches.

## Dependency Graph

```
math-utils/1.0.0 (C++ library)
  ↓ consumed by
physics-engine/2.1.0 (C++ library)
  ↓ consumed by
game-server/3.0.0 (C++ binary → Docker container)
  ↓ deployed via
Helm chart → Kubernetes cluster
```

Each layer is independently versioned, built, tested, and published through Code Haven.
