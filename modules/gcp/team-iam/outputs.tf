output "deploy_service_account_email" {
  description = "Deploy SA email — use as DEPLOY_GCP_SERVICE_ACCOUNT secret"
  value       = google_service_account.deploy.email
}

output "deploy_service_account_id" {
  description = "Deploy SA full resource ID"
  value       = google_service_account.deploy.id
}

output "runtime_service_account_email" {
  description = "Runtime SA email — use as service_account in deploy.yml"
  value       = google_service_account.runtime.email
}

output "runtime_service_account_id" {
  description = "Runtime SA full resource ID"
  value       = google_service_account.runtime.id
}

output "workload_identity_provider" {
  description = "WIF provider to use as DEPLOY_GCP_WORKLOAD_IDENTITY_PROVIDER"
  value       = "${var.workload_identity_pool_id}/providers/${var.workload_identity_provider_id}"
}

output "team_name" {
  description = "Team name"
  value       = var.team_name
}
