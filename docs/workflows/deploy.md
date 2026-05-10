# Deploy (Intent-Based)

Code Haven's intent-based deployment lets developers deploy containerized services
**without writing any Terraform**. You declare what you want in a simple `deploy.yml`
file, and Code Haven handles the rest — selecting the right cloud module, generating
Terraform, planning, and applying across environments.

## Philosophy

> Developers declare intent. Code Haven handles infrastructure.

Instead of requiring every team to learn Terraform, understand cloud-specific
resources, and maintain IaC modules, Code Haven provides **pre-built, battle-tested
Terraform modules** that are selected automatically based on your intent.

## Quick Start

### 1. Write your code + Dockerfile (you already do this)

### 2. Add `deploy.yml` to your repo root

```yaml
kind: service
cloud: gcp
runtime: cloud-run
team: platform
port: 8080
expose: private
replicas:
  min: 1
  max: 5
resources:
  cpu: "1"
  memory: 512Mi
health:
  path: /health
env:
  APP_NAME: my-api
```

### 3. Add per-environment overrides

```yaml
# deploy.dev.yml
project_id: myorg-dev-123456
region: northamerica-northeast1
replicas:
  min: 0         # scale-to-zero in dev
  max: 2
resources:
  cpu: "0.5"
  memory: 256Mi
env:
  LOG_LEVEL: debug
```

```yaml
# deploy.prod.yml
project_id: myorg-prod-789012
region: northamerica-northeast1
replicas:
  min: 3
  max: 10
resources:
  cpu: "2"
  memory: 1Gi
```

### 4. Push

That's it. Code Haven auto-detects `deploy.yml` + `Dockerfile`, builds your container,
generates Terraform, and deploys.

## How It Works

```
Developer's Repo              Code Haven
┌─────────────────┐           ┌──────────────────────────┐
│ src/             │           │ modules/                 │
│ Dockerfile       │──build──▶│   gcp/cloud-run/         │
│ deploy.yml       │──intent─▶│   gcp/gke/               │
│ deploy.dev.yml   │           │   gcp/compute/           │
│ deploy.prod.yml  │           │   gcp/cloud-run-job/     │
│                  │           │   aws/ecs/               │
│ .github/         │           │   azure/container-apps/  │
│   workflows/     │           │ actions/deploy-generate/ │
│     ci.yml  ─────┼──calls──▶│ .github/workflows/       │
└─────────────────┘           │   _deploy.yml            │
                              └──────────────────────────┘
```

### Pipeline Flow

1. **Detect** — Code Haven finds `deploy.yml` → sets `has_deploy_intent=true`
2. **Build** — Language-specific build + test (Python, Java, etc.)
3. **Package** — Docker build + push to registry (GHCR by default)
4. **Deploy** — The intent-based deploy workflow:
   - Parses `deploy.yml` + merges `deploy.<env>.yml`
   - Copies the right Terraform module from Code Haven
   - Generates `terraform.auto.tfvars.json` from merged intent
   - Runs `terraform plan` for all environments
   - Applies based on branch gating rules

### Branch Gating

| Trigger | Plan | Apply Dev | Apply Staging | Apply Prod |
|---------|------|-----------|---------------|------------|
| PR / feature branch | ✅ All envs | ❌ | ❌ | ❌ |
| Push to `main` | ✅ All envs | ✅ Auto | ⚙️ If enabled | ❌ |
| Tag (`v*`) | ✅ All envs | ✅ Auto | ✅ Auto | ✅ Approval gate |

## deploy.yml Reference

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `kind` | Service type | `service` |
| `cloud` | Cloud provider | `gcp` |
| `runtime` | Deployment target | `cloud-run` |

### Optional Fields (Base)

| Field | Default | Description |
|-------|---------|-------------|
| `team` | `default` | Team name (used for state isolation + labels) |
| `port` | `8080` | Container port |
| `expose` | `private` | `private` or `public` (default: private — defense posture) |
| `replicas.min` | `1` | Minimum instances (0 = scale-to-zero) |
| `replicas.max` | `5` | Maximum instances |
| `resources.cpu` | `"1"` | CPU allocation |
| `resources.memory` | `"512Mi"` | Memory allocation |
| `health.path` | `/health` | Health check endpoint |
| `timeout` | `300` | Request timeout (seconds) |
| `concurrency` | `80` | Max concurrent requests per instance |
| `service_account` | `""` | GCP SA email for runtime identity |
| `vpc_connector` | `""` | VPC Access connector for private networking |
| `env` | `{}` | Environment variables (non-secret) |

