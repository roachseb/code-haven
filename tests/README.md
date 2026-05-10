# Code Haven — Testing Guide

## Testing Strategy

Code Haven uses a **6-layer testing pyramid** to validate the entire
intent-based deployment system — from schema validation to Terraform
workspace generation — without requiring cloud credentials or
infrastructure.

```
        ╭────────────────────╮
        │  Layer 6: Schema   │  deploy.yml valid against JSON Schema?
        ├────────────────────┤
        │  Layer 5: Simulate │  Full fixture → workspace → validate
        ├────────────────────┤
        │  Layer 4: TF Valid │  terraform validate on generated code
        ├────────────────────┤
        │  Layer 3: TFVars   │  Correct JSON output per cloud/runtime?
        ├────────────────────┤
        │  Layer 2: Contract │  Module vars ↔ Template vars ↔ JSON
        ├────────────────────┤
        │  Layer 1: Routing  │  All modules/templates/routes exist?
        ╰────────────────────╯
```

**No cloud credentials needed. No infrastructure created. All tests
run locally or in CI with zero side effects.**

## Quick Start

### Prerequisites

```bash
# macOS
brew install jq yq terraform

# Ubuntu/Debian
sudo apt-get install jq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Terraform — https://developer.hashicorp.com/terraform/install
```

### Run Tests

```bash
# From repo root:
cd tests

# Fast: unit + contract tests (no terraform needed)
make test

# Full: all layers including terraform validate
make test-all

# Simulate a single fixture
make simulate-one FIXTURE=gcp-cloud-run

# Simulate all fixtures with terraform validate
make simulate-plan
```

### Or without Make

```bash
# Unit tests
bash tests/unit/test-deploy-routing.sh
bash tests/unit/test-generate-tfvars.sh
bash tests/unit/test-contracts.sh

# Local simulation
bash tests/local/simulate-deploy.sh tests/fixtures/gcp-cloud-run --plan
bash tests/local/simulate-deploy.sh --all --plan

# Integration
bash tests/integration/test-tf-validate.sh
```

## Test Layers Explained

### Layer 1: Routing (`test-deploy-routing.sh`)

Verifies the structural integrity of the deploy system:

- Every supported cloud/runtime has a Terraform module directory
  with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- Every module has a matching root template in `templates/`
- The `action.yml` case statement routes to every supported runtime
- The `generate-tfvars.sh` case statement handles every runtime
- The `_deploy.yml` workflow validates every runtime
- Auth steps exist for all clouds (GCP, AWS, Azure)
- Test fixtures exist for every runtime

**Catches: new runtime added without wiring, deleted files, broken routes**

### Layer 2: Contracts (`test-contracts.sh`)

Verifies alignment between the three layers that must agree:

```
Module variables.tf ─── declares what TF expects
        ↕
Template root .tf   ─── declares what gets passed to module
        ↕
generate-tfvars.sh  ─── produces the JSON that fills vars
```

Contract tests verify:
1. Every template variable exists in the module's `variables.tf`
2. Every template variable is produced by `generate-tfvars.sh`
3. The JSON Schema file is valid and covers all runtimes
4. Test fixtures only use fields defined in the schema

**Catches: var name typo in one layer, missing field after refactor,
schema drift**

### Layer 3: TFVars Generation (`test-generate-tfvars.sh`)

Runs `generate-tfvars.sh` with controlled inputs for each
cloud/runtime and asserts the JSON output has correct:

- Field names and types
- Correct label/tag naming (GCP uses `labels`, AWS/Azure use `tags`)
- Environment variable passthrough
- Default values
- CronJob schedule fields

**Catches: jq errors, wrong field names, type mismatches, missing
env var exports**

### Layer 4: Terraform Validate (`test-tf-validate.sh`)

For each fixture, copies the module + template into a temp directory
and runs `terraform init -backend=false` + `terraform validate`.

This catches Terraform syntax errors, provider version issues, and
resource configuration mistakes — all without cloud credentials.

**Catches: HCL syntax errors, invalid resource arguments, provider
version conflicts**

