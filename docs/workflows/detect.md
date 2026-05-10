# Stack Detection

**Workflow:** Embedded in `devsecops.yml` (the orchestrator)  
**Runs:** Always — first job in every pipeline run

## How detection works

The `detect` job is the brain of the pipeline. It scans your repository for
known project files and sets boolean output flags. Downstream workflows only
run when their flag is `true`.

```
detect ──► has_pom=true         ──► _build-java.yml
       ──► has_package_json=true ──► _build-node.yml
       ──► has_dockerfile=true   ──► _docker.yml
       ──► has_cargo=true        ──► _build-rust.yml
       ──► ...                   ──► ...
```

!!! tip "Why detection matters"
    Detection is what makes the "zero-config" promise work. You never need
    to tell Code Haven what languages you use — it figures it out by looking
    at your files. If a flag is `false`, that workflow is skipped entirely
    (costs zero runner minutes).

## Detection rules

| Output | Detected by | Search depth |
|--------|-------------|--------------|
| `has_pom` | `pom.xml` | root only |
| `has_gradle` | `build.gradle` or `build.gradle.kts` | root only |
| `has_package_json` | `package.json` | root only |
| `has_angular` | `angular.json` | root only |
| `has_cargo` | `Cargo.lock` | root only |
| `has_go` | any `*.go` file | 4 levels deep |
| `has_python` | `setup.py` or `pyproject.toml` | root only |
| `has_cmake` | `CMakeLists.txt` | root only |
| `has_dotnet` | any `*.sln` or `*.csproj` | 3 levels deep |
| `has_php` | any `*phpunit*` file | 4 levels deep |
| `has_dockerfile` | `Dockerfile` (path configurable) | root only |
| `has_helm` | `.helmignore` | root only |
| `has_mkdocs` | `mkdocs.yml` | 4 levels deep |
| `has_sql` | any `*.sql` file | 4 levels deep |
| `has_hurl` | any `*.hurl` file | 4 levels deep |
| `has_cypress` | `cypress.config.*` | 4 levels deep |
| `has_playwright` | `playwright.config.*` | 4 levels deep |
| `has_tox` | `tox.ini` or `tox.toml` | root only |
| `has_django` | `manage.py` | root only |
| `has_twig` | any `*.twig` file | 4 levels deep |
| `has_deploy` | `deploy.yml` | root only |

!!! note "Search depth"
    "Root only" means the file must be at the repository root. "4 levels deep"
    means the pipeline checks subdirectories up to 4 levels, which handles
    monorepo structures like `packages/api/src/*.go`.

## Package manager detection (Node.js)

When `has_package_json` is `true`, the pipeline also detects which package manager to use:

| Lock file | Manager used | Priority |
|-----------|-------------|----------|
| `pnpm-lock.yaml` | pnpm | 1 (highest) |
| `yarn.lock` | yarn | 2 |
| `package-lock.json` | npm | 3 (default) |

## Overriding detection

You can bypass detection by disabling stacks explicitly:

```yaml
with:
  rust_disabled: true      # Skip even if Cargo.lock exists
  golang_disabled: true    # Skip even if *.go files exist
```

This is useful when you have files from a language you don't want to build
(e.g., vendored Go code, or a Rust tool you build separately).

## Summary Output

The detect job generates a GitHub Step Summary table showing all detection results,
making it easy to verify what was found.
