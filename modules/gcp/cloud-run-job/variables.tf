variable "service_name" {
  type        = string
  description = "Name of the Cloud Run Job"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region"
}

variable "image" {
  type        = string
  description = "Container image URL"
}

variable "cpu" {
  type        = string
  default     = "1"
  description = "CPU allocation"
}

variable "memory" {
  type        = string
  default     = "512Mi"
  description = "Memory allocation"
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables"
}

variable "service_account" {
  type        = string
  default     = ""
  description = "GCP service account email"
}

variable "vpc_connector" {
  type        = string
  default     = ""
  description = "VPC Access connector"
}

variable "timeout_seconds" {
  type        = number
  default     = 600
  description = "Max execution time in seconds"
}

variable "max_retries" {
  type        = number
  default     = 3
  description = "Maximum retry attempts on failure"
}

variable "parallelism" {
  type        = number
  default     = 1
  description = "Number of tasks to run in parallel"
}

variable "task_count" {
  type        = number
  default     = 1
  description = "Total number of tasks"
}

# ── CronJob-specific ─────────────────────────────────────────

variable "schedule" {
  type        = string
  default     = ""
  description = "Cron schedule expression (empty = worker, not scheduled)"
}

variable "schedule_timezone" {
  type        = string
  default     = "America/Toronto"
  description = "Timezone for the cron schedule"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all resources"
}
