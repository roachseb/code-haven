#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Local Deploy Simulation
#
# Simulates the deploy-generate action + terraform plan LOCALLY.
# No GitHub Actions needed. No cloud credentials needed for
# validation (uses -backend=false).
#
# Usage:
#   # Test a specific fixture
#   bash tests/local/simulate-deploy.sh tests/fixtures/gcp-cloud-run
#
#   # Test with a real repo's deploy.yml
#   bash tests/local/simulate-deploy.sh /path/to/my-repo
#
#   # Test all fixtures
#   bash tests/local/simulate-deploy.sh --all
#
#   # With terraform plan (requires terraform CLI)
#   bash tests/local/simulate-deploy.sh tests/fixtures/gcp-cloud-run --plan
#
# Prerequisites:
#   - yq (YAML processor)
#   - jq (JSON processor)
#   - terraform (only if --plan flag is used)
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Args ──────────────────────────────────────────────────────
FIXTURE_PATH="${1:-}"
DO_PLAN=false
RUN_ALL=false
ENVIRONMENT="${CODEHAVEN_ENV:-dev}"

for arg in "$@"; do
  case "$arg" in
    --plan) DO_PLAN=true ;;
    --all)  RUN_ALL=true ;;
    --env=*) ENVIRONMENT="${arg#--env=}" ;;
  esac
done

if [[ -z "$FIXTURE_PATH" && "$RUN_ALL" == "false" ]]; then
  echo -e "${RED}Usage: $0 <fixture-dir|--all> [--plan] [--env=dev|staging|prod]${NC}"
  echo ""
  echo "  fixture-dir   Directory containing deploy.yml"
  echo "  --all         Run all test fixtures"
  echo "  --plan        Also run terraform plan (requires terraform CLI)"
  echo "  --env=ENV     Target environment (default: dev)"
  exit 1
fi

# ── Check prerequisites ──────────────────────────────────────
for cmd in yq jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Missing: $cmd${NC}"
    echo "Install: brew install $cmd  (macOS) or see docs"
    exit 1
  fi
done

if [[ "$DO_PLAN" == "true" ]] && ! command -v terraform &>/dev/null; then
  echo -e "${RED}--plan requires terraform CLI${NC}"
  exit 1
fi

