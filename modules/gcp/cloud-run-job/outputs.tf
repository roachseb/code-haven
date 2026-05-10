output "job_name" {
  description = "Cloud Run Job name"
  value       = google_cloud_run_v2_job.main.name
}

output "job_id" {
  description = "Full resource ID"
  value       = google_cloud_run_v2_job.main.id
}

output "project" {
  description = "GCP project"
  value       = var.project_id
}

output "region" {
  description = "Deployment region"
  value       = var.region
}

output "scheduler_name" {
  description = "Cloud Scheduler job name (only for cronjobs)"
  value       = local.is_cronjob ? google_cloud_scheduler_job.main[0].name : "N/A (worker — not scheduled)"
}

output "schedule" {
  description = "Cron schedule"
  value       = local.is_cronjob ? var.schedule : "N/A"
}
