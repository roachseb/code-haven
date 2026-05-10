# Code Haven — C++ Builder Image

Pre-built Docker images with everything needed to build, test, and package C++ projects with Conan 2.x.

**Developers never need this in their repos.** These images are published by Code Haven and consumed by CI workflows and local development environments automatically.

## Published Images

| Tag | Compiler | Base |
|-----|----------|------|
| `ghcr.io/<org>/code-haven/cpp-builder:gcc13` | GCC 13 | Ubuntu 24.04 |
| `ghcr.io/<org>/code-haven/cpp-builder:gcc14` | GCC 14 | Ubuntu 24.04 |
| `ghcr.io/<org>/code-haven/cpp-builder:clang16` | Clang 16 | Ubuntu 24.04 |
| `ghcr.io/<org>/code-haven/cpp-builder:clang18` | Clang 18 | Ubuntu 24.04 |

All images include: CMake, Ninja, Conan 2.x, ccache, gcovr, lcov, git.

## What's Inside

```
Ubuntu 24.04
├── GCC 13 or Clang 16+         ← Compiler (parameterized)
├── CMake 3.28+                  ← Build system
├── Ninja 1.11+                  ← Build backend
├── Conan 2.x                    ← Package manager (pre-configured profile)
├── ccache                       ← Compilation cache
├── gcovr + lcov                 ← Coverage tools
└── git, curl, pkg-config        ← Utilities
```

## Usage

### In GitHub Actions (via Code Haven workflows)

Developers don't interact with images directly — `_build-cpp.yml` handles everything. If your org publishes these images to GHCR, the CI workflow can use them as containers for faster startup (skipping apt-get/pip installs):

```yaml
# In devsecops.yml, the workflow detects pre-installed tools and skips setup steps.
# No developer action needed.
```

### For Local Development

Reference the published image in a `docker-compose.yml`:

```yaml
services:
  conan:
    image: ghcr.io/<org>/code-haven/cpp-builder:gcc13
    volumes:
      - .:/workspace
      - conan-cache:/root/.conan2
    working_dir: /workspace

volumes:
  conan-cache:
```

Then run commands directly:

```bash
docker compose run --rm conan conan create . --build=missing
docker compose run --rm conan cmake -B build -G Ninja && cmake --build build
```

## Building Locally (for Code Haven maintainers)

```bash
# Default: GCC 13
docker build -t cpp-builder:gcc13 .

# Clang 18
docker build -t cpp-builder:clang18 \
  --build-arg COMPILER=clang \
  --build-arg COMPILER_VERSION=18 .

# GCC 14 on Ubuntu 22.04
docker build -t cpp-builder:gcc14-jammy \
  --build-arg COMPILER_VERSION=14 \
  --build-arg UBUNTU_VERSION=22.04 .
```

## Adding a New Compiler Variant

1. Update the matrix in `.github/workflows/_build-images.yml`
2. Push — images are built and published to GHCR automatically
