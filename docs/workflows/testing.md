# E2E Testing

**Workflow:** [`_test-e2e.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_test-e2e.yml)  
**Triggered by:** `cypress.config.*` / `playwright.config.*` / `*.hurl`

## Jobs

### Cypress
Multi-browser matrix testing. Automatically downloads `node_modules` from the Node build.
Records videos and screenshots as artifacts.

### Playwright
Full browser testing with HTML + JUnit reports. Installs browser dependencies automatically.

### Hurl
HTTP API testing using `.hurl` files. Generates HTML and JUnit reports.

## Configuration

```yaml
with:
  cypress_browsers: 'chrome,firefox,edge'
  hurl_extra_args: '--variable host=http://localhost:8080'
```
