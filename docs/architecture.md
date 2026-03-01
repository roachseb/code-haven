# Architecture

## Design Philosophy

Code Haven follows three principles:

1. **Zero-config by default** — auto-detect everything, build what's there
2. **Modular internals** — each domain (Java, Docker, Security) lives in its own workflow
3. **Single entry point** — consumers call ONE workflow file, period

## How the Pipeline Flows

```
Consumer Repo                          Code Haven Templates
─────────────                          ────────────────────
.github/workflows/ci.yml
  │
  │  uses: devsecops.yml@main
  │
  ▼
┌─────────────────────────────────────────────────────────────┐
│  devsecops.yml  (Orchestrator — ~300 lines)                 │
│                                                             │
│  ┌──────────┐                                               │
│  │  detect   │  Scans repo for pom.xml, Cargo.lock, etc.   │
│  └────┬─────┘                                               │
│       │                                                     │
│       ├── has_pom? ──────► _build-java.yml                  │
│       ├── has_package_json? ► _build-node.yml               │
│       ├── has_python? ───► _build-python.yml                │
│       ├── has_go? ───────► _build-go.yml                    │
│       ├── has_cargo? ────► _build-rust.yml                  │
│       ├── has_dotnet? ───► _build-dotnet.yml                │
│       ├── has_php? ──────► _build-php.yml                   │
│       ├── has_dockerfile? ► _docker.yml                     │
│       ├── has_cypress/pw? ► _test-e2e.yml                   │
│       ├── (always) ──────► _security.yml                    │
│       ├── (always) ──────► _quality.yml                     │
│       ├── has_helm? ─────► _helm.yml                        │
│       └── (after all) ──► _pages.yml                        │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
.github/workflows/
├── devsecops.yml          # 🎯 The entry point (consumers call this)
├── _build-java.yml        # ☕ Maven + Gradle + formatting + Javadoc
├── _build-node.yml        # 📦 npm/yarn/pnpm + Angular
├── _build-python.yml      # 🐍 Python + Django + Tox + MkDocs + PyPI
├── _build-go.yml          # 🐹 Go build/test/lint/fmt/vet
├── _build-rust.yml        # 🦀 Rust build/test/fmt/clippy/doc
├── _build-dotnet.yml      # 🔷 .NET build/test/format/publish
├── _build-php.yml         # 🐘 PHP test + Twig lint
├── _docker.yml            # 🐳 Docker build + Hadolint + Trivy scan
├── _test-e2e.yml          # 🧪 Cypress + Playwright + Hurl
├── _security.yml          # 🛡 CodeQL, Gitleaks, Trivy, KICS, Sonar, Checkmarx
├── _quality.yml           # ✨ CodeClimate + SCC metrics + link check
├── _helm.yml              # ⎈ Helm lint + OCI package push
├── _pages.yml             # 📄 Aggregate reports → GitHub Pages
├── _release.yml           # 🚀 Tag → Release + packaging + registry
└── ci.yml                 # 🐕 Dog-fooding — this repo uses its own pipeline!

actions/
├── toolkit/               # 🔧 Environment init (CA certs, debug, scripts)
├── cloud-login/           # ☁️ AWS / Azure / GCP OIDC authentication
├── k8s-deploy/            # 🚀 Helm deployment with auto-rollback
└── code-quality/          # ✨ CodeClimate config generator
```

## Why Modular?

The original monolith was **~1,500 lines** in a single file. The modular approach:

| Benefit | How |
|---------|-----|
| **Readability** | Each file is 50–130 lines, focused on ONE domain |
| **Maintainability** | Change Java builds without touching security scans |
| **Impact control** | A bug in `_build-rust.yml` won't affect Python builds |
| **Reusability** | Teams can call individual workflows directly if needed |
| **Code review** | PRs touch only the files that matter |
| **Onboarding** | New contributors understand one file at a time |

## Nesting Model

GitHub Actions supports reusable workflow nesting up to 4 levels:

```
Level 1:  Consumer repo calls devsecops.yml
Level 2:  devsecops.yml calls _build-java.yml, _security.yml, etc.
Level 3:  (available if sub-workflows need to call others)
Level 4:  (reserved)
```

We use 2 levels, leaving headroom for future composition.

## Dog-Fooding 🐕

Code Haven uses its own pipeline to build and deploy itself. The repo's
[`ci.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/ci.yml)
calls `devsecops.yml` — the exact same orchestrator every consumer uses.

When the pipeline runs on this repo, the detect step finds `mkdocs.yml` and
triggers the Python sub-workflow (MkDocs build), then security scans (Gitleaks,
CodeQL), quality checks (link check, code metrics), and finally deploys the
documentation site to GitHub Pages.

This is deliberate: the best way to verify a pipeline framework works is to
run it on itself. If Code Haven breaks Code Haven, we know immediately.

```
ci.yml  (push / PR trigger)
  ├── yaml-lint          ← Template-specific
  ├── actionlint         ← Template-specific
  └── pipeline
        └── devsecops.yml  (same orchestrator consumers call)
              ├── detect     → finds mkdocs.yml
              ├── python     → builds docs
              ├── security   → Gitleaks, CodeQL, Trivy, KICS
              ├── quality    → link check, SCC metrics
              └── pages      → deploys to GitHub Pages
```

## Job Dependencies

```
detect ─┬─► java ────────┐
        ├─► node ──┬─────┤
        ├─► python ┤     │
        ├─► go ────┤     ├─► security ──┐
        ├─► rust ──┤     │              │
        ├─► dotnet ┤     │              ├─► pages
        ├─► php ───┘     │              │
        ├─► docker ──────┤              │
        ├─► helm ────────┤              │
        └─► quality ─────┘──────────────┘
                          │
        node ──► e2e ─────┘
```

- **Build jobs** run in parallel after detection
- **Security** waits for all builds (needs their artifacts)
- **E2E tests** wait for Node install (needs `node_modules`)
- **Pages** runs last, collecting all artifacts

## Artifact Flow

All workflows in a run share the same artifact namespace. Artifacts uploaded by
`_build-java.yml` (e.g., `maven-target`) are downloadable by `_security.yml`
(for SonarQube) and `_pages.yml` (for report aggregation).

| Artifact | Produced by | Consumed by |
|----------|-------------|-------------|
| `maven-target` | `_build-java.yml` | `_security.yml`, `_pages.yml` |
| `node-modules` | `_build-node.yml` | `_test-e2e.yml` |
| `python-coverage` | `_build-python.yml` | `_pages.yml` |
| `go-reports` | `_build-go.yml` | `_pages.yml` |
| `rust-doc` | `_build-rust.yml` | `_pages.yml` |
| `scc-report` | `_quality.yml` | `_pages.yml` |
