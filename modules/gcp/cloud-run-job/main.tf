# ═══════════════════════════════════════════════════════════════
# GCP Cloud Run Job (Worker + CronJob)
# Code Haven — Intent-Based Deployment Module
#
# kind: worker   → Cloud Run Job (executed manually or by event)
# kind: cronjob  → Cloud Run Job + Cloud Scheduler trigger
# ═══════════════════════════════════════════════════════════════

locals {
  is_cronjob = var.schedule != ""
  merged_labels = merge(var.labels, {
    managed-by = "code-haven"
  })
}

# ── Cloud Run Job ────────────────────────────────────────────

resource "google_cloud_run_v2_job" "main" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
  labels   = local.merged_labels

  template {
    parallelism = var.parallelism
    task_count  = var.task_count

    template {
      service_account = var.service_account != "" ? var.service_account : null
      timeout         = "${var.timeout_seconds}s"
      max_retries     = var.max_retries

      dynamic "vpc_access" {
        for_each = var.vpc_connector != "" ? [1] : []
        content {
          connector = var.vpc_connector
          egress    = "ALL_TRAFFIC"
        }
      }

      containers {
        image = var.image

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
    ]
  }
}

# ── Cloud Scheduler (CronJob only) ──────────────────────────

resource "google_cloud_scheduler_job" "main" {
  count            = local.is_cronjob ? 1 : 0
  name             = "${var.service_name}-trigger"
  project          = var.project_id
  region           = var.region
  schedule         = var.schedule
  time_zone        = var.schedule_timezone
  attempt_deadline = "${var.timeout_seconds}s"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.service_name}:run"

    oauth_token {
      service_account_email = var.service_account
    }
  }
}
