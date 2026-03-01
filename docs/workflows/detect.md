# Stack Detection

**Workflow:** `_build-*.yml` (embedded in orchestrator)  
**Runs:** Always (first job)

## How Detection Works

The `detect` job is the brain of the pipeline. It runs first, scans the repository for
known project files, and outputs boolean flags that control which downstream workflows launch.

```
detect ──► has_pom=true       ──► Java builds
       ──► has_package_json=true ──► Node builds
       ──► has_dockerfile=true   ──► Docker builds
       ──► ...
```

## Detection Rules

| Output | Detected by | Depth |
|--------|-------------|-------|
| `has_pom` | `pom.xml` exists | root |
| `has_gradle` | `build.gradle` or `build.gradle.kts` | root |
| `has_package_json` | `package.json` exists | root |
| `has_angular` | `angular.json` exists | root |
| `has_cargo` | `Cargo.lock` exists | root |
| `has_go` | any `*.go` file | 4 levels deep |
| `has_python` | `setup.py` or `pyproject.toml` | root |
| `has_dotnet` | any `*.sln` or `*.csproj` | 3 levels deep |
| `has_php` | any `*phpunit*` file | 4 levels deep |
| `has_dockerfile` | `Dockerfile` (configurable) | root |
| `has_helm` | `.helmignore` exists | root |
| `has_mkdocs` | `mkdocs.yml` exists | 4 levels deep |
| `has_sql` | any `*.sql` file | 4 levels deep |
| `has_hurl` | any `*.hurl` file | 4 levels deep |
| `has_cypress` | `cypress.config.*` | 4 levels deep |
| `has_playwright` | `playwright.config.*` | 4 levels deep |
| `has_tox` | `tox.ini` or `tox.toml` | root |
| `has_django` | `manage.py` exists | root |
| `has_twig` | any `*.twig` file | 4 levels deep |

## Package Manager Detection

For Node.js projects, the pipeline also detects the package manager:

| Lock file | Manager |
|-----------|---------|
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| *(default)* | npm |

## Summary Output

The detect job generates a GitHub Step Summary table showing all detection results,
making it easy to verify what was found.
