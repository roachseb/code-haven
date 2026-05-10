# ═══════════════════════════════════════════════════════════════
# Cloud Run v2 Service
# ═══════════════════════════════════════════════════════════════

resource "google_cloud_run_v2_service" "main" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
  ingress  = var.expose == "public" ? "INGRESS_TRAFFIC_ALL" : var.ingress

  labels = merge(var.labels, {
    managed-by = "code-haven"
  })

  template {
    service_account = var.service_account != "" ? var.service_account : null
    timeout         = "${var.timeout_seconds}s"

    max_instance_request_concurrency = var.concurrency

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector != "" ? [1] : []
      content {
        connector = var.vpc_connector
        egress    = "ALL_TRAFFIC"
      }
    }

    containers {
      image = var.image

      ports {
        container_port = var.port
      }

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

      startup_probe {
        http_get {
          path = var.health_check_path
          port = var.port
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = var.health_check_path
          port = var.port
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
    ]
  }
}

# ═══════════════════════════════════════════════════════════════
# IAM — Private by default (defense posture)
#
# Only creates a public invoker binding when expose == "public".
# By default, Cloud Run services are internal-only.
# ═══════════════════════════════════════════════════════════════

resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.expose == "public" ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.main.location
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
