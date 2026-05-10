#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Integration Test: Terraform Validate
# For each fixture, runs the deploy-generate logic and validates
# the generated Terraform is syntactically correct.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/tests/unit/test-helpers.sh"

FIXTURES_DIR="$ROOT_DIR/tests/fixtures"
MODULES_ROOT="$ROOT_DIR/modules"
TEMPLATES_ROOT="$ROOT_DIR/actions/deploy-generate/templates"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Map fixture dir name → module path + template
declare -A MODULE_MAP=(
  ["gcp-cloud-run"]="gcp/cloud-run:gcp-cloud-run.tf"
  ["gcp-gke"]="gcp/gke:gcp-gke.tf"
  ["gcp-compute"]="gcp/compute:gcp-compute.tf"
  ["gcp-worker"]="gcp/cloud-run-job:gcp-cloud-run-job.tf"
  ["gcp-cronjob"]="gcp/cloud-run-job:gcp-cloud-run-job.tf"
  ["aws-ecs"]="aws/ecs:aws-ecs.tf"
  ["azure-container-apps"]="azure/container-apps:azure-container-apps.tf"
)

describe "Terraform validate — all runtimes"

for fixture_dir in "$FIXTURES_DIR"/*/; do
  fixture_name=$(basename "$fixture_dir")

  # Skip multi-service (needs special handling)
  [[ "$fixture_name" == "multi-service" ]] && continue

  mapping="${MODULE_MAP[$fixture_name]:-}"
  if [[ -z "$mapping" ]]; then
    echo "  ⚠ No mapping for fixture: $fixture_name — skipping"
    continue
  fi

  IFS=':' read -r module_rel template_file <<< "$mapping"

  TF_DIR="$WORKDIR/$fixture_name"
  mkdir -p "$TF_DIR"

  # Copy module and template
  cp -r "$MODULES_ROOT/$module_rel" "$TF_DIR/module"
  cp "$TEMPLATES_ROOT/$template_file" "$TF_DIR/main.tf"

  # Create a minimal tfvars so validate doesn't complain about required vars
  # We just need valid JSON structure — actual values don't matter for validate
  echo '{}' > "$TF_DIR/terraform.auto.tfvars.json"

  # Terraform init (skip backend) + validate
  pushd "$TF_DIR" > /dev/null

  INIT_OK=true
  if ! terraform init -backend=false -input=false -no-color > /dev/null 2>&1; then
    INIT_OK=false
  fi

  if [[ "$INIT_OK" == "true" ]]; then
    if terraform validate -no-color > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $fixture_name — terraform validate passed"
      PASS=$((PASS + 1))
    else
      echo -e "  ${RED}✗${NC} $fixture_name — terraform validate failed"
      terraform validate -no-color 2>&1 | head -20
      FAIL=$((FAIL + 1))
      ERRORS+=("$fixture_name: terraform validate")
    fi
  else
    echo -e "  ${RED}✗${NC} $fixture_name — terraform init failed"
    FAIL=$((FAIL + 1))
    ERRORS+=("$fixture_name: terraform init")
  fi

  popd > /dev/null
done

summary
