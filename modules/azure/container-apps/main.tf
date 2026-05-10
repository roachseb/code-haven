# ═══════════════════════════════════════════════════════════════
# Azure Container Apps Service
# Code Haven — Intent-Based Deployment Module
# ═══════════════════════════════════════════════════════════════

locals {
  merged_tags = merge(var.tags, {
    "managed-by" = "code-haven"
  })
  create_environment = var.managed_environment_id == ""
  create_law         = var.log_analytics_workspace_id == "" && local.create_environment
}

# ── Log Analytics (if no existing workspace) ─────────────────

resource "azurerm_log_analytics_workspace" "main" {
  count               = local.create_law ? 1 : 0
  name                = "${var.service_name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.merged_tags
}

# ── Container Apps Environment ───────────────────────────────

resource "azurerm_container_app_environment" "main" {
  count                      = local.create_environment ? 1 : 0
  name                       = "${var.service_name}-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = local.create_law ? azurerm_log_analytics_workspace.main[0].id : var.log_analytics_workspace_id
  tags                       = local.merged_tags
}

locals {
  environment_id = local.create_environment ? azurerm_container_app_environment.main[0].id : var.managed_environment_id
}

# ── Container App ────────────────────────────────────────────

resource "azurerm_container_app" "main" {
  name                         = var.service_name
  container_app_environment_id = local.environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = local.merged_tags

  ingress {
    external_enabled = var.expose == "public"
    target_port      = var.port
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = var.min_instances
    max_replicas = var.max_instances

    container {
      name   = var.service_name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      liveness_probe {
        transport = "HTTP"
        path      = var.health_check_path
        port      = var.port

        initial_delay    = 10
        interval_seconds = 30
        failure_count_threshold = 3
      }

      startup_probe {
        transport = "HTTP"
        path      = var.health_check_path
        port      = var.port

        failure_count_threshold = 3
      }

      readiness_probe {
        transport = "HTTP"
        path      = var.health_check_path
        port      = var.port

        success_count_threshold = 1
        failure_count_threshold = 3
      }
    }

    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = "50"
    }
  }
}
