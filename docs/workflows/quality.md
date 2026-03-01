# Quality & Metrics

**Workflow:** [`_quality.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_quality.yml)  
**Runs:** Always

## Jobs

| Job | Tool | Description |
|-----|------|-------------|
| `code-quality` | CodeClimate | Automated code quality checks (requires `CC_TEST_REPORTER_ID`) |
| `code-metrics` | SCC | Lines of code, complexity, language breakdown (default branch only) |
| `links-check` | Lychee | Dead link detection in Markdown files |
