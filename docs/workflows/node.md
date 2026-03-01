# Node.js / Angular

**Workflow:** [`_build-node.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-node.yml)  
**Triggered by:** `package.json` (Node) + `angular.json` (Angular)

## Jobs

### npm Install
Auto-detects npm/yarn/pnpm and installs dependencies. Uploads `node_modules` artifact for downstream jobs.

### npm Build
Runs `npm run build` (configurable). Skipped if Angular is detected.

### npm Test
Runs `npm run test` (configurable). Skipped if Angular is detected.

### Angular Build
Runs `ng build --configuration production`.

### Angular Test
Runs `ng test` with ChromeHeadless and code coverage.

### Angular Lint
Runs `ng lint`. Soft-fail.

## Configuration

```yaml
with:
  node_version: '20'
  node_build_args: 'run build'
  node_test_args: 'run test:ci'
```

## Package Manager Auto-Detection

| Lock File | Used Manager |
|-----------|-------------|
| `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` |
| `yarn.lock` | `yarn install --frozen-lockfile` |
| `package-lock.json` | `npm ci` |
| *(none)* | `npm install` |
