# C++ Package

**Action:** [`actions/cpp-package`](https://github.com/code-haven/code-haven/tree/main/actions/cpp-package)

## Overview

The C++ Package composite action handles building, packaging, and uploading C/C++ libraries using Conan 2.x. It automates the full lifecycle:

1. Install Conan
2. Configure profile (compiler, standard, build type)
3. Add and authenticate remote registry
4. Install dependencies
5. Build the package
6. Create the Conan package
7. Upload to remote

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `conan_version` | No | `2` | Conan version to install |
| `conan_remote_url` | No | — | Remote registry URL for upload |
| `conan_remote_name` | No | `code-haven` | Name for the Conan remote |
| `conan_login_username` | No | — | Remote authentication username |
| `conan_login_password` | No | — | Remote authentication password/token |
| `conan_channel` | No | — | Conan channel (stable, testing, etc.) |
| `conan_profile` | No | `default` | Conan build profile |
| `build_policy` | No | `missing` | Build policy: missing, never, always |
| `upload_package` | No | `true` | Whether to upload after building |
| `cmake_build_type` | No | `Release` | CMake build type |
| `compiler` | No | `gcc` | Compiler: gcc or clang |
| `compiler_version` | No | `13` | Compiler version |
| `cpp_standard` | No | `20` | C++ standard: 14, 17, 20, 23 |

## Usage

### Basic library packaging

```yaml
- uses: code-haven/code-haven/actions/cpp-package@main
  with:
    conan_remote_url: ${{ secrets.CONAN_REMOTE_URL }}
    conan_remote_name: company-packages
    conan_login_username: ${{ secrets.CONAN_USER }}
    conan_login_password: ${{ secrets.CONAN_PASS }}
```

### With specific compiler and standard

```yaml
- uses: code-haven/code-haven/actions/cpp-package@main
  with:
    compiler: 'clang'
    compiler_version: '17'
    cpp_standard: '23'
    cmake_build_type: 'RelWithDebInfo'
    conan_remote_url: ${{ secrets.CONAN_REMOTE_URL }}
    conan_login_username: ${{ secrets.CONAN_USER }}
    conan_login_password: ${{ secrets.CONAN_PASS }}
```

### Package without upload (local testing)

```yaml
- uses: code-haven/code-haven/actions/cpp-package@main
  with:
    upload_package: 'false'
    build_policy: 'always'
```

## Prerequisites

Your project needs:

1. **`conanfile.py`** — Defines the package recipe (name, version, build steps)
2. **`CMakeLists.txt`** — CMake build system configuration
3. **Source files** — In `src/` and `include/` directories

## Conan Recipe Template

```python
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout

class MyLibConan(ConanFile):
    name = "my-lib"
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
        self.cpp_info.libs = ["my-lib"]
```

## Registry Options

| Registry | Native Conan | Best For |
|----------|-------------|----------|
| JFrog Artifactory | ✅ | Enterprise teams |
| Self-hosted conan_server | ✅ | Full control |
| GCP Artifact Registry (generic) | Adapter needed | GCP-native teams |
| GitHub Actions Cache | ❌ (temporary) | CI-only caching |

## Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `CONAN_REMOTE_URL` | Yes (for upload) | Conan remote registry URL |
| `CONAN_LOGIN_USERNAME` | Yes (for upload) | Registry authentication username |
| `CONAN_LOGIN_PASSWORD` | Yes (for upload) | Registry authentication password |
