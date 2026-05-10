# E2E Testing

**Workflow:** [`_test-e2e.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_test-e2e.yml)  
**Triggered by:** `cypress.config.*` / `playwright.config.*` / `*.hurl`

!!! note "This is for end-to-end tests only"
    Unit tests are handled by each language's build workflow (pytest, JUnit, go test, etc.).
    This workflow focuses on browser and API integration testing.

## Jobs

### Cypress

Multi-browser matrix testing. The pipeline:

1. Downloads `node_modules` from the Node.js build job (no reinstall)
2. Runs tests in each browser specified by `cypress_browsers`
3. Uploads videos, screenshots, and JUnit reports as artifacts
4. Reports results via `dorny/test-reporter`

```yaml
with:
  cypress_browsers: 'chrome,firefox,edge'
```

### Playwright

Full browser testing with auto-installed dependencies:

1. Installs Playwright browser binaries
2. Runs all test specs
3. Generates HTML report + JUnit XML
4. Uploads trace files on failure for debugging

### Hurl

HTTP API testing using declarative `.hurl` files. Useful for testing REST APIs
without a browser:

1. Finds all `*.hurl` files in the repo
2. Runs them sequentially
3. Generates HTML and JUnit reports

```yaml
with:
  hurl_extra_args: '--variable host=http://localhost:8080 --retry 3'
```

??? example "Sample .hurl file"
    ```hurl title="tests/api/health.hurl"
    GET http://localhost:8080/health
    HTTP 200
    [Asserts]
    jsonpath "$.status" == "UP"

    GET http://localhost:8080/api/users
    HTTP 200
    [Asserts]
    jsonpath "$" count > 0
    ```

## How E2E tests fit in the pipeline

```
detect ──► node build ──► e2e tests (Cypress, Playwright)
       ──► (always)   ──► e2e tests (Hurl — no Node needed)
```

E2E tests wait for the Node.js build to complete so they can reuse
installed dependencies. Hurl tests don't depend on Node and run independently.