### Per-Environment Files

| Field | Description |
|-------|-------------|
| `project_id` | **Required** — Cloud project ID for this environment |
| `region` | Deployment region |
| Any base field | Overrides the base value for this environment |

Environment files are merged on top of the base using deep merge.
For example, `env` values in `deploy.dev.yml` are merged with (not replacing)
the base `env` values.

## Terraform State

State is stored per cloud provider with automatic path isolation:

| Cloud | Backend | Path |
|-------|---------|------|
| GCP | GCS bucket | `{team}/{service}/{env}` |
| AWS | S3 bucket | `{team}/{service}/{env}/terraform.tfstate` |
| Azure | Storage Account | Container `tfstate`, key `{team}/{service}/{env}/terraform.tfstate` |

The bucket/account name is provided via the `DEPLOY_STATE_BUCKET` organization secret.
Each team's state is isolated by the `team` field in `deploy.yml`.

## Supported Runtimes

| Cloud | Runtime | Kind | Module | Description |
|-------|---------|------|--------|-------------|
| GCP | `cloud-run` | `service` | Cloud Run v2 | Serverless container, auto-scaling, scale-to-zero |
| GCP | `cloud-run` | `worker` | Cloud Run Job | Background job (no ingress, event/manual trigger) |
| GCP | `cloud-run` | `cronjob` | Cloud Run Job + Scheduler | Scheduled task via Cloud Scheduler |
| GCP | `gke` | `service` | GKE (Helm) | Kubernetes deployment with HPA + workload identity |
| GCP | `compute` | `service` | Compute Engine | Container-Optimized OS VM |
| AWS | `ecs` | `service` | ECS Fargate | Serverless containers with ALB + auto-scaling |
| Azure | `container-apps` | `service` | Container Apps | Serverless containers with HTTP scale rules |

### Planned

| Cloud | Runtime | Kind | Description |
|-------|---------|------|-------------|
| AWS | `ec2` | `service` | EC2 instance |
| Azure | `aks` | `service` | AKS deployment via Helm |
| Any | Any | `frontend` | Static site (CDN) |

## deploy.yml Reference

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `kind` | Service type | `service`, `worker`, `cronjob` |
| `cloud` | Cloud provider | `gcp`, `aws`, `azure` |
| `runtime` | Deployment target | `cloud-run`, `gke`, `compute`, `ecs`, `container-apps` |

### Common Fields

| Field | Default | Description |
|-------|---------|-------------|
| `team` | `default` | Team name (state isolation + labels) |
| `port` | `8080` | Container port |
| `expose` | `private` | `private` or `public` |
| `replicas.min` | `1` | Minimum instances |
| `replicas.max` | `5` | Maximum instances |
| `resources.cpu` | `"1"` | CPU allocation |
| `resources.memory` | `"512Mi"` | Memory allocation |
| `health.path` | `/health` | Health check endpoint |
| `env` | `{}` | Environment variables |

### GCP Cloud Run Fields

| Field | Default | Description |
|-------|---------|-------------|
| `timeout` | `300` | Request timeout (seconds) |
| `concurrency` | `80` | Max concurrent requests per instance |
| `service_account` | `""` | GCP SA email for runtime identity |
| `vpc_connector` | `""` | VPC Access connector |

### GCP GKE Fields

| Field | Default | Description |
|-------|---------|-------------|
| `cluster_name` | **Required** | GKE cluster name |
| `namespace` | `default` | Kubernetes namespace |
| `service_account` | `""` | GCP SA email (workload identity) |

### GCP Compute Engine Fields

| Field | Default | Description |
|-------|---------|-------------|
| `machine_type` | `e2-small` | VM machine type |
| `zone` | `""` | Compute zone |
| `network` | `default` | VPC network |
| `subnetwork` | `""` | VPC subnetwork |
| `disk_size_gb` | `10` | Boot disk size |

### GCP Worker / CronJob Fields

| Field | Default | Description |
|-------|---------|-------------|
| `schedule` | `""` | Cron expression (empty = worker, set = cronjob) |
| `schedule_timezone` | `UTC` | Timezone for cron schedule |
| `parallelism` | `1` | Parallel tasks |
| `task_count` | `1` | Total tasks per execution |
| `max_retries` | `3` | Retry count on failure |
| `timeout` | `300` | Task timeout (seconds) |

