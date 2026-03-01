# Migration Guide (GitLab → GitHub)

## Core Differences

| GitLab CI | GitHub Actions |
|-----------|----------------|
| `include: project:` merges YAML | `uses:` calls reusable workflows |
| Hidden jobs (`.template`) with `extends:` | Composite actions |
| `rules: exists: [pom.xml]` | Detection job + conditional `if:` |
| `variables:` | `inputs:` + `env:` |
| `services: [docker:dind]` | Docker pre-installed on runners |
| `artifacts: reports: junit:` | `dorny/test-reporter` |
| `$CI_REGISTRY_IMAGE` | `ghcr.io/${{ github.repository }}` |
| `$CI_COMMIT_SHA` | `${{ github.sha }}` |
| `pages:` job | `actions/deploy-pages` |

## What Changed in the Architecture

On GitLab, Code Haven Farm used `include:` to merge ~37 template files into a consumer pipeline.
Each template was a small, focused file. The consumer's pipeline inherited all jobs automatically.

**GitHub Actions doesn't support YAML merging.** Instead, we use:

1. **One orchestrator workflow** (`devsecops.yml`) that consumers call
2. **13 domain-specific reusable workflows** (prefixed with `_`) for each concern
3. **Composite actions** for reusable step sequences

## Variable Mapping

| GitLab Variable | GitHub Actions Equivalent |
|-----------------|--------------------------|
| `$CI_COMMIT_SHA` | `${{ github.sha }}` |
| `$CI_COMMIT_REF_NAME` | `${{ github.ref_name }}` |
| `$CI_MERGE_REQUEST_ID` | `${{ github.event.pull_request.number }}` |
| `$CI_DEFAULT_BRANCH` | `${{ github.event.repository.default_branch }}` |
| `$CI_PROJECT_PATH` | `${{ github.repository }}` |
| `$CI_JOB_TOKEN` | `${{ secrets.GITHUB_TOKEN }}` |
| `$CI_REGISTRY` | `ghcr.io` |
| `$CI_REGISTRY_IMAGE` | `ghcr.io/${{ github.repository }}` |

For the complete detailed mapping, see [MIGRATION-REPORT.md](https://github.com/code-haven/code-haven/blob/main/MIGRATION-REPORT.md).
