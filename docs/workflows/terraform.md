# Terraform / OpenTofu

**Workflow:** [`_build-terraform.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-terraform.yml)  
**Triggered by:** `*.tf` files detected in the repository  
**Supports:** Terraform and OpenTofu (via `tf_tool` input)

## Overview

The Terraform workflow provides a complete infrastructure-as-code pipeline: validate, plan, and conditionally apply — gated by branch and environment.

**Developer responsibility:** `.tf` files + `terraform.tfvars.<env>` + `ci.yml` (6 lines of intent).  
**Code Haven responsibility:** Terraform install, cloud auth, workspace management, plan/apply gating, PR comments, cost estimation.

## Pipeline Flow

```
┌─────────┐   ┌──────────┐   ┌─────────┐   ┌─────────┐   ┌────────┐
│  Init   │──▶│ Validate │──▶│  Plan   │──▶│  Gate   │──▶│ Apply  │
│         │   │ + fmt    │   │ (all    │   │ branch? │   │ (env)  │
│ backend │   │ + tflint │   │  envs)  │   │ manual? │   │        │
│ plugins │   │ + KICS   │   │         │   │         │   │        │
└─────────┘   └──────────┘   └─────────┘   └─────────┘   └────────┘
  Always        Always         Always       Conditional   Conditional
```

## Branch Gating Strategy

| Event | dev | staging | prod |
|-------|-----|---------|------|
| **PR / feature branch** | plan only | plan only | plan only |
| **Push to main** | **auto-apply** | plan (or approval) | plan only |
| **Tag / release** | auto-apply | **auto-apply** | **auto-apply** (or approval) |

This maps to Code Haven's git model:
- `main` = pre-production (safe to apply dev infra)
- `tag` = production stamp (apply everywhere)
- Feature branches = feedback only (never touch real cloud resources)

## Detection

| Trigger File | What it means |
|-------------|---------------|
| `*.tf` | Terraform / HCL configuration |
| `terraform.tfvars.*` | Workspace-based environment separation |
| `backend.tf` | State backend configuration |

## Configuration

```yaml
jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      # ── Terraform Intent ────────────────────────────────
      tf_cloud_provider: 'gcp'          # aws | azure | gcp
      tf_version: '1.9'                 # Terraform version
      tf_tool: 'terraform'              # terraform | tofu (OpenTofu)
      tf_environments: 'dev,staging,prod'
      tf_auto_apply_dev: true           # Auto-apply dev on main
      tf_auto_apply_staging: false      # Require GitHub Environment approval
      tf_infracost_enabled: false       # Show cost estimates on PRs
    secrets: inherit
```

## Repository Structure (Option B — Workspace-Based)

```
my-infra/
├── main.tf                     # Resources (shared config)
├── variables.tf                # Variable declarations
├── outputs.tf                  # Output values
├── backend.tf                  # State backend (GCS, S3, azurerm)
├── versions.tf                 # Required providers + versions
├── terraform.tfvars.dev        # Dev environment values
├── terraform.tfvars.staging    # Staging environment values
├── terraform.tfvars.prod       # Production environment values
└── .github/workflows/
    └── ci.yml                  # 6 lines of intent
```

Each environment uses a **Terraform workspace** and its own var file. Code Haven auto-detects var files in these patterns:
- `terraform.tfvars.<env>`
- `<env>.tfvars`
- `environments/<env>.tfvars`
- `vars/<env>.tfvars`

## Cloud Authentication

Authentication is handled automatically via OIDC — no static credentials needed.

### AWS
```yaml
# Required secrets (set at org/repo level):
TF_AWS_ROLE_ARN: 'arn:aws:iam::123456789:role/terraform-deploy'
TF_AWS_REGION: 'us-east-1'
```
Uses `aws-actions/configure-aws-credentials@v4` with IAM role assumption.

### Azure
```yaml
TF_AZURE_CLIENT_ID: '...'
TF_AZURE_TENANT_ID: '...'
TF_AZURE_SUBSCRIPTION_ID: '...'
```
Uses `azure/login@v2` with service principal.

### GCP
```yaml
TF_GCP_WORKLOAD_IDENTITY_PROVIDER: 'projects/123/locations/global/workloadIdentityPools/...'
TF_GCP_SERVICE_ACCOUNT: 'terraform@my-project.iam.gserviceaccount.com'
```
Uses `google-github-actions/auth@v2` with Workload Identity Federation (keyless).

## PR Comments

On pull requests, Code Haven posts the `terraform plan` output as a PR comment for each environment:

```
### ⚠️ Terraform Plan — `dev`

**Status:** Changes detected
**Tool:** `terraform 1.9`

<details><summary>Show plan output</summary>
  # google_compute_instance.web will be updated
  ~ instance_type = "e2-micro" -> "e2-small"

Plan: 0 to add, 1 to change, 0 to destroy.
</details>
```

## GitHub Environments (Approval Gates)

For `staging` and `prod`, Code Haven uses GitHub's native [deployment environments](https://docs.github.com/en/actions/deployment/targeting-different-environments):

1. Go to **Settings → Environments** in your repo
2. Create environments: `dev`, `staging`, `production`
3. Add required reviewers to `staging` and/or `production`
4. When `tf_auto_apply_staging: true` is set, the apply job targets the `staging` environment — GitHub will hold the workflow until a reviewer approves

This gives you a manual approval gate without any Code Haven configuration.

## Cost Estimation (Infracost)

When `tf_infracost_enabled: true`, the pipeline runs [Infracost](https://www.infracost.io/) on PRs to show the estimated cost impact of infrastructure changes.

Required secret: `INFRACOST_API_KEY` (free tier available at infracost.io)

## Destruction

Terraform `destroy` is **never automated**. It's intentionally excluded from the standard pipeline to prevent accidental infrastructure deletion.

To destroy infrastructure, use the manual workflow dispatch or run locally:

```bash
terraform workspace select dev
terraform destroy -var-file=terraform.tfvars.dev
```

## Security Scanning

KICS (already part of Code Haven's security pipeline) automatically scans all `.tf` files for:
- Unencrypted resources (databases, storage)
- Public exposure (security groups, firewall rules)
- Missing tags and labels
- IAM misconfigurations
- Hardcoded credentials

Results appear in the GitHub Security tab as SARIF findings.

## OpenTofu Support

To use [OpenTofu](https://opentofu.org/) instead of Terraform:

```yaml
with:
  tf_tool: 'tofu'
  tf_version: '1.8'
```

The CLI is nearly identical — all plan/apply/workspace commands work the same.

## Secrets Reference

| Secret | Provider | Purpose |
|--------|----------|---------|
| `TF_AWS_ROLE_ARN` | AWS | IAM role for OIDC federation |
| `TF_AWS_REGION` | AWS | Default region |
| `TF_AZURE_CLIENT_ID` | Azure | Service principal client ID |
| `TF_AZURE_TENANT_ID` | Azure | Azure AD tenant |
| `TF_AZURE_SUBSCRIPTION_ID` | Azure | Subscription for deployments |
| `TF_GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP | WIF provider for keyless auth |
| `TF_GCP_SERVICE_ACCOUNT` | GCP | Service account email |
| `INFRACOST_API_KEY` | — | Cost estimation (optional) |
