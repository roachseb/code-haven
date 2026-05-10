# ═══════════════════════════════════════════════════════════════
# GKE Deployment via Helm
# Code Haven — Intent-Based Deployment Module
#
# Deploys a service to an EXISTING GKE cluster using a generic
# Helm chart. The chart is generated inline — no external
# chart repo needed.
# ═══════════════════════════════════════════════════════════════

locals {
  merged_labels = merge(var.labels, {
    "managed-by" = "code-haven"
    "app"        = var.service_name
  })
}

# ── GKE Cluster Data (for provider config) ───────────────────

data "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

data "google_client_config" "default" {}

# ── Kubernetes Provider (configured from GKE data) ───────────

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.main.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.main.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.main.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.main.master_auth[0].cluster_ca_certificate)
  }
}

# ── Namespace ────────────────────────────────────────────────

resource "kubernetes_namespace" "main" {
  metadata {
    name   = var.namespace
    labels = local.merged_labels
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# ── Helm Release (generic chart) ─────────────────────────────

resource "helm_release" "main" {
  name             = var.service_name
  namespace        = kubernetes_namespace.main.metadata[0].name
  chart            = "${path.module}/chart"
  create_namespace = false
  wait             = true
  timeout          = 300

  set {
    name  = "image"
    value = var.image
  }

  set {
    name  = "port"
    value = tostring(var.port)
  }

  set {
    name  = "resources.requests.cpu"
    value = var.cpu
  }

  set {
    name  = "resources.requests.memory"
    value = var.memory
  }

  set {
    name  = "resources.limits.cpu"
    value = var.cpu
  }

  set {
    name  = "resources.limits.memory"
    value = var.memory
  }

  set {
    name  = "replicaCount"
    value = tostring(var.min_instances)
  }

  set {
    name  = "autoscaling.minReplicas"
    value = tostring(var.min_instances)
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = tostring(var.max_instances)
  }

  set {
    name  = "service.type"
    value = var.expose == "public" ? "LoadBalancer" : "ClusterIP"
  }

  set {
    name  = "healthCheckPath"
    value = var.health_check_path
  }

  dynamic "set" {
    for_each = var.env_vars
    content {
      name  = "env.${set.key}"
      value = set.value
    }
  }

  set {
    name  = "serviceAccount.gcpEmail"
    value = var.service_account
  }
}
