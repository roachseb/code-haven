# C/C++

**Workflow:** [`_build-cpp.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-cpp.yml)  
**Triggered by:** `CMakeLists.txt` or `meson.build`

## Overview

The C/C++ workflow provides a complete build, test, lint, format, and package pipeline using industry-standard tools. It supports CMake with Conan 2.x for dependency management.

**Developer responsibility:** `CMakeLists.txt` + `conanfile.txt`/`conanfile.py` + `ci.yml` (4 lines of intent).  
**Code Haven responsibility:** Builder images, tool installation, CI orchestration, registry management.

All tool installation steps are conditional — if running inside a Code Haven builder image or a self-hosted runner with tools pre-installed, install steps are skipped automatically.

## Jobs

| Job | Description | Soft-Fail |
|-----|-------------|-----------|
| `cpp-build` | CMake/Meson configure + build via Conan | No |
| `cpp-test` | CTest / GoogleTest with JUnit XML + coverage (gcov/lcov) | No |
| `cpp-lint` | clang-tidy + cppcheck → SARIF upload | Yes |
| `cpp-format` | clang-format --dry-run style check | Yes |
| `cpp-package` | Conan create + upload to configured remote | No |

## Detection

| Trigger File | Build System |
|-------------|-------------|
| `CMakeLists.txt` | CMake |
| `meson.build` | Meson |
| `conanfile.py` or `conanfile.txt` | Conan dependencies |
| `vcpkg.json` | vcpkg dependencies |

## Configuration

```yaml
jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      # ── C/C++ Intent (the only thing developers configure) ──
      cpp_compiler: 'gcc'             # gcc | clang
      cpp_compiler_version: '13'      # Compiler version to install
      cpp_standard: '20'              # C++ standard: 14, 17, 20, 23
      cpp_build_type: 'Release'       # Release, Debug, RelWithDebInfo
      cpp_conan_remote: ${{ vars.CONAN_REMOTE_URL }}  # Org-level variable
      cpp_coverage_enabled: false     # Enable gcov/lcov coverage
    secrets: inherit
```

The Conan remote URL is typically set as an **org-level variable** (`CONAN_REMOTE_URL`) so developers reference it as `${{ vars.CONAN_REMOTE_URL }}` without knowing the actual URL.

## Builder Images

Code Haven publishes pre-built Docker images to GHCR with all C++ tooling pre-installed:

| Image | Contents |
|-------|----------|
| `ghcr.io/<org>/code-haven/cpp-builder:gcc13` | Ubuntu 24.04 + GCC 13 + CMake + Conan 2.x |
| `ghcr.io/<org>/code-haven/cpp-builder:gcc14` | Ubuntu 24.04 + GCC 14 + CMake + Conan 2.x |
| `ghcr.io/<org>/code-haven/cpp-builder:clang16` | Ubuntu 24.04 + Clang 16 + CMake + Conan 2.x |
| `ghcr.io/<org>/code-haven/cpp-builder:clang18` | Ubuntu 24.04 + Clang 18 + CMake + Conan 2.x |

These images are:
- **Used in CI** — when jobs run in a container, install steps are skipped (tools pre-exist)
- **Used for local dev** — developers reference them in `docker-compose.yml` instead of building their own
- **Built automatically** — the `_build-images.yml` workflow rebuilds on changes to `images/`

The Dockerfile lives in `images/cpp-builder/Dockerfile` and accepts build args:
`COMPILER` (gcc/clang), `COMPILER_VERSION`, `UBUNTU_VERSION`.

## Build Process

### With Conan (recommended)

```
1. conan install . --output-folder=build --build=missing
2. cmake -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake
3. cmake --build build --config Release
4. ctest --test-dir build --output-junit test-results.xml
5. conan create . (package creation)
6. conan upload (publish to remote)
```

### Without Conan (plain CMake)

```
1. cmake -B build -DCMAKE_BUILD_TYPE=Release
2. cmake --build build
3. ctest --test-dir build --output-junit test-results.xml
```

## Static Analysis

### clang-tidy

Runs the LLVM static analyzer with 300+ checks. Configured via `.clang-tidy` at repo root:

```yaml
# .clang-tidy (example)
Checks: >
  -*,
  bugprone-*,
  cert-*,
  clang-analyzer-*,
  cppcoreguidelines-*,
  misc-*,
  modernize-*,
  performance-*,
  readability-*

WarningsAsErrors: ''
HeaderFilterRegex: '(src|include)/.*'
```

Results are uploaded as SARIF to the GitHub Security tab.

### cppcheck

Complementary static analysis tool for undefined behavior, memory leaks, and buffer overflows:

```bash
cppcheck --enable=all --xml --xml-version=2 src/ 2> cppcheck-report.xml
```

## Code Formatting

Uses `clang-format` with a `.clang-format` file at repo root:

```yaml
# .clang-format (example — Google style)
BasedOnStyle: Google
IndentWidth: 4
ColumnLimit: 120
AllowShortFunctionsOnASingleLine: Inline
```

The pipeline runs `clang-format --dry-run --Werror` to check (not modify) formatting.

## Coverage Reports

When `cpp_coverage_enabled: true`:

1. Builds a Debug configuration with `--coverage` flags
2. Runs tests to generate `.gcda` / `.gcno` files
3. Runs `lcov` to generate HTML coverage report
4. Uploads to GitHub Pages at `/cpp/coverage/`

## Package Management: Conan 2.x

### Library producers

Your `conanfile.py` defines the package:

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

### Library consumers

Reference libraries in `conanfile.txt`:

```ini
[requires]
my-lib/1.0.0

[generators]
CMakeDeps
CMakeToolchain
```

Or in `conanfile.py`:

```python
def requirements(self):
    self.requires("my-lib/1.0.0")
```

## Artifacts Produced

| Artifact | Path on Pages | Description |
|----------|--------------|-------------|
| Coverage HTML | `/cpp/coverage/` | lcov HTML report |
| Test Results | JUnit XML | CTest/GoogleTest results |
| SARIF (clang-tidy) | GitHub Security tab | Static analysis findings |
| SARIF (cppcheck) | GitHub Security tab | Supplementary analysis |
| Conan Package | Configured remote | Installable library package |

## Project Structure (Recommended)

```
my-cpp-project/
├── CMakeLists.txt              # Build system
├── conanfile.py                # Package definition + dependencies
├── .clang-format               # Code style rules
├── .clang-tidy                 # Static analysis config
├── .github/workflows/ci.yml   # Uses Code Haven
├── include/
│   └── mylib/
│       └── mylib.h            # Public headers
├── src/
│   ├── main.cpp               # Entry point (binary) or...
│   └── mylib.cpp              # Implementation (library)
└── tests/
    ├── CMakeLists.txt          # Test build config
    └── test_mylib.cpp          # GoogleTest / Catch2 tests
```

## Cross-Compilation (Future)

When `cpp_cross_compile` is set, the pipeline adds a build matrix:

```yaml
strategy:
  matrix:
    include:
      - target: x86_64-linux-gnu
      - target: aarch64-linux-gnu
      - target: x86_64-apple-darwin
```

Each target uses a corresponding Conan profile for cross-compilation.

## Secrets

| Config | Type | Required | Purpose |
|--------|------|----------|---------|
| `CONAN_REMOTE_URL` | Variable (org/repo) | No | Conan package registry URL |
| `CONAN_LOGIN_USERNAME` | Secret | No | Registry authentication |
| `CONAN_PASSWORD` | Secret | No | Registry authentication (password or API key) |
