#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Unit Tests for generate-tfvars.sh
# Tests that each cloud/runtime combination produces valid JSON
# with the correct fields.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

TFVARS_SCRIPT="$ROOT_DIR/actions/deploy-generate/scripts/generate-tfvars.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ── Shared defaults ───────────────────────────────────────────
set_defaults() {
  export SERVICE_NAME="test-service"
  export PROJECT_ID="my-project-dev"
  export REGION="us-central1"
  export IMAGE="ghcr.io/org/repo:sha-abc1234"
  export PORT="8080"
  export CPU="1"
  export MEMORY="512Mi"
  export MIN_INSTANCES="1"
  export MAX_INSTANCES="5"
  export EXPOSE="private"
  export HEALTH_PATH="/health"
  export SERVICE_ACCOUNT=""
  export TIMEOUT="300"
  export CONCURRENCY="80"
  export VPC_CONNECTOR=""
  export TEAM="platform"
  export ENVIRONMENT="dev"
  export ENV_VARS='{}'
  export KIND="service"
  # AWS defaults
  export VPC_ID=""
  export SUBNET_IDS="[]"
  export EXECUTION_ROLE_ARN=""
  export TASK_ROLE_ARN=""
  # Azure defaults
  export RESOURCE_GROUP=""
  export LOCATION=""
  export MANAGED_ENV_ID=""
  export LOG_ANALYTICS_ID=""
  # GKE defaults
  export CLUSTER_NAME=""
  export NAMESPACE="default"
  # Compute defaults
  export MACHINE_TYPE="e2-small"
  export ZONE=""
  export NETWORK="default"
  export SUBNETWORK=""
  export DISK_SIZE="10"
  # Job defaults
  export SCHEDULE=""
  export SCHEDULE_TIMEZONE="UTC"
  export PARALLELISM="1"
  export TASK_COUNT="1"
  export MAX_RETRIES="3"
}

# ══════════════════════════════════════════════════════════════
# GCP Cloud Run
# ══════════════════════════════════════════════════════════════
describe "GCP Cloud Run — generate-tfvars"

set_defaults
export CLOUD="gcp" RUNTIME="cloud-run"
OUT="$TMPDIR/gcp-cloud-run.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "service_name" "$OUT" '.service_name' "test-service"
assert_json_field "project_id" "$OUT" '.project_id' "my-project-dev"
assert_json_field "region" "$OUT" '.region' "us-central1"
assert_json_field "image" "$OUT" '.image' "ghcr.io/org/repo:sha-abc1234"
assert_json_field "port is number" "$OUT" '.port' "8080"
assert_json_field "cpu" "$OUT" '.cpu' "1"
assert_json_field "memory" "$OUT" '.memory' "512Mi"
assert_json_field "min_instances" "$OUT" '.min_instances' "1"
assert_json_field "max_instances" "$OUT" '.max_instances' "5"
assert_json_field "expose" "$OUT" '.expose' "private"
assert_json_field "health_check_path" "$OUT" '.health_check_path' "/health"
assert_json_field "timeout_seconds" "$OUT" '.timeout_seconds' "300"
assert_json_field "concurrency" "$OUT" '.concurrency' "80"
assert_json_field "labels.team" "$OUT" '.labels.team' "platform"
assert_json_field "labels.managed-by" "$OUT" '.labels."managed-by"' "code-haven"

# ══════════════════════════════════════════════════════════════
# GCP Cloud Run Job (Worker)
# ══════════════════════════════════════════════════════════════
describe "GCP Cloud Run Job — generate-tfvars"

set_defaults
export CLOUD="gcp" RUNTIME="cloud-run-job"
export SCHEDULE="" MAX_RETRIES="3" PARALLELISM="1" TASK_COUNT="1"
OUT="$TMPDIR/gcp-cloud-run-job.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "service_name" "$OUT" '.service_name' "test-service"
assert_json_field "project_id" "$OUT" '.project_id' "my-project-dev"
assert_json_field "schedule is empty (worker)" "$OUT" '.schedule' ""
assert_json_field "max_retries" "$OUT" '.max_retries' "3"
assert_json_field "parallelism" "$OUT" '.parallelism' "1"
assert_json_field "task_count" "$OUT" '.task_count' "1"
assert_json_field "timeout_seconds" "$OUT" '.timeout_seconds' "300"

