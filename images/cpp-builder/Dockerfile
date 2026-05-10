# ═══════════════════════════════════════════════════════════════
# Code Haven — C++ Builder Image
#
# Pre-built build environment for C++ projects using Conan 2.x.
# Published to GHCR and used by:
#   • GitHub Actions CI (container-based jobs)
#   • Local development (via docker compose)
#   • Self-hosted runners (pre-installed tooling)
#
# Build args:
#   COMPILER         gcc | clang        (default: gcc)
#   COMPILER_VERSION 13, 14, 16, 18...  (default: 13)
#   UBUNTU_VERSION   22.04 | 24.04      (default: 24.04)
#
# Examples:
#   docker build -t cpp-builder:gcc13 .
#   docker build -t cpp-builder:clang18 --build-arg COMPILER=clang --build-arg COMPILER_VERSION=18 .
#
# Published tags:
#   ghcr.io/<org>/code-haven/cpp-builder:gcc13
#   ghcr.io/<org>/code-haven/cpp-builder:gcc14
#   ghcr.io/<org>/code-haven/cpp-builder:clang16
#   ghcr.io/<org>/code-haven/cpp-builder:clang18
# ═══════════════════════════════════════════════════════════════

ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG COMPILER=gcc
ARG COMPILER_VERSION=13

ENV DEBIAN_FRONTEND=noninteractive

# ── Common build tools ──────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        cmake ninja-build make ccache \
        python3 python3-pip python3-venv \
        curl ca-certificates git pkg-config \
        gcovr lcov \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Compiler (GCC or Clang) ────────────────────────────────
RUN apt-get update \
    && if [ "$COMPILER" = "clang" ]; then \
         apt-get install -y --no-install-recommends \
           clang-${COMPILER_VERSION} \
           libc++-${COMPILER_VERSION}-dev \
           libc++abi-${COMPILER_VERSION}-dev \
           lld-${COMPILER_VERSION} \
         && update-alternatives --install /usr/bin/cc  cc  /usr/bin/clang-${COMPILER_VERSION}   100 \
         && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-${COMPILER_VERSION} 100; \
       else \
         apt-get install -y --no-install-recommends \
           gcc-${COMPILER_VERSION} \
           g++-${COMPILER_VERSION} \
         && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${COMPILER_VERSION} 100 \
         && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${COMPILER_VERSION} 100 \
         && update-alternatives --install /usr/bin/cc  cc  /usr/bin/gcc-${COMPILER_VERSION} 100 \
         && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-${COMPILER_VERSION} 100; \
       fi \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Conan 2.x ──────────────────────────────────────────────
RUN pip3 install --break-system-packages conan \
    && conan profile detect --force

# ── Labels ──────────────────────────────────────────────────
LABEL org.opencontainers.image.source="https://github.com/code-haven/code-haven"
LABEL org.opencontainers.image.description="Code Haven C++ Builder — ${COMPILER} ${COMPILER_VERSION}"
LABEL code-haven.compiler="${COMPILER}"
LABEL code-haven.compiler-version="${COMPILER_VERSION}"

WORKDIR /workspace