### Layer 5: Local Simulation (`simulate-deploy.sh`)

The most comprehensive local test. For each fixture:

1. Finds `deploy.yml`
2. Merges with `deploy.<env>.yml` override (exactly like the action)
3. Parses all fields with `yq`
4. Maps kind → runtime (worker/cronjob → cloud-run-job)
5. Resolves module + template
6. Copies into a temp workspace
7. Generates `terraform.auto.tfvars.json`
8. Validates JSON is parseable
9. Optionally runs `terraform validate`

This is the closest you can get to testing the deploy-generate action
without GitHub Actions.

**Catches: everything layers 1-4 catch, plus: YAML parsing errors,
yq expression bugs, environment merge logic, kind→runtime mapping**

### Layer 6: JSON Schema Validation

Validates `deploy.yml` files (fixtures and examples) against
`schemas/deploy.schema.json`. The schema enforces:

- Required fields (`cloud`, `runtime`)
- Valid enum values (`gcp|aws|azure`, `service|worker|cronjob`)
- Conditional requirements (e.g., `ecs` requires `vpc_id`)
- Team name pattern (`[a-z0-9-]`)
- Port range (1-65535)
- No unknown fields (`additionalProperties: false`)

**Catches: typos in field names, invalid values, missing required
fields, schema drift**

## CI Pipeline

The test suite runs automatically in GitHub Actions on every push
to files in `actions/deploy-generate/`, `modules/`, `tests/`, or
`schemas/`. See `.github/workflows/test-deploy.yml`.

CI runs all 6 layers with matrix-based Terraform validation
(one job per runtime for fast parallel feedback).

## Directory Structure

```
tests/
├── Makefile                       Easy local test commands
├── README.md                      This file
├── run-tests.sh                   Legacy test runner
├── unit/
│   ├── test-helpers.sh            Assert framework
│   ├── test-deploy-routing.sh     Layer 1: routing
│   ├── test-contracts.sh          Layer 2: contracts
│   └── test-generate-tfvars.sh    Layer 3: tfvars
├── integration/
│   └── test-tf-validate.sh        Layer 4: TF validate
├── local/
│   └── simulate-deploy.sh         Layer 5: simulation
├── fixtures/                      Layer 6: fixtures
│   ├── gcp-cloud-run/
│   │   ├── deploy.yml
│   │   └── deploy.prod.yml
│   ├── gcp-gke/
│   │   └── deploy.yml
│   ├── gcp-compute/
│   │   └── deploy.yml
│   ├── gcp-worker/
│   │   └── deploy.yml
│   ├── gcp-cronjob/
│   │   └── deploy.yml
│   ├── aws-ecs/
│   │   └── deploy.yml
│   ├── azure-container-apps/
│   │   └── deploy.yml
│   └── multi-service/
│       └── deploy.yml
schemas/
└── deploy.schema.json             JSON Schema for deploy.yml
```

## Adding a New Runtime

When you add a new cloud/runtime to Code Haven:

1. Create the Terraform module in `modules/{cloud}/{runtime}/`
2. Create the root template in `actions/deploy-generate/templates/`
3. Add a case in `action.yml` + `generate-tfvars.sh`
4. Add a test fixture in `tests/fixtures/{cloud}-{runtime}/`
5. Update the schema in `schemas/deploy.schema.json`
6. Run `make test-all` — it will catch anything you missed

## What's NOT Tested Locally

These require real infrastructure and are tested via separate processes:

| What | Why | How to Test |
|------|-----|-------------|
| `terraform apply` | Creates real resources | Manual deploy to test project |
| Cloud authentication | Needs real credentials | GitHub Actions with secrets |
| GitHub Actions composite action | Needs `$GITHUB_*` env vars | Push + PR workflow runs |
| Multi-service Docker builds | Needs Docker + registry | Docker workflow tests |
| Environment approval gates | Needs GitHub Environments | Manual PR + tag workflow |

For end-to-end validation, push to a feature branch and observe the
GitHub Actions workflow. For a safe live test, use a test GCP project
with a minimal fixture.