# ── CronJob variant ──────────────────────────────────────────
describe "GCP Cloud Run Job (CronJob) — generate-tfvars"

set_defaults
export CLOUD="gcp" RUNTIME="cloud-run-job"
export SCHEDULE="0 2 * * *" SCHEDULE_TIMEZONE="America/New_York"
OUT="$TMPDIR/gcp-cloud-run-job-cron.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "schedule" "$OUT" '.schedule' "0 2 * * *"
assert_json_field "schedule_timezone" "$OUT" '.schedule_timezone' "America/New_York"

# ══════════════════════════════════════════════════════════════
# GCP GKE
# ══════════════════════════════════════════════════════════════
describe "GCP GKE — generate-tfvars"

set_defaults
export CLOUD="gcp" RUNTIME="gke"
export CLUSTER_NAME="main-cluster" NAMESPACE="platform"
OUT="$TMPDIR/gcp-gke.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "cluster_name" "$OUT" '.cluster_name' "main-cluster"
assert_json_field "namespace" "$OUT" '.namespace' "platform"
assert_json_field "port" "$OUT" '.port' "8080"
assert_json_field "min_instances" "$OUT" '.min_instances' "1"
assert_json_field "max_instances" "$OUT" '.max_instances' "5"

# ══════════════════════════════════════════════════════════════
# GCP Compute Engine
# ══════════════════════════════════════════════════════════════
describe "GCP Compute — generate-tfvars"

set_defaults
export CLOUD="gcp" RUNTIME="compute"
export MACHINE_TYPE="n2-standard-4" ZONE="us-central1-a" DISK_SIZE="50"
OUT="$TMPDIR/gcp-compute.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "machine_type" "$OUT" '.machine_type' "n2-standard-4"
assert_json_field "zone" "$OUT" '.zone' "us-central1-a"
assert_json_field "disk_size_gb" "$OUT" '.disk_size_gb' "50"
assert_json_field "network" "$OUT" '.network' "default"

# ══════════════════════════════════════════════════════════════
# AWS ECS
# ══════════════════════════════════════════════════════════════
describe "AWS ECS — generate-tfvars"

set_defaults
export CLOUD="aws" RUNTIME="ecs"
export REGION="us-east-1"
export VPC_ID="vpc-0123456789abcdef0"
export SUBNET_IDS='["subnet-a","subnet-b"]'
export CPU="512" MEMORY="1024"
OUT="$TMPDIR/aws-ecs.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "vpc_id" "$OUT" '.vpc_id' "vpc-0123456789abcdef0"
assert_json_field "subnet count" "$OUT" '.subnet_ids | length' "2"
assert_json_field "subnet[0]" "$OUT" '.subnet_ids[0]' "subnet-a"
assert_json_field "uses tags not labels" "$OUT" '.tags.team' "platform"
assert_json_field "no labels key" "$OUT" '.labels // "absent"' "absent"
assert_json_field "region" "$OUT" '.region' "us-east-1"

# ══════════════════════════════════════════════════════════════
# Azure Container Apps
# ══════════════════════════════════════════════════════════════
describe "Azure Container Apps — generate-tfvars"

set_defaults
export CLOUD="azure" RUNTIME="container-apps"
export RESOURCE_GROUP="rg-platform-dev" LOCATION="eastus"
OUT="$TMPDIR/azure-container-apps.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "resource_group_name" "$OUT" '.resource_group_name' "rg-platform-dev"
assert_json_field "location" "$OUT" '.location' "eastus"
assert_json_field "uses tags not labels" "$OUT" '.tags.team' "platform"
assert_json_field "no labels key" "$OUT" '.labels // "absent"' "absent"

# ══════════════════════════════════════════════════════════════
# Env vars passthrough
# ══════════════════════════════════════════════════════════════
describe "Env vars are passed through"

set_defaults
export CLOUD="gcp" RUNTIME="cloud-run"
export ENV_VARS='{"DB_HOST":"db.internal","LOG_LEVEL":"debug"}'
OUT="$TMPDIR/env-vars.json"
bash "$TFVARS_SCRIPT" > "$OUT"

assert_json_field "env_vars.DB_HOST" "$OUT" '.env_vars.DB_HOST' "db.internal"
assert_json_field "env_vars.LOG_LEVEL" "$OUT" '.env_vars.LOG_LEVEL' "debug"

# ══════════════════════════════════════════════════════════════
summary
