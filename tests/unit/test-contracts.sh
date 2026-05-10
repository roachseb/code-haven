#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Contract Tests
#
# Verifies the THREE layers of the deploy pipeline are aligned:
#   1. Module variables.tf  ← what Terraform expects
#   2. Template .tf file    ← what gets copied into workspace
#   3. generate-tfvars.sh   ← what JSON gets produced
#
# If any layer declares a variable that another layer doesn't
# provide (or vice versa), the deploy will fail at runtime.
# These tests catch that at development time.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/tests/unit/test-helpers.sh"

MODULES_ROOT="$ROOT_DIR/modules"
TEMPLATES_ROOT="$ROOT_DIR/actions/deploy-generate/templates"
TFVARS_SCRIPT="$ROOT_DIR/actions/deploy-generate/scripts/generate-tfvars.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ── Helper: extract variable names from a .tf file ───────────
extract_tf_vars() {
  local tf_file="$1"
  grep -E '^variable\s+"' "$tf_file" | sed 's/variable "\([^"]*\)".*/\1/' | sort
}

# ── Helper: extract variable names from a module dir ─────────
extract_module_vars() {
  local module_dir="$1"
  extract_tf_vars "$module_dir/variables.tf"
}

# ── Runtime definitions ──────────────────────────────────────
declare -A RUNTIMES=(
  ["gcp-cloud-run"]="gcp/cloud-run:gcp-cloud-run.tf"
  ["gcp-cloud-run-job"]="gcp/cloud-run-job:gcp-cloud-run-job.tf"
  ["gcp-gke"]="gcp/gke:gcp-gke.tf"
  ["gcp-compute"]="gcp/compute:gcp-compute.tf"
  ["aws-ecs"]="aws/ecs:aws-ecs.tf"
  ["azure-container-apps"]="azure/container-apps:azure-container-apps.tf"
)

# ═══════════════════════════════════════════════════════════════
# CONTRACT 1: Template variables ⊆ Module variables
# Every variable declared in the template must exist in the module.
# ═══════════════════════════════════════════════════════════════
describe "Contract 1: Template vars are subset of Module vars"

for runtime in "${!RUNTIMES[@]}"; do
  IFS=':' read -r module_rel template_file <<< "${RUNTIMES[$runtime]}"
  MODULE_DIR="$MODULES_ROOT/$module_rel"
  TEMPLATE="$TEMPLATES_ROOT/$template_file"

  MODULE_VARS=$(extract_module_vars "$MODULE_DIR")
  TEMPLATE_VARS=$(extract_tf_vars "$TEMPLATE")

  # Every template var must be in the module
  for var in $TEMPLATE_VARS; do
    if echo "$MODULE_VARS" | grep -qw "$var"; then
      : # ok
    else
      echo -e "  ${RED}✗${NC} [$runtime] Template var '$var' NOT in module variables.tf"
      FAIL=$((FAIL + 1))
      ERRORS+=("[$runtime] Template var '$var' missing from module")
    fi
  done

  # Check the reverse: module vars should be in template (except special cases)
  for var in $MODULE_VARS; do
    if echo "$TEMPLATE_VARS" | grep -qw "$var"; then
      : # ok
    else
      # 'ingress' is module-internal (computed from expose), so skip it
      if [[ "$var" == "ingress" ]]; then
        continue
      fi
      echo -e "  ${YELLOW}⚠${NC} [$runtime] Module var '$var' NOT declared in template (may use default)"
    fi
  done

  # Count
  T_COUNT=$(echo "$TEMPLATE_VARS" | wc -w | tr -d ' ')
  M_COUNT=$(echo "$MODULE_VARS" | wc -w | tr -d ' ')
  echo -e "  ${GREEN}✓${NC} [$runtime] Template ($T_COUNT vars) → Module ($M_COUNT vars)"
  PASS=$((PASS + 1))
done

# ═══════════════════════════════════════════════════════════════
# CONTRACT 2: TFVars output matches Template variables
# Every variable declared in the template must be present in
# the JSON produced by generate-tfvars.sh.
# ═══════════════════════════════════════════════════════════════
describe "Contract 2: TFVars output covers all Template vars"

# Set up shared env vars for tfvars generation
set_tfvars_env() {
  export SERVICE_NAME="contract-test"
  export PROJECT_ID="test-project"
  export REGION="us-central1"
  export IMAGE="ghcr.io/test/repo:sha-abc"
  export PORT="8080"
  export CPU="1"
  export MEMORY="512Mi"
  export MIN_INSTANCES="1"
  export MAX_INSTANCES="5"
  export EXPOSE="private"
  export HEALTH_PATH="/health"
  export SERVICE_ACCOUNT="test@test.iam.gserviceaccount.com"
  export TIMEOUT="300"
  export CONCURRENCY="80"
  export VPC_CONNECTOR=""
  export TEAM="test"
  export ENVIRONMENT="dev"
  export ENV_VARS='{}'
  export KIND="service"
  # AWS
  export VPC_ID="vpc-test"
  export SUBNET_IDS='["subnet-a","subnet-b"]'
  export EXECUTION_ROLE_ARN=""
  export TASK_ROLE_ARN=""
  # Azure
  export RESOURCE_GROUP="rg-test"
  export LOCATION="eastus"
  export MANAGED_ENV_ID=""
  export LOG_ANALYTICS_ID=""
  # GKE
  export CLUSTER_NAME="test-cluster"
  export NAMESPACE="default"
  # Compute
  export MACHINE_TYPE="e2-small"
  export ZONE="us-central1-a"
  export NETWORK="default"
  export SUBNETWORK=""
  export DISK_SIZE="10"
  # Job
  export SCHEDULE=""
  export SCHEDULE_TIMEZONE="UTC"
  export PARALLELISM="1"
  export TASK_COUNT="1"
  export MAX_RETRIES="3"
}

