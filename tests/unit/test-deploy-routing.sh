#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Unit Tests for Deploy Routing
# Validates that all cloud/runtime combos have matching
# modules, templates, and are wired in the case statement.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

MODULES_ROOT="$ROOT_DIR/modules"
TEMPLATES_ROOT="$ROOT_DIR/actions/deploy-generate/templates"
ACTION_FILE="$ROOT_DIR/actions/deploy-generate/action.yml"

# ── All supported cloud/runtime pairs ─────────────────────────
SUPPORTED_PAIRS=(
  "gcp:cloud-run:modules/gcp/cloud-run:gcp-cloud-run.tf"
  "gcp:cloud-run-job:modules/gcp/cloud-run-job:gcp-cloud-run-job.tf"
  "gcp:gke:modules/gcp/gke:gcp-gke.tf"
  "gcp:compute:modules/gcp/compute:gcp-compute.tf"
  "aws:ecs:modules/aws/ecs:aws-ecs.tf"
  "azure:container-apps:modules/azure/container-apps:azure-container-apps.tf"
)

# ── Modules exist ─────────────────────────────────────────────
describe "Terraform modules exist"

for pair in "${SUPPORTED_PAIRS[@]}"; do
  IFS=':' read -r cloud runtime module_path template_file <<< "$pair"
  assert_dir_exists "Module: ${cloud}/${runtime}" "$ROOT_DIR/$module_path"
  assert_file_exists "Module main.tf: ${cloud}/${runtime}" "$ROOT_DIR/$module_path/main.tf"
  assert_file_exists "Module variables.tf: ${cloud}/${runtime}" "$ROOT_DIR/$module_path/variables.tf"
  assert_file_exists "Module outputs.tf: ${cloud}/${runtime}" "$ROOT_DIR/$module_path/outputs.tf"
  assert_file_exists "Module versions.tf: ${cloud}/${runtime}" "$ROOT_DIR/$module_path/versions.tf"
done

# ── Templates exist ───────────────────────────────────────────
describe "Root TF templates exist"

for pair in "${SUPPORTED_PAIRS[@]}"; do
  IFS=':' read -r cloud runtime module_path template_file <<< "$pair"
  assert_file_exists "Template: $template_file" "$TEMPLATES_ROOT/$template_file"
done

# ── GKE Helm chart exists ────────────────────────────────────
describe "GKE Helm chart structure"

GKE_CHART="$ROOT_DIR/modules/gcp/gke/chart"
assert_file_exists "Chart.yaml" "$GKE_CHART/Chart.yaml"
assert_file_exists "values.yaml" "$GKE_CHART/values.yaml"
assert_file_exists "deployment.yaml" "$GKE_CHART/templates/deployment.yaml"
assert_file_exists "service.yaml" "$GKE_CHART/templates/service.yaml"
assert_file_exists "hpa.yaml" "$GKE_CHART/templates/hpa.yaml"
assert_file_exists "serviceaccount.yaml" "$GKE_CHART/templates/serviceaccount.yaml"

# ── Team IAM module exists ───────────────────────────────────
describe "Team IAM module"

IAM="$ROOT_DIR/modules/gcp/team-iam"
assert_dir_exists "Team IAM dir" "$IAM"
assert_file_exists "Team IAM main.tf" "$IAM/main.tf"
assert_file_exists "Team IAM variables.tf" "$IAM/variables.tf"
assert_file_exists "Team IAM outputs.tf" "$IAM/outputs.tf"

# ── Action routes all pairs ──────────────────────────────────
describe "deploy-generate action.yml routes all pairs"

ACTION_CONTENT=$(cat "$ACTION_FILE")
for pair in "${SUPPORTED_PAIRS[@]}"; do
  IFS=':' read -r cloud runtime module_path template_file <<< "$pair"
  CASE_KEY="${cloud}-${runtime}"
  assert_contains "Route: $CASE_KEY" "$ACTION_CONTENT" "$CASE_KEY)"
done

# ── generate-tfvars.sh routes all pairs ──────────────────────
describe "generate-tfvars.sh routes all pairs"

TFVARS_CONTENT=$(cat "$ROOT_DIR/actions/deploy-generate/scripts/generate-tfvars.sh")
for pair in "${SUPPORTED_PAIRS[@]}"; do
  IFS=':' read -r cloud runtime module_path template_file <<< "$pair"
  CASE_KEY="${cloud}-${runtime}"
  assert_contains "Tfvars route: $CASE_KEY" "$TFVARS_CONTENT" "$CASE_KEY)"
done

# ── _deploy.yml validates all pairs ─────────────────────────
describe "_deploy.yml validates all pairs"

DEPLOY_WF=$(cat "$ROOT_DIR/.github/workflows/_deploy.yml")
for pair in "${SUPPORTED_PAIRS[@]}"; do
  IFS=':' read -r cloud runtime module_path template_file <<< "$pair"
  CASE_KEY="${cloud}-${runtime}"
  assert_contains "Validate: $CASE_KEY" "$DEPLOY_WF" "$CASE_KEY"
done

# ── _deploy.yml has all cloud auth steps ─────────────────────
describe "_deploy.yml cloud auth steps"

assert_contains "GCP Auth step" "$DEPLOY_WF" "provider: gcp"
assert_contains "AWS Auth step" "$DEPLOY_WF" "provider: aws"
assert_contains "Azure Auth step" "$DEPLOY_WF" "provider: azure"

# ── Test fixtures exist ──────────────────────────────────────
describe "Test fixtures for all runtimes"

FIXTURES_DIR="$ROOT_DIR/tests/fixtures"
assert_file_exists "GCP Cloud Run fixture" "$FIXTURES_DIR/gcp-cloud-run/deploy.yml"
assert_file_exists "GCP GKE fixture" "$FIXTURES_DIR/gcp-gke/deploy.yml"
assert_file_exists "GCP Compute fixture" "$FIXTURES_DIR/gcp-compute/deploy.yml"
assert_file_exists "GCP Worker fixture" "$FIXTURES_DIR/gcp-worker/deploy.yml"
assert_file_exists "GCP CronJob fixture" "$FIXTURES_DIR/gcp-cronjob/deploy.yml"
assert_file_exists "AWS ECS fixture" "$FIXTURES_DIR/aws-ecs/deploy.yml"
assert_file_exists "Azure CA fixture" "$FIXTURES_DIR/azure-container-apps/deploy.yml"
assert_file_exists "Multi-service fixture" "$FIXTURES_DIR/multi-service/deploy.yml"

# ══════════════════════════════════════════════════════════════
summary