### AWS ECS Fields

| Field | Default | Description |
|-------|---------|-------------|
| `vpc_id` | **Required** | VPC ID |
| `subnet_ids` | **Required** | List of subnet IDs |
| `execution_role_arn` | `""` | ECS execution IAM role |
| `task_role_arn` | `""` | ECS task IAM role |

> **Note**: CPU for ECS uses Fargate units (256, 512, 1024, 2048, 4096).
> Memory is in MiB.

### Azure Container Apps Fields

| Field | Default | Description |
|-------|---------|-------------|
| `resource_group` | **Required** | Azure resource group |
| `location` | Region fallback | Azure region |
| `managed_environment_id` | `""` | Existing managed environment |
| `log_analytics_workspace_id` | `""` | Existing Log Analytics workspace |

### Per-Environment Files

| Field | Description |
|-------|-------------|
| `project_id` | **Required** — Cloud project ID for this environment |
| `region` | Deployment region |
| Any base field | Overrides the base value for this environment |

## Multi-Service Repos

For repos that contain multiple services (e.g., an API + worker + web frontend),
use the `services` array in `deploy.yml`:

```yaml
team: platform
cloud: gcp
runtime: cloud-run
region: us-central1

services:
  - name: api
    port: 8080
    expose: public
    resources:
      cpu: "1"
      memory: 512Mi
    health:
      path: /api/health
    env:
      SERVICE_ROLE: api

  - name: worker
    kind: worker
    resources:
      cpu: "2"
      memory: 1Gi
    env:
      SERVICE_ROLE: worker

  - name: web
    port: 3000
    expose: public
    resources:
      cpu: "0.5"
      memory: 256Mi
```

Each service gets its own Terraform workspace and is deployed independently.
Services inherit `cloud`, `runtime`, `region`, and other root-level fields
but can override any field at the service level.

Container images are tagged as `{registry}/{org}/{repo}/{service-name}:{tag}`.

## Team IAM

Code Haven provides a Team IAM module (`modules/gcp/team-iam/`) that creates
isolated service accounts per team:

| SA | Purpose | Permissions |
|----|---------|-------------|
| `{team}-deploy` | GitHub Actions (via WIF) | `run.developer`, `iam.serviceAccountUser`, `storage.objectAdmin` |
| `{team}-runtime` | Service identity | Custom roles per team |

The deploy SA is bound to GitHub via Workload Identity Federation, scoped to
specific repository patterns. The deploy SA can impersonate the runtime SA,
creating a clean separation between CI/CD and runtime identities.

## Secrets Setup

### Organization Secrets Required

| Secret | Cloud | Description |
|--------|-------|-------------|
| `DEPLOY_STATE_BUCKET` | All | State backend bucket/account name |
| `DEPLOY_GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP | WIF provider for deployment auth |
| `DEPLOY_GCP_SERVICE_ACCOUNT` | GCP | SA email for running Terraform |
| `DEPLOY_AWS_ROLE_ARN` | AWS | IAM role ARN for OIDC auth |
| `DEPLOY_AWS_REGION` | AWS | AWS region |
| `DEPLOY_AZURE_CLIENT_ID` | Azure | Service principal client ID |
| `DEPLOY_AZURE_TENANT_ID` | Azure | Azure AD tenant ID |
| `DEPLOY_AZURE_SUBSCRIPTION_ID` | Azure | Azure subscription ID |
| `DEPLOY_GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP WIF provider for deployment auth |
| `DEPLOY_GCP_SERVICE_ACCOUNT` | GCP SA email for running Terraform |

> **Note**: Deploy secrets are prefixed with `DEPLOY_*` to separate them from
> the Terraform IaC secrets (`TF_*`). This allows different service accounts
> for custom IaC vs intent-based deployment.

### GCP Prerequisites

1. A GCS bucket for Terraform state
2. Workload Identity Federation configured for GitHub Actions
3. A GCP service account with:
   - `roles/run.developer` (deploy Cloud Run services)
   - `roles/iam.serviceAccountUser` (act as the runtime SA)
   - `roles/storage.objectAdmin` on the state bucket
   - `roles/container.developer` (GKE deployments)
   - `roles/compute.instanceAdmin` (Compute Engine VMs)