for runtime in "${!RUNTIMES[@]}"; do
  IFS=':' read -r module_rel template_file <<< "${RUNTIMES[$runtime]}"
  TEMPLATE="$TEMPLATES_ROOT/$template_file"
  TEMPLATE_VARS=$(extract_tf_vars "$TEMPLATE")

  # Parse cloud-runtime
  IFS='-' read -r TCLOUD TRUNTIME_REST <<< "$runtime"
  TRUNTIME="${runtime#$TCLOUD-}"

  # Generate tfvars
  set_tfvars_env
  export CLOUD="$TCLOUD" RUNTIME="$TRUNTIME"
  OUT="$TMPDIR/${runtime}.json"
  bash "$TFVARS_SCRIPT" > "$OUT" 2>/dev/null

  if [[ ! -s "$OUT" ]] || ! jq empty "$OUT" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} [$runtime] generate-tfvars produced invalid output"
    FAIL=$((FAIL + 1))
    ERRORS+=("[$runtime] tfvars generation failed")
    continue
  fi

  JSON_KEYS=$(jq -r 'keys[]' "$OUT" | sort)
  MISSING=0

  for var in $TEMPLATE_VARS; do
    if echo "$JSON_KEYS" | grep -qw "$var"; then
      : # ok
    else
      echo -e "  ${RED}✗${NC} [$runtime] Template var '$var' NOT in tfvars JSON output"
      FAIL=$((FAIL + 1))
      ERRORS+=("[$runtime] Missing tfvar: $var")
      MISSING=$((MISSING + 1))
    fi
  done

  if [[ $MISSING -eq 0 ]]; then
    J_COUNT=$(echo "$JSON_KEYS" | wc -w | tr -d ' ')
    T_COUNT=$(echo "$TEMPLATE_VARS" | wc -w | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} [$runtime] TFVars ($J_COUNT keys) covers Template ($T_COUNT vars)"
    PASS=$((PASS + 1))
  fi
done

# ═══════════════════════════════════════════════════════════════
# CONTRACT 3: Schema file exists and is valid JSON
# ═══════════════════════════════════════════════════════════════
describe "Contract 3: Deploy schema is valid"

SCHEMA_FILE="$ROOT_DIR/schemas/deploy.schema.json"
if [[ -f "$SCHEMA_FILE" ]]; then
  if jq empty "$SCHEMA_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} schema is valid JSON"
    PASS=$((PASS + 1))

    # Verify all runtimes are in schema enum
    SCHEMA_RUNTIMES=$(jq -r '.properties.runtime.enum[]' "$SCHEMA_FILE" | sort)
    for runtime in cloud-run gke compute ecs container-apps; do
      if echo "$SCHEMA_RUNTIMES" | grep -qw "$runtime"; then
        echo -e "  ${GREEN}✓${NC} schema includes runtime: $runtime"
        PASS=$((PASS + 1))
      else
        echo -e "  ${RED}✗${NC} schema missing runtime: $runtime"
        FAIL=$((FAIL + 1))
        ERRORS+=("Schema missing runtime: $runtime")
      fi
    done
  else
    echo -e "  ${RED}✗${NC} schema is NOT valid JSON"
    FAIL=$((FAIL + 1))
    ERRORS+=("Schema invalid JSON")
  fi
else
  echo -e "  ${RED}✗${NC} schema file not found"
  FAIL=$((FAIL + 1))
  ERRORS+=("Schema file missing")
fi

# ═══════════════════════════════════════════════════════════════
# CONTRACT 4: Fixtures match deploy.schema.json fields
# ═══════════════════════════════════════════════════════════════
describe "Contract 4: Test fixtures use valid fields"

SCHEMA_PROPS=$(jq -r '.properties | keys[]' "$SCHEMA_FILE" 2>/dev/null)
FIXTURES_DIR="$ROOT_DIR/tests/fixtures"

for fixture_dir in "$FIXTURES_DIR"/*/; do
  NAME=$(basename "$fixture_dir")
  DEPLOY="$fixture_dir/deploy.yml"
  [[ ! -f "$DEPLOY" ]] && continue

  # Get top-level keys from the fixture
  FIXTURE_KEYS=$(yq 'keys | .[]' "$DEPLOY" 2>/dev/null)
  INVALID=0

  for key in $FIXTURE_KEYS; do
    if echo "$SCHEMA_PROPS" | grep -qw "$key"; then
      : # valid
    else
      echo -e "  ${YELLOW}⚠${NC} [$NAME] Unknown field '$key' not in schema"
      INVALID=$((INVALID + 1))
    fi
  done

  if [[ $INVALID -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} [$NAME] All fields valid"
    PASS=$((PASS + 1))
  fi
done

# ═══════════════════════════════════════════════════════════════
summary
