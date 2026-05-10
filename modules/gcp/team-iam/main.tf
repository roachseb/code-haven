# ═══════════════════════════════════════════════════════════════
# Team IAM Module — GCP
# Code Haven — Per-Team Identity Management
#
# Creates two service accounts per team:
#   1. Deploy SA — used by GitHub Actions (via Workload Identity)
#      to run terraform plan/apply
#   2. Runtime SA — used by the deployed services at runtime
#      (e.g., Cloud Run service identity)
#
# The deploy SA is bound to the Workload Identity Pool so that
# GitHub repos belonging to this team can authenticate via OIDC.
# ═══════════════════════════════════════════════════════════════

# ── Deploy Service Account ───────────────────────────────────

resource "google_service_account" "deploy" {
  account_id   = "${var.team_name}-deploy"
  display_name = "Code Haven Deploy — ${var.team_name}"
  project      = var.project_id
  description  = "Used by GitHub Actions to deploy infrastructure for team ${var.team_name}"
}

# Grant deploy roles to deploy SA
resource "google_project_iam_member" "deploy_roles" {
  for_each = toset(var.deploy_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

# Grant state bucket access
resource "google_storage_bucket_iam_member" "state_access" {
  count  = var.state_bucket != "" ? 1 : 0
  bucket = var.state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.deploy.email}"
}

# ── Workload Identity Binding (GitHub → Deploy SA) ──────────

resource "google_service_account_iam_member" "wif_binding" {
  for_each = toset(var.github_repos)

  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"

  member = each.value == "*" ? (
    "principalSet://iam.googleapis.com/${var.workload_identity_pool_id}/attribute.repository_owner/${var.github_org}"
  ) : (
    "principalSet://iam.googleapis.com/${var.workload_identity_pool_id}/attribute.repository/${var.github_org}/${each.value}"
  )
}

# ── Runtime Service Account ─────────────────────────────────

resource "google_service_account" "runtime" {
  account_id   = "${var.team_name}-runtime"
  display_name = "Code Haven Runtime — ${var.team_name}"
  project      = var.project_id
  description  = "Runtime identity for services deployed by team ${var.team_name}"
}

# Grant runtime roles
resource "google_project_iam_member" "runtime_roles" {
  for_each = toset(var.runtime_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# Allow deploy SA to impersonate runtime SA
resource "google_service_account_iam_member" "deploy_impersonate_runtime" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy.email}"
}