### AWS Prerequisites

1. An S3 bucket for Terraform state
2. OIDC identity provider configured for GitHub Actions
3. An IAM role with:
   - ECS, ECR, ALB, CloudWatch, IAM pass-role permissions
   - S3 read/write on the state bucket

### Azure Prerequisites

1. An Azure Storage Account for Terraform state
2. A service principal with:
   - `Contributor` on the resource group
   - `Storage Blob Data Contributor` on the storage account

## CI Configuration

```yaml
# .github/workflows/ci.yml
name: CI/CD
on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:

jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@main
    with:
      deploy_auto_apply_staging: true   # Also auto-deploy staging on main
    secrets: inherit
```

### Available Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `deploy_disabled` | `false` | Disable intent-based deployment |
| `deploy_environments` | `dev,staging,prod` | Comma-separated environment list |
| `deploy_auto_apply_dev` | `true` | Auto-apply dev on main push |
| `deploy_auto_apply_staging` | `false` | Auto-apply staging on main push |
| `deploy_auto_apply_prod` | `false` | Auto-apply prod (always needs tag) |
| `deploy_tf_version` | `1.9` | Terraform version |

## Destroy Policy

> **Destroy is NEVER automated.** Infrastructure teardown must be performed
> manually via your cloud console or by running `terraform destroy`
> manually with appropriate credentials.

This is a deliberate safety decision. Automated destroy in a defense environment
is too risky for a CI/CD pipeline. If you need to tear down a service:

1. Use your cloud console to delete the service
2. Clean up the Terraform state: `terraform state rm <resource>`
3. Or, if authorized, run `terraform destroy` manually

## Team Identity & Isolation

Each team is identified by the `team` field in `deploy.yml`. This creates:

- **State isolation**: `{team}/{service}/{env}` path in the state bucket
- **Labels/Tags**: All resources are labeled with `team=<name>` and `managed-by=code-haven`
- **IAM isolation**: Team IAM module creates dedicated SAs per team
- **Auditability**: Query your cloud provider for all resources belonging to a team

### Setting Up Team IAM (GCP)

Use the `modules/gcp/team-iam` module to create service accounts for a team:

```hcl
module "team_platform" {
  source = "github.com/your-org/code-haven//modules/gcp/team-iam"

  team_name    = "platform"
  project_id   = "myorg-dev-123456"
  github_org   = "your-org"
  github_repos = ["api-service", "web-app"]

  workload_identity_pool_id     = "github-pool"
  workload_identity_provider_id = "github-provider"
  state_bucket                  = "myorg-tf-state"
}
```

## File Location

`deploy.yml` can be placed in either:
- **Root**: `deploy.yml` (recommended)
- **Namespaced**: `.codehaven/deploy.yml`

Per-environment files must be in the same directory as the base file:
- Root: `deploy.dev.yml`, `deploy.staging.yml`, `deploy.prod.yml`
- Namespaced: `.codehaven/deploy.dev.yml`, etc.

## Custom IaC vs Intent-Based

Code Haven supports **both** approaches:

| Approach | When to use | Developer writes |
|----------|-------------|------------------|
| **Intent-based** (`deploy.yml`) | Standard services with common patterns | `deploy.yml` (~15 lines) |
| **Custom IaC** (`*.tf` files) | Complex/unique infrastructure needs | Full Terraform code |

Both can coexist in the same repo. If both `deploy.yml` and `*.tf` files are
detected, both pipelines run independently. The custom IaC pipeline uses
`_build-terraform.yml`, while intent-based uses `_deploy.yml`.

## Example: Complete Repo Structure

```
my-flask-api/
├── .github/
│   └── workflows/
│       └── ci.yml              ← 4 lines of config
├── src/
│   └── app.py                  ← Your code
├── tests/
│   └── test_app.py
├── Dockerfile                  ← Standard container
├── deploy.yml                  ← Intent: "I'm a service on Cloud Run"
├── deploy.dev.yml              ← Dev: project, scaling, debug logging
├── deploy.staging.yml          ← Staging: project, scaling
├── deploy.prod.yml             ← Prod: project, scaling, warn logging
└── requirements.txt
```

**Total infrastructure code written by developer: ~40 lines of YAML.**
**No Terraform. No cloud-specific knowledge. Just intent.**
