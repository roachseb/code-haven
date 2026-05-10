# Quality & Metrics

**Workflow:** [`_quality.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_quality.yml)  
**Runs:** Always (parallel to builds)

## Jobs

| Job | Tool | Description |
|-----|------|-------------|
| `code-quality` | CodeClimate | Automated code quality analysis (maintainability, duplication) |
| `code-metrics` | SCC | Lines of code, complexity, language breakdown |
| `links-check` | Lychee | Dead link detection in Markdown and HTML files |
| `hadolint` | Hadolint | Dockerfile best-practice linting (uploads SARIF to Security tab) |
| `actionlint` | Actionlint | GitHub Actions workflow syntax validation |

## CodeClimate

Requires the `CC_TEST_REPORTER_ID` secret. Get it from
**CodeClimate → Repo Settings → Test Coverage → Test Reporter ID**.

Code Haven uses the [`code-quality` composite action](../actions/code-quality.md)
to auto-generate a `.codeclimate.yml` configuration file tailored to your detected
languages. The generated config is placed in the repository root during the CI run
(not committed).

```yaml title="Secret setup"
# Settings → Secrets and variables → Actions
CC_TEST_REPORTER_ID: "your-reporter-id-here"
```

!!! tip "No CodeClimate? No problem"
    If `CC_TEST_REPORTER_ID` is not set, the code-quality job is skipped
    automatically. No error, no noise.

## SCC (Code Metrics)

[SCC](https://github.com/boyter/scc) provides fast, accurate code metrics:

- Lines of code per language
- Cyclomatic complexity
- Estimated cost (COCOMO model)
- Language breakdown

The report is uploaded as an artifact and deployed to the Pages dashboard.

## Lychee (Link Check)

Checks all Markdown and HTML files for broken links. Runs in soft-fail mode —
findings are reported but don't block the pipeline.

## Hadolint

Lints Dockerfiles against [best practice rules](https://github.com/hadolint/hadolint#rules).
Results are uploaded as SARIF to the **Security → Code scanning** tab in your repository.

## Actionlint

Validates GitHub Actions workflow files for syntax errors, type mismatches, and
common mistakes. Only runs when `.github/workflows/*.yml` files exist.
