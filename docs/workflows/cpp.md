# C/C++

**Workflow:** [`_build-cpp.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-cpp.yml)  
**Triggered by:** `CMakeLists.txt` or `meson.build`

## Overview

The C/C++ workflow provides a complete build, test, lint, format, and package pipeline using industry-standard tools. It supports CMake and Meson build systems with Conan 2.x for dependency management.

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
with:
  # ── C/C++ Settings ────────────────────────────
  cpp_compiler: 'gcc'             # gcc, clang
  cpp_compiler_version: '13'      # GCC 13, Clang 17, etc.
  cpp_standard: '20'              # C++ standard: 14, 17, 20, 23
  cpp_build_type: 'Release'       # Release, Debug, RelWithDebInfo, MinSizeRel
  cpp_build_system: 'cmake'       # cmake, meson
  cpp_package_manager: 'conan'    # conan, vcpkg, none
  cpp_conan_remote: ''            # Custom Conan remote URL
  cpp_conan_login_username: ''    # Conan remote username (use secrets)
  cpp_test_framework: 'ctest'     # ctest, gtest, catch2
  cpp_coverage_enabled: true      # Generate lcov/gcov coverage
  cpp_cross_compile: ''           # Target triple (e.g., aarch64-linux-gnu)
  cpp_disabled: false             # Disable C/C++ pipeline entirely
```

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

| Secret | Required | Used by |
|--------|----------|---------|
| `CONAN_REMOTE_URL` | No | Conan package upload destination |
| `CONAN_LOGIN_USERNAME` | No | Conan remote authentication |
| `CONAN_LOGIN_PASSWORD` | No | Conan remote authentication |
