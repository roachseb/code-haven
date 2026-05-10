#!/usr/bin/env bash
# generate-tfvars.sh — Generate terraform.auto.tfvars.json from deploy intent
# Called by the deploy-generate action. Reads env vars set by the action.
set -euo pipefail

# ── Shared labels ──────────────────────────────────────────
LABELS=$(jq -n \
  --arg team "$TEAM" \
  --arg environment "$ENVIRONMENT" \
  '{
    team: $team,
    environment: $environment,
    "managed-by": "code-haven"
  }')

# ── Base fields (all runtimes) ─────────────────────────────
BASE=$(jq -n \
  --arg service_name "$SERVICE_NAME" \
  --arg image "$IMAGE" \
  --arg cpu "$CPU" \
  --arg memory "$MEMORY" \
  --argjson env_vars "$ENV_VARS" \
  --argjson labels "$LABELS" \
  '{
    service_name: $service_name,
    image: $image,
    cpu: $cpu,
    memory: $memory,
    env_vars: $env_vars,
    labels: $labels
  }')

# ── Cloud/Runtime-specific fields ──────────────────────────
case "${CLOUD}-${RUNTIME}" in

  gcp-cloud-run)
    jq -n \
      --argjson base "$BASE" \
      --arg project_id "$PROJECT_ID" \
      --arg region "$REGION" \
      --argjson port "$PORT" \
      --argjson min_instances "$MIN_INSTANCES" \
      --argjson max_instances "$MAX_INSTANCES" \
      --arg expose "$EXPOSE" \
      --arg health_check_path "$HEALTH_PATH" \
      --arg service_account "$SERVICE_ACCOUNT" \
      --argjson timeout_seconds "$TIMEOUT" \
      --argjson concurrency "$CONCURRENCY" \
      --arg vpc_connector "$VPC_CONNECTOR" \
      '$base + {
        project_id: $project_id,
        region: $region,
        port: $port,
        min_instances: $min_instances,
        max_instances: $max_instances,
        expose: $expose,
        health_check_path: $health_check_path,
        service_account: $service_account,
        timeout_seconds: $timeout_seconds,
        concurrency: $concurrency,
        vpc_connector: $vpc_connector
      }'
    ;;

  gcp-cloud-run-job)
    jq -n \
      --argjson base "$BASE" \
      --arg project_id "$PROJECT_ID" \
      --arg region "$REGION" \
      --arg service_account "$SERVICE_ACCOUNT" \
      --arg vpc_connector "$VPC_CONNECTOR" \
      --argjson timeout_seconds "$TIMEOUT" \
      --argjson max_retries "$MAX_RETRIES" \
      --argjson parallelism "$PARALLELISM" \
      --argjson task_count "$TASK_COUNT" \
      --arg schedule "$SCHEDULE" \
      --arg schedule_timezone "$SCHEDULE_TIMEZONE" \
      '$base + {
        project_id: $project_id,
        region: $region,
        service_account: $service_account,
        vpc_connector: $vpc_connector,
        timeout_seconds: $timeout_seconds,
        max_retries: $max_retries,
        parallelism: $parallelism,
        task_count: $task_count,
        schedule: $schedule,
        schedule_timezone: $schedule_timezone
      }'
    ;;

  gcp-gke)
    jq -n \
      --argjson base "$BASE" \
      --arg project_id "$PROJECT_ID" \
      --arg region "$REGION" \
      --argjson port "$PORT" \
      --argjson min_instances "$MIN_INSTANCES" \
      --argjson max_instances "$MAX_INSTANCES" \
      --arg expose "$EXPOSE" \
      --arg health_check_path "$HEALTH_PATH" \
      --arg service_account "$SERVICE_ACCOUNT" \
      --arg cluster_name "$CLUSTER_NAME" \
      --arg namespace "$NAMESPACE" \
      '$base + {
        project_id: $project_id,
        region: $region,
        port: $port,
        min_instances: $min_instances,
        max_instances: $max_instances,
        expose: $expose,
        health_check_path: $health_check_path,
        service_account: $service_account,
        cluster_name: $cluster_name,
        namespace: $namespace
      }'
    ;;

  gcp-compute)
    jq -n \
      --argjson base "$BASE" \
      --arg project_id "$PROJECT_ID" \
      --arg region "$REGION" \
      --argjson port "$PORT" \
      --arg expose "$EXPOSE" \
      --arg health_check_path "$HEALTH_PATH" \
      --arg service_account "$SERVICE_ACCOUNT" \
      --arg machine_type "$MACHINE_TYPE" \
      --arg zone "$ZONE" \
      --arg network "$NETWORK" \
      --arg subnetwork "$SUBNETWORK" \
      --argjson disk_size_gb "$DISK_SIZE" \
      '$base + {
        project_id: $project_id,
        region: $region,
        port: $port,
        expose: $expose,
        health_check_path: $health_check_path,
        service_account: $service_account,
        machine_type: $machine_type,
        zone: $zone,
        network: $network,
        subnetwork: $subnetwork,
        disk_size_gb: $disk_size_gb
      }'
    ;;

  aws-ecs)
    # Convert subnet_ids JSON array to Terraform-compatible list
    jq -n \
      --argjson base "$BASE" \
      --arg region "$REGION" \
      --argjson port "$PORT" \
      --argjson min_instances "$MIN_INSTANCES" \
      --argjson max_instances "$MAX_INSTANCES" \
      --arg expose "$EXPOSE" \
      --arg health_check_path "$HEALTH_PATH" \
      --arg vpc_id "$VPC_ID" \
      --argjson subnet_ids "$SUBNET_IDS" \
      --arg execution_role_arn "$EXECUTION_ROLE_ARN" \
      --arg task_role_arn "$TASK_ROLE_ARN" \
      '($base | del(.labels) | .cpu = (.cpu | tonumber) | .memory = (.memory | tonumber)) + {
        region: $region,
        port: $port,
        min_instances: $min_instances,
        max_instances: $max_instances,
        expose: $expose,
        health_check_path: $health_check_path,
        vpc_id: $vpc_id,
        subnet_ids: $subnet_ids,
        execution_role_arn: $execution_role_arn,
        task_role_arn: $task_role_arn,
        tags: $base.labels
      }'
    ;;

  azure-container-apps)
    jq -n \
      --argjson base "$BASE" \
      --arg resource_group_name "$RESOURCE_GROUP" \
      --arg location "${LOCATION:-$REGION}" \
      --argjson port "$PORT" \
      --argjson min_instances "$MIN_INSTANCES" \
      --argjson max_instances "$MAX_INSTANCES" \
      --arg expose "$EXPOSE" \
      --arg health_check_path "$HEALTH_PATH" \
      --arg managed_environment_id "$MANAGED_ENV_ID" \
      --arg log_analytics_workspace_id "$LOG_ANALYTICS_ID" \
      '($base | del(.labels) | .cpu = (.cpu | tonumber)) + {
        resource_group_name: $resource_group_name,
        location: $location,
        port: $port,
        min_instances: $min_instances,
        max_instances: $max_instances,
        expose: $expose,
        health_check_path: $health_check_path,
        managed_environment_id: $managed_environment_id,
        log_analytics_workspace_id: $log_analytics_workspace_id,
        tags: $base.labels
      }'
    ;;

  *)
    echo "::error::generate-tfvars: unsupported ${CLOUD}/${RUNTIME}" >&2
    exit 1
    ;;
esac
