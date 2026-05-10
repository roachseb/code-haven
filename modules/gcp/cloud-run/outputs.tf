output "url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.main.uri
}

output "service_name" {
  description = "The Cloud Run service name"
  value       = google_cloud_run_v2_service.main.name
}

output "service_id" {
  description = "The full resource ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.main.id
}

output "project" {
  description = "The GCP project the service is deployed in"
  value       = google_cloud_run_v2_service.main.project
}

output "region" {
  description = "The region the service is deployed in"
  value       = google_cloud_run_v2_service.main.location
}

output "latest_revision" {
  description = "Name of the latest ready revision"
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}
