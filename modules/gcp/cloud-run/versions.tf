# ═══════════════════════════════════════════════════════════════
# Code Haven — GCP Cloud Run Module
#
# Pre-built Terraform module for deploying container services
# to Google Cloud Run. Used by the intent-based deploy system.
#
# Developers never touch this file — Code Haven uses it
# automatically based on their deploy.yml intent.
# ═══════════════════════════════════════════════════════════════

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
