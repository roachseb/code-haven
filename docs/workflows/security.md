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
