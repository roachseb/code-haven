# ═══════════════════════════════════════════════════════════════
# GCP Compute Engine — Container-Optimized OS VM
# Code Haven — Intent-Based Deployment Module
#
# Runs a container on a COS VM. Ideal for services that need
# persistent disks, GPU, or custom machine types.
# ═══════════════════════════════════════════════════════════════

locals {
  merged_labels = merge(var.labels, {
    managed-by = "code-haven"
  })
  zone = var.zone != "" ? var.zone : "${var.region}-a"
  env_block = join("\n", [
    for k, v in var.env_vars : "          - name: ${k}\n            value: '${v}'"
  ])
}

# ── Container declaration (cloud-init metadata) ─────────────

data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

# ── Firewall rule (only for public exposure) ─────────────────

resource "google_compute_firewall" "allow_port" {
  count   = var.expose == "public" ? 1 : 0
  name    = "${var.service_name}-allow-${var.port}"
  network = var.network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.service_name]
}

# ── VM Instance ──────────────────────────────────────────────

resource "google_compute_instance" "main" {
  name         = var.service_name
  machine_type = var.machine_type
  zone         = local.zone
  project      = var.project_id

  tags = var.expose == "public" ? [var.service_name] : []

  labels = local.merged_labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork != "" ? var.subnetwork : null

    dynamic "access_config" {
      for_each = var.expose == "public" ? [1] : []
      content {}
    }
  }

  metadata = {
    gce-container-declaration = yamlencode({
      spec = {
        containers = [{
          name  = var.service_name
          image = var.image
          ports = [{ containerPort = var.port }]
          env   = [for k, v in var.env_vars : { name = k, value = v }]
        }]
        restartPolicy = "Always"
      }
    })
  }

  service_account {
    email  = var.service_account != "" ? var.service_account : null
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}

# ── Health Check ─────────────────────────────────────────────

resource "google_compute_health_check" "main" {
  name    = "${var.service_name}-hc"
  project = var.project_id

  http_health_check {
    port         = var.port
    request_path = var.health_check_path
  }

  check_interval_sec  = 30
  healthy_threshold   = 2
  unhealthy_threshold = 3
  timeout_sec         = 5
}
