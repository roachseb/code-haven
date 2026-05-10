# Testing Guide

Code Haven ships a **6-layer testing pyramid** that verifies the entire
intent-based deployment pipeline — from YAML validation to Terraform
workspace generation — without cloud credentials or real infrastructure.

!!! info "Zero side effects"
    Every test runs locally. Nothing is deployed, no cloud APIs are called,
    no resources are created.

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| `bash` 4+ | Yes | Ships with macOS/Linux |
| `jq` | Yes | `brew install jq` / `apt install jq` |
| `yq` | Yes | `brew install yq` / [GitHub releases](https://github.com/mikefarah/yq/releases) |
| `terraform` | For layers 4-5 | [terraform.io/install](https://developer.hashicorp.com/terraform/install) |
| `check-jsonschema` | For layer 6 | `pip install check-jsonschema` |

## Quick Start

```bash
cd tests

# Fast: unit + contract tests (no terraform)
make test

# Full: all 6 layers
make test-all

# Simulate one fixture end-to-end
make simulate-one FIXTURE=gcp-cloud-run

# Simulate all fixtures with terraform validate
make simulate-plan
```

## The 6 Layers

### Layer 1 — Routing

**File:** `tests/unit/test-deploy-routing.sh`

Verifies structural integrity:

- [x] Every cloud/runtime has a Terraform module (`main.tf`, `variables.tf`, `outputs.tf`)
- [x] Every module has a matching root template
- [x] `action.yml` routes every supported runtime
- [x] `generate-tfvars.sh` handles every runtime
- [x] Auth steps exist for all clouds
- [x] Test fixtures exist for every runtime

```bash
bash tests/unit/test-deploy-routing.sh
```

??? example "What it catches"
    - New runtime added but not wired in the case statement
    - Template file deleted or renamed
    - Missing auth config for a cloud provider

---

### Layer 2 — Contracts

**File:** `tests/unit/test-contracts.sh`

The deploy system has three layers that must stay aligned:

```
Module variables.tf ──── what Terraform expects
        ↕
Template .tf file   ──── what gets copied into workspace
        ↕
generate-tfvars.sh  ──── what JSON values are produced
```

Contract tests verify:

1. Every template `variable` exists in the module's `variables.tf`
2. Every template `variable` is produced by `generate-tfvars.sh`
3. The JSON Schema covers all runtimes
4. Test fixtures only use fields defined in the schema

```bash
bash tests/unit/test-contracts.sh
```

??? example "What it catches"
    - Variable name typo in one layer (`service_name` vs `serviceName`)
    - New field added to module but not wired in template or tfvars
    - Schema enum missing a new runtime

---

### Layer 3 — TFVars Generation

**File:** `tests/unit/test-generate-tfvars.sh`

Runs `generate-tfvars.sh` with controlled inputs for every
cloud/runtime combo and validates:

- Correct JSON structure
- Proper field names (`labels` for GCP, `tags` for AWS/Azure)
- Environment variable passthrough
- Default values applied
- CronJob schedule fields present

```bash
bash tests/unit/test-generate-tfvars.sh
```

---

### Layer 4 — Terraform Validate

**File:** `tests/integration/test-tf-validate.sh`

For each fixture, assembles a real Terraform workspace (module + template)
and runs:

```bash
terraform init -backend=false   # no state backend needed
terraform validate              # checks HCL syntax + provider config
```

```bash
bash tests/integration/test-tf-validate.sh
```

??? example "What it catches"
    - HCL syntax errors
    - Invalid resource arguments
    - Provider version conflicts
    - Type constraint violations

---

### Layer 5 — Local Simulation

**File:** `tests/local/simulate-deploy.sh`

The most comprehensive test. Replicates the entire `deploy-generate`
action locally:

1. Reads `deploy.yml` from a fixture directory
2. Merges with `deploy.<env>.yml` overrides (same logic as the action)
3. Parses all fields with `yq`
4. Maps `kind` → `runtime` (worker/cronjob → cloud-run-job)
5. Resolves module path + template
6. Copies into a temp workspace
7. Generates `terraform.auto.tfvars.json`
8. Optionally runs `terraform validate`

```bash
# Simulate one fixture
bash tests/local/simulate-deploy.sh tests/fixtures/gcp-cloud-run

# Simulate all fixtures
bash tests/local/simulate-deploy.sh --all

# With terraform validate
bash tests/local/simulate-deploy.sh --all --plan
```

??? example "What it catches"
    Everything from layers 1-4, plus:

    - `yq` expression bugs
    - Environment merge logic errors
    - Kind → runtime mapping mistakes
    - YAML parsing failures on edge cases

---

### Layer 6 — Schema Validation

**File:** `schemas/deploy.schema.json`

Validates `deploy.yml` files against a formal JSON Schema that enforces:

- Required fields (`cloud`, `runtime`)
- Valid enum values for all fields
- Conditional requirements (e.g., ECS requires `vpc_id`)
- Port range (1–65535)
- Team name pattern (`[a-z0-9-]`)

```bash
# Validate a fixture
check-jsonschema --schemafile schemas/deploy.schema.json \
  tests/fixtures/gcp-cloud-run/deploy.yml

# Validate all fixtures
make validate
```

The schema is also used in the CI workflow to validate all examples
and fixtures automatically.

---

## CI Pipeline

Tests run automatically via `.github/workflows/test-deploy.yml` on every
push that touches deploy-related files:

```yaml
on:
  push:
    paths:
      - 'actions/deploy-generate/**'
      - 'modules/**'
      - 'tests/**'
      - 'schemas/**'
```

The CI pipeline runs all 6 layers with parallel Terraform validation
per runtime (matrix strategy).

## Make Targets

| Target | Description |
|--------|-------------|
| `make test` | Routing + TFVars + Contract tests |
| `make test-unit` | Same as `make test` |
| `make test-contract` | Contract alignment only |
| `make simulate` | Simulate all fixtures (no TF) |
| `make simulate-plan` | Simulate all fixtures + TF validate |
| `make simulate-one FIXTURE=name` | Simulate one fixture |
| `make validate` | Schema validation (needs `check-jsonschema`) |
| `make test-all` | All layers |

## Adding a New Runtime

When adding a new cloud/runtime combo, follow this checklist.
The test suite will catch anything you miss:

1. **Module** — Create `modules/{cloud}/{runtime}/` with `main.tf`,
   `variables.tf`, `outputs.tf`, `versions.tf`
2. **Template** — Create `actions/deploy-generate/templates/{cloud}-{runtime}.tf`
3. **Action routing** — Add case in `action.yml` for the new runtime
4. **TFVars generation** — Add case in `generate-tfvars.sh`
5. **Test fixture** — Create `tests/fixtures/{cloud}-{runtime}/deploy.yml`
6. **Schema** — Add runtime to `schemas/deploy.schema.json` enum
7. **Run tests** — `make test-all` — it will catch alignment gaps

## What's NOT Tested Locally

| Aspect | Why | How to verify |
|--------|-----|---------------|
| `terraform apply` | Creates real resources | Deploy to test GCP project |
| Cloud authentication | Needs real credentials | GitHub Actions secrets |
| GitHub Actions runtime | Needs `$GITHUB_*` vars | PR/push triggers |
| Docker builds | Needs Docker daemon | Docker workflow |
| Approval gates | Needs GitHub Environments | Tag-based deploy to prod |

For end-to-end validation, push to a feature branch and watch
the workflow run in GitHub Actions.
