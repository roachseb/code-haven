# Code Quality Action

**Path:** `actions/code-quality/action.yml`

Auto-generates a `.codeclimate.yml` configuration based on detected languages in the repository.

## Usage

```yaml
- uses: code-haven/code-haven/actions/code-quality@main
```

## What it detects

| Language | Plugins Enabled |
|----------|----------------|
| Python | pylint, radon, pep8 |
| Go | gofmt, govet, golint |
| Java | pmd, checkstyle |
| JavaScript/TypeScript | eslint, nodesecurity |
| Ruby | rubocop |
| PHP | phpmd, phpcodesniffer |

The **duplication** plugin is always enabled for all detected languages.
