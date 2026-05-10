# GitHub Pages

**Workflow:** [`_pages.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_pages.yml)  
**Runs:** After all other jobs complete (default branch or tag only)  
**Default:** Disabled — opt-in with `pages_disabled: false`

## Enabling Pages

Pages are **disabled by default**. To enable, set `pages_disabled: false` in your workflow call:

```yaml
jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      pages_disabled: false    # Enable GitHub Pages deployment
    secrets: inherit
```

Then in your repository:

1. Go to **Settings → Pages**
2. Set **Source** to **GitHub Actions**
3. Push to your default branch

## What Gets Published

The Pages job aggregates artifacts from ALL build/test/quality jobs and categorizes them:

### API Documentation

| Route | Source | Content |
|-------|--------|---------|
| `/` | MkDocs site or auto-index | Landing portal |
| `/java/apidocs/` | Maven/Gradle Javadoc | Java API reference |
| `/rust/doc/` | rustdoc | Rust API reference |
| `/cpp/docs/` | Doxygen | C++ API reference |

### Code Coverage

| Route | Source | Content |
|-------|--------|---------|
| `/java/jacoco/` | Maven JaCoCo | Java line/branch coverage |
| `/python/coverage/` | pytest + coverage.py | Python coverage HTML |
| `/golang/` | Go coverage | Go test & coverage |
| `/angular/coverage/` | Angular + Karma | Angular component coverage |

### Test Reports

| Route | Source | Content |
|-------|--------|---------|
| `/dotnet/` | .NET TRX results | .NET test output |
| `/php/` | PHPUnit reports | PHP test results |
| `/playwright/` | Playwright HTML report | E2E browser test results |
| `/hurl/` | Hurl HTML report | API integration test results |

### Metrics

| Route | Source | Content |
|-------|--------|---------|
| `/code-metrics/` | SCC report | Lines of code, complexity, language breakdown |

### Frontend Applications

| Route | Source | Content |
|-------|--------|---------|
| `/app/` | npm/Angular build output | Live preview of built frontend |

## Smart Index Page

When no MkDocs site is detected, Code Haven generates a themed portal page that:

- **Auto-detects** which artifact categories were produced
- **Groups** them into logical sections (Docs, Coverage, Tests, Metrics, App)
- **Adapts** to light/dark mode via `prefers-color-scheme`
- **Shows metadata** — branch, commit, and link back to the pipeline run
- **Falls back gracefully** with an empty state if no artifacts exist

### Frontend Projects

For Angular/React/Next.js projects, if the build output contains an `index.html`,
the Pages job deploys it under `/app/` and links it from the portal. This gives
you a live preview of your frontend application alongside all the usual reports.

## How it works

1. Downloads all artifacts from every preceding job
2. Copies them into categorized `public/` subdirectories
3. If a MkDocs site was built, uses it as the root (`/`)
4. If no MkDocs site exists, generates the smart portal index
5. Uploads and deploys to GitHub Pages via `actions/deploy-pages`

!!! note "MkDocs + reports coexistence"
    If your project has a `mkdocs.yml`, Code Haven uses your built MkDocs site
    as the root. Reports are still deployed under their subpaths
    (`/java/jacoco/`, `/python/coverage/`, etc.) and can be linked from your
    MkDocs pages.
