# Troubleshooting

Common issues and solutions when using Code Haven.

---

## Pipeline detects nothing

**Symptom:** The Detect job runs but no build jobs are triggered.

**Causes:**

1. **Files not at root** — most detection looks at the repo root only.
   `pom.xml`, `package.json`, `Cargo.lock` must be at the top level.
2. **Stack is disabled** — check for `maven_disabled: true` etc. in your `with:` block.
3. **Wrong file name** — Helm detection looks for `.helmignore` (not `Chart.yaml`).
   PHP detection looks for `phpunit*` files.

**Fix:** Check the [Detection rules](workflows/detect.md) table for the exact
file patterns and search depths.

---

## Permission errors

**Symptom:** Steps fail with `403 Forbidden`, `permission denied`, or
`Resource not accessible by integration`.

**Fix:** Add the permissions block to your workflow:

```yaml
permissions:
  contents: write
  checks: write
  pull-requests: write
  packages: write
  pages: write
  id-token: write
  security-events: write
  actions: read
```

!!! note "Why so many permissions?"
    Each permission maps to a specific feature. If you don't use a feature
    (e.g., Pages), you can remove that permission — but keeping them all
    avoids surprise failures when new features are added.

| Permission | Used by |
|-----------|---------|
| `contents: write` | Checkout, creating releases, tagging |
| `checks: write` | Test result annotations on PRs |
| `pull-requests: write` | PR status comments |
| `packages: write` | Docker push to GHCR, Helm OCI push |
| `pages: write` | GitHub Pages deployment |
| `id-token: write` | OIDC tokens for Pages and cloud auth |
| `security-events: write` | SARIF uploads (CodeQL, Trivy, KICS) |
| `actions: read` | Pages deployment token |

---

## Docker push fails

**Symptom:** Docker build succeeds but push to GHCR fails.

**Common causes:**

1. **Missing `packages: write`** — see permissions section above.
2. **First push from a new repo** — GHCR packages default to private.
   Go to the package settings and make it public, or ensure the org
   allows private packages.
3. **Org restrictions** — some orgs restrict which repos can push packages.
   Check **Organization → Packages → Package creation**.

---

## SonarQube / Checkmarx not running

**Symptom:** Security scans are skipped even though `sonar_host_url` is set.

**Check:**

1. Is the `SONAR_TOKEN` secret configured? (Settings → Secrets → Actions)
2. Is `sonar_disabled: true` set in your `with:` block?
3. Can the runner reach the SonarQube server? (network/firewall issues)

The same applies to Checkmarx — it requires both `checkmarx_base_url` in
`with:` and `CHECKMARX_TOKEN` in secrets.

---

## GitHub Pages not deploying

**Symptom:** Pipeline passes but no Pages site appears.

**Fix:**

1. Pages are **disabled by default**. Add `pages_disabled: false`:
   ```yaml
   with:
     pages_disabled: false
   ```
2. Go to **Settings → Pages → Source** and set it to **GitHub Actions**
3. Pages only deploy on pushes to your default branch (not PRs)

---

## Cloud login fails (OIDC)

**Symptom:** `cloud-login` step fails with authentication errors.

**GCP:**

- Verify your Workload Identity Pool/Provider is configured correctly
- The provider must allow `principalSet://...` matching your repo
- Check that `GCP_WIF_PROVIDER` contains the full resource name:
  `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER`

**AWS:**

- Verify the IAM OIDC identity provider exists with audience `sts.amazonaws.com`
- Check the IAM role trust policy restricts to your repo and branch
- Verify `AWS_ROLE_ARN` is a full ARN: `arn:aws:iam::ACCOUNT:role/ROLE_NAME`

**Azure:**

- Verify federated credentials are configured on the Azure AD app
- Check that issuer is `https://token.actions.githubusercontent.com`
- Ensure `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` are all set

---

## Helm chart not found

**Symptom:** Helm lint or package fails with "chart not found".

**Fix:**

1. Helm detection requires `.helmignore` at the repo root
2. Set `helm_chart_path` if your chart is in a subdirectory:
   ```yaml
   with:
     helm_chart_path: 'deploy/helm'
   ```

---

## C++ build fails — compiler not found

**Symptom:** CMake fails with "could not find compiler".

**Fix:** Verify your `cpp_compiler` and `cpp_compiler_version` match an
available combination. Common values:

| Compiler | Versions |
|----------|----------|
| `gcc` | `11`, `12`, `13`, `14` |
| `clang` | `15`, `16`, `17`, `18` |

---

## Deploy (intent-based) not triggered

**Symptom:** You added a `deploy.yml` but nothing happens.

**Check:**

1. Is the file named exactly `deploy.yml` at the repo root?
2. Does the Detect job show `has_deploy=true`?
3. Are the `DEPLOY_STATE_BUCKET` and cloud auth secrets configured?
4. Infrastructure only deploys on `main` push and tag push (not PRs — PRs only plan)

---

## Slow builds

**Tips to speed up your pipeline:**

1. **Disable unused stacks** — every disabled stack skips detection entirely
2. **Use caching** — Code Haven caches Maven, npm, pip, Go, Rust, and Conan
   dependencies automatically
3. **Split heavy jobs** — for monorepos, consider change detection (see Example 13)
4. **Self-hosted runners** — use `runner: 'self-hosted'` for faster hardware

---

## Debug mode

Enable verbose logging to see what the pipeline is doing:

```yaml
with:
  debug: true
```

This prints environment variables, tool versions, detection results, and
detailed step output. Useful for diagnosing unexpected behavior.

---

## Getting help

1. Check the [Configuration Reference](configuration.md) for all available inputs
2. Review the [Architecture](architecture.md) to understand the pipeline structure
3. Look at [Examples](examples.md) for working configurations
4. Open an issue on the Code Haven repository with your workflow file and error output
