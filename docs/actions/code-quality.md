# Code Quality Action

**Path:** `actions/code-quality/action.yml`

Auto-generates a `.codeclimate.yml` configuration tailored to the languages
detected in your repository. Used internally by the `_quality.yml` workflow.

## Usage

```yaml
steps:
  - uses: code-haven/code-haven/actions/code-quality@main
```

No inputs needed — the action scans your repo and configures CodeClimate
automatically.

## What it detects

| Language | Plugins Enabled |
|----------|----------------|
| Python | pylint, radon, pep8 |
| Go | gofmt, govet, golint |
| Java | pmd, checkstyle |
| JavaScript / TypeScript | eslint, nodesecurity |
| Ruby | rubocop |
| PHP | phpmd, phpcodesniffer |

The **duplication** plugin is always enabled for all detected languages.

## How it works

1. Scans the repository for language-specific files
2. Generates a `.codeclimate.yml` in the repository root (during CI only — not committed)
3. The CodeClimate CLI uses this config to run quality checks
4. Results are reported via the `CC_TEST_REPORTER_ID` integration

### Generated config example

For a Python + JavaScript project, the action generates:

```yaml title=".codeclimate.yml (auto-generated)"
version: "2"
plugins:
  pylint:
    enabled: true
  radon:
    enabled: true
  pep8:
    enabled: true
  eslint:
    enabled: true
  nodesecurity:
    enabled: true
  duplication:
    enabled: true
    config:
      languages:
        python: {}
        javascript: {}
```

## Prerequisites

Requires the `CC_TEST_REPORTER_ID` secret. To get it:

1. Sign up at [codeclimate.com](https://codeclimate.com)
2. Add your repository
3. Go to **Repo Settings → Test Coverage**
4. Copy the **Test Reporter ID**
5. Add it as a repository secret: `CC_TEST_REPORTER_ID`

If the secret is not configured, the code-quality job is skipped silently.
