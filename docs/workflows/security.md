# Security Scanning

**Workflow:** [`_security.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_security.yml)  
**Runs:** Always (after builds complete)

## Jobs

| Job | Tool | SARIF Upload | Description |
|-----|------|-------------|-------------|
| `sast` | CodeQL | ✅ | Static Application Security Testing — auto-detects languages |
| `secret-detection` | Gitleaks | — | Scans git history for leaked secrets, tokens, passwords |
| `dependency-scan` | Trivy FS | ✅ | Filesystem scan for vulnerable dependencies |
| `iac-scan` | KICS | ✅ | Infrastructure-as-Code scan (Terraform, K8s, Docker, etc.) |
| `sonarqube` | SonarQube | — | Code quality + security (requires `sonar_host_url`) |
| `checkmarx` | CxFlow | — | Enterprise SAST (requires `checkmarx_base_url`) |
| `sqlfluff` | SQLFluff | — | SQL linting with configurable dialect |
| `semgrep` | Semgrep | ✅ | Open-source SAST with community rules (`auto` config) |
| `osv-scanner` | OSV Scanner | — | Google's vulnerability database — checks all ecosystems |
| `license-check` | pip-licenses / license-checker | — | License compliance (flags copyleft licenses like GPL) |
| `scorecard` | OSSF Scorecard | ✅ | Supply chain security assessment (OpenSSF) |

## SARIF Integration

Jobs that upload SARIF results integrate with GitHub's **Security** tab. Findings appear in:

- **Code scanning alerts** — visible in the Security tab
- **Pull request annotations** — inline comments on vulnerable code

## Configuration

```yaml
with:
  sonar_host_url: 'https://sonarqube.example.com'
  sonar_project_key: 'my-project'
  checkmarx_base_url: 'https://checkmarx.example.com'
  sqlfluff_dialect: 'postgres'
```

Required secrets:

```yaml
secrets:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  CHECKMARX_TOKEN: ${{ secrets.CHECKMARX_TOKEN }}
  CHECKMARX_USERNAME: ${{ secrets.CHECKMARX_USERNAME }}
  CHECKMARX_PASSWORD: ${{ secrets.CHECKMARX_PASSWORD }}
```

## Disabling Individual Scanners

Each scanner can be independently toggled:

```yaml
with:
  sast_disabled: true                # Disable CodeQL
  secret_detection_disabled: true    # Disable Gitleaks
  dependency_scan_disabled: true     # Disable Trivy FS
  iac_scan_disabled: true            # Disable KICS
  sonar_disabled: true               # Disable SonarQube
  checkmarx_disabled: true           # Disable Checkmarx
  sqlfluff_disabled: true            # Disable SQLFluff
  semgrep_disabled: true             # Disable Semgrep
  osv_disabled: true                 # Disable OSV Scanner
  license_check_disabled: true       # Disable license compliance
  scorecard_disabled: true           # Disable OSSF Scorecard
```
