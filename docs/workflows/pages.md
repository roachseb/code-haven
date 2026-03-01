# GitHub Pages

**Workflow:** [`_pages.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_pages.yml)  
**Runs:** After all other jobs complete (default branch only)

## What Gets Published

The Pages job aggregates artifacts from ALL build/test/quality jobs:

| Route | Source | Content |
|-------|--------|---------|
| `/` | MkDocs site or auto-index | Landing page |
| `/java/apidocs/` | Maven/Gradle Javadoc | API documentation |
| `/java/jacoco/` | Maven JaCoCo | Java code coverage |
| `/python/coverage/` | pytest coverage HTML | Python code coverage |
| `/golang/` | Go coverage | Go test reports |
| `/rust/doc/` | rustdoc | Rust API documentation |
| `/angular/coverage/` | Angular coverage | Frontend code coverage |
| `/playwright/` | Playwright HTML report | E2E test results |
| `/hurl/` | Hurl HTML report | API test results |
| `/code-metrics/` | SCC report | Lines of code, complexity |

## Setup

1. Go to **Settings → Pages** in your repository
2. Set **Source** to **GitHub Actions**
3. Push to your default branch

## Auto-Generated Index

If no MkDocs site is detected, the job generates a simple HTML index page linking
to all available report directories.