# ═══════════════════════════════════════════════════════════════
# SIMULATE — Runs the deploy-generate logic locally
# ═══════════════════════════════════════════════════════════════
simulate_deploy() {
  local SOURCE_DIR="$1"
  local ENV="$2"

  # Find deploy.yml
  local FILE=""
  [[ -f "$SOURCE_DIR/deploy.yml" ]] && FILE="$SOURCE_DIR/deploy.yml"
  [[ -f "$SOURCE_DIR/.codehaven/deploy.yml" ]] && FILE="$SOURCE_DIR/.codehaven/deploy.yml"

  if [[ -z "$FILE" ]]; then
    echo -e "  ${RED}✗ No deploy.yml found in $SOURCE_DIR${NC}"
    return 1
  fi

  echo -e "  ${CYAN}Intent:${NC} $FILE"

  # Merge with environment override
  local DIR
  DIR=$(dirname "$FILE")
  local BASE
  BASE=$(basename "$FILE" .yml)
  local ENV_FILE="${DIR}/${BASE}.${ENV}.yml"
  local MERGED
  MERGED=$(mktemp)
  trap "rm -f $MERGED" RETURN

  if [[ -f "$ENV_FILE" ]]; then
    echo -e "  ${CYAN}Override:${NC} $ENV_FILE"
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$FILE" "$ENV_FILE" > "$MERGED"
  else
    cp "$FILE" "$MERGED"
  fi

  # Parse values
  local KIND CLOUD RUNTIME TEAM PROJECT_ID REGION PORT CPU MEMORY
  local MIN MAX EXPOSE HEALTH SA TIMEOUT CONCURRENCY VPC_CONN ENV_VARS
  KIND=$(yq '.kind // "service"' "$MERGED")
  CLOUD=$(yq '.cloud // ""' "$MERGED")
  RUNTIME=$(yq '.runtime // ""' "$MERGED")
  TEAM=$(yq '.team // "default"' "$MERGED")
  PROJECT_ID=$(yq '.project_id // "test-project"' "$MERGED")
  REGION=$(yq '.region // "us-central1"' "$MERGED")
  PORT=$(yq '.port // 8080' "$MERGED")
  CPU=$(yq '.resources.cpu // "1"' "$MERGED")
  MEMORY=$(yq '.resources.memory // "512Mi"' "$MERGED")
  MIN=$(yq '.replicas.min // 1' "$MERGED")
  MAX=$(yq '.replicas.max // 5' "$MERGED")
  EXPOSE=$(yq '.expose // "private"' "$MERGED")
  HEALTH=$(yq '.health.path // "/health"' "$MERGED")
  SA=$(yq '.service_account // ""' "$MERGED")
  TIMEOUT=$(yq '.timeout // 300' "$MERGED")
  CONCURRENCY=$(yq '.concurrency // 80' "$MERGED")
  VPC_CONN=$(yq '.vpc_connector // ""' "$MERGED")
  ENV_VARS=$(yq -o=json '.env // {}' "$MERGED")

  # Cloud-specific
  local VPC_ID SUBNET_IDS EXECUTION_ROLE_ARN TASK_ROLE_ARN
  local RESOURCE_GROUP LOCATION MANAGED_ENV_ID LOG_ANALYTICS_ID
  local CLUSTER_NAME NAMESPACE MACHINE_TYPE ZONE NETWORK SUBNETWORK DISK_SIZE
  local SCHEDULE SCHEDULE_TIMEZONE PARALLELISM TASK_COUNT MAX_RETRIES
  VPC_ID=$(yq '.vpc_id // ""' "$MERGED")
  SUBNET_IDS=$(yq -o=json '.subnet_ids // []' "$MERGED")
  EXECUTION_ROLE_ARN=$(yq '.execution_role_arn // ""' "$MERGED")
  TASK_ROLE_ARN=$(yq '.task_role_arn // ""' "$MERGED")
  RESOURCE_GROUP=$(yq '.resource_group // ""' "$MERGED")
  LOCATION=$(yq '.location // ""' "$MERGED")
  MANAGED_ENV_ID=$(yq '.managed_environment_id // ""' "$MERGED")
  LOG_ANALYTICS_ID=$(yq '.log_analytics_workspace_id // ""' "$MERGED")
  CLUSTER_NAME=$(yq '.cluster_name // ""' "$MERGED")
  NAMESPACE=$(yq '.namespace // "default"' "$MERGED")
  MACHINE_TYPE=$(yq '.machine_type // "e2-small"' "$MERGED")
  ZONE=$(yq '.zone // ""' "$MERGED")
  NETWORK=$(yq '.network // "default"' "$MERGED")
  SUBNETWORK=$(yq '.subnetwork // ""' "$MERGED")
  DISK_SIZE=$(yq '.disk_size_gb // 10' "$MERGED")
  SCHEDULE=$(yq '.schedule // ""' "$MERGED")
  SCHEDULE_TIMEZONE=$(yq '.schedule_timezone // "UTC"' "$MERGED")
  PARALLELISM=$(yq '.parallelism // 1' "$MERGED")
  TASK_COUNT=$(yq '.task_count // 1' "$MERGED")
  MAX_RETRIES=$(yq '.max_retries // 3' "$MERGED")

  # Validate
  if [[ -z "$CLOUD" || "$CLOUD" == "null" ]]; then
    echo -e "  ${RED}✗ 'cloud' is required${NC}"
    return 1
  fi
  if [[ -z "$RUNTIME" || "$RUNTIME" == "null" ]]; then
    echo -e "  ${RED}✗ 'runtime' is required${NC}"
    return 1
  fi

  # Map kind to runtime override
  if [[ "$KIND" == "worker" || "$KIND" == "cronjob" ]]; then
    case "$CLOUD" in
      gcp) RUNTIME="cloud-run-job" ;;
      *) echo -e "  ${RED}✗ Worker/CronJob only supported on GCP${NC}"; return 1 ;;
    esac
  fi

  echo -e "  ${CYAN}Resolved:${NC} kind=$KIND cloud=$CLOUD runtime=$RUNTIME team=$TEAM"

  # Resolve module and template
  local MODULES_ROOT="$ROOT_DIR/modules"
  local TEMPLATES_ROOT="$ROOT_DIR/actions/deploy-generate/templates"
  local MODULE_SRC TEMPLATE

  case "${CLOUD}-${RUNTIME}" in
    gcp-cloud-run)        MODULE_SRC="$MODULES_ROOT/gcp/cloud-run";       TEMPLATE="$TEMPLATES_ROOT/gcp-cloud-run.tf" ;;
    gcp-cloud-run-job)    MODULE_SRC="$MODULES_ROOT/gcp/cloud-run-job";   TEMPLATE="$TEMPLATES_ROOT/gcp-cloud-run-job.tf" ;;
    gcp-gke)              MODULE_SRC="$MODULES_ROOT/gcp/gke";             TEMPLATE="$TEMPLATES_ROOT/gcp-gke.tf" ;;
    gcp-compute)          MODULE_SRC="$MODULES_ROOT/gcp/compute";         TEMPLATE="$TEMPLATES_ROOT/gcp-compute.tf" ;;
    aws-ecs)              MODULE_SRC="$MODULES_ROOT/aws/ecs";             TEMPLATE="$TEMPLATES_ROOT/aws-ecs.tf" ;;
    azure-container-apps) MODULE_SRC="$MODULES_ROOT/azure/container-apps"; TEMPLATE="$TEMPLATES_ROOT/azure-container-apps.tf" ;;
    *)
      echo -e "  ${RED}✗ Unsupported: ${CLOUD}/${RUNTIME}${NC}"
      return 1
      ;;
  esac

  if [[ ! -d "$MODULE_SRC" ]]; then
    echo -e "  ${RED}✗ Module not found: $MODULE_SRC${NC}"
    return 1
  fi
  if [[ ! -f "$TEMPLATE" ]]; then
    echo -e "  ${RED}✗ Template not found: $TEMPLATE${NC}"
    return 1
  fi

  # Build workspace
  local DEPLOY_DIR
  DEPLOY_DIR=$(mktemp -d)
  cp -r "$MODULE_SRC" "$DEPLOY_DIR/module"
  cp "$TEMPLATE" "$DEPLOY_DIR/main.tf"

  # Generate tfvars
  local SERVICE_NAME="test-service-sim"
  local IMAGE="ghcr.io/test-org/test-repo:sha-sim1234"

  (
    export SERVICE_NAME PROJECT_ID REGION IMAGE PORT CPU MEMORY
    export MIN_INSTANCES="$MIN" MAX_INSTANCES="$MAX"
    export EXPOSE HEALTH_PATH="$HEALTH" SERVICE_ACCOUNT="$SA"
    export TIMEOUT CONCURRENCY VPC_CONNECTOR="$VPC_CONN" TEAM ENVIRONMENT="$ENV" ENV_VARS
    export CLOUD RUNTIME KIND
    export VPC_ID SUBNET_IDS EXECUTION_ROLE_ARN TASK_ROLE_ARN
    export RESOURCE_GROUP LOCATION MANAGED_ENV_ID LOG_ANALYTICS_ID
    export CLUSTER_NAME NAMESPACE
    export MACHINE_TYPE ZONE NETWORK SUBNETWORK DISK_SIZE
    export SCHEDULE SCHEDULE_TIMEZONE PARALLELISM TASK_COUNT MAX_RETRIES
    bash "$ROOT_DIR/actions/deploy-generate/scripts/generate-tfvars.sh"
  ) > "$DEPLOY_DIR/terraform.auto.tfvars.json"

  echo -e "  ${GREEN}✓${NC} Workspace generated at $DEPLOY_DIR"

  # Validate JSON
  if jq empty "$DEPLOY_DIR/terraform.auto.tfvars.json" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} terraform.auto.tfvars.json is valid JSON"
  else
    echo -e "  ${RED}✗${NC} terraform.auto.tfvars.json is NOT valid JSON"
    cat "$DEPLOY_DIR/terraform.auto.tfvars.json"
    rm -rf "$DEPLOY_DIR"
    return 1
  fi

  # Count fields
  local FIELD_COUNT
  FIELD_COUNT=$(jq 'keys | length' "$DEPLOY_DIR/terraform.auto.tfvars.json")
  echo -e "  ${CYAN}Fields:${NC} $FIELD_COUNT variables generated"

  # Pretty-print tfvars
  echo -e "  ${CYAN}TFVars:${NC}"
  jq '.' "$DEPLOY_DIR/terraform.auto.tfvars.json" | sed 's/^/    /'

  # Terraform validate (no backend)
  if [[ "$DO_PLAN" == "true" ]]; then
    echo ""
    echo -e "  ${CYAN}Terraform init (no backend)...${NC}"
    if (cd "$DEPLOY_DIR" && terraform init -backend=false -input=false -no-color > /dev/null 2>&1); then
      echo -e "  ${GREEN}✓${NC} terraform init succeeded"

      echo -e "  ${CYAN}Terraform validate...${NC}"
      if (cd "$DEPLOY_DIR" && terraform validate -no-color 2>&1); then
        echo -e "  ${GREEN}✓${NC} terraform validate passed"
      else
        echo -e "  ${RED}✗${NC} terraform validate failed"
      fi
    else
      echo -e "  ${RED}✗${NC} terraform init failed"
      (cd "$DEPLOY_DIR" && terraform init -backend=false -input=false -no-color 2>&1 | head -20)
    fi
  fi

  # Cleanup
  rm -rf "$DEPLOY_DIR"
  echo -e "  ${GREEN}✓${NC} Simulation complete"
  return 0
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Code Haven — Local Deploy Simulation${NC}"
echo -e "${CYAN}  Environment: ${ENVIRONMENT}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

PASS=0
FAIL=0

if [[ "$RUN_ALL" == "true" ]]; then
  FIXTURES_DIR="$ROOT_DIR/tests/fixtures"
  for fixture in "$FIXTURES_DIR"/*/; do
    NAME=$(basename "$fixture")

    # Skip multi-service for now (needs special handling)
    [[ "$NAME" == "multi-service" ]] && continue

    echo ""
    echo -e "${YELLOW}━━━ $NAME ━━━${NC}"
    if simulate_deploy "$fixture" "$ENVIRONMENT"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
    fi
  done

  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  if [[ $FAIL -gt 0 ]]; then
    echo -e "  ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
  else
    echo -e "  ${GREEN}All $PASS fixtures passed${NC}"
  fi
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  [[ $FAIL -gt 0 ]] && exit 1
else
  # Remove --plan and --env flags from the path
  CLEAN_PATH="$FIXTURE_PATH"
  [[ "$CLEAN_PATH" == "--"* ]] && { echo "No fixture path provided"; exit 1; }

  echo ""
  echo -e "${YELLOW}━━━ $(basename "$CLEAN_PATH") ━━━${NC}"
  simulate_deploy "$CLEAN_PATH" "$ENVIRONMENT"
fi
