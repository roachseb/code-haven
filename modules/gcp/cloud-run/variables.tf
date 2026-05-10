# ── Service Identity ──────────────────────────────────────────

variable "service_name" {
  type        = string
  description = "Name of the Cloud Run service (defaults to repo name)"
}

variable "project_id" {
  type        = string
  description = "GCP project ID where the service is deployed"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region for deployment"
}

# ── Container ────────────────────────────────────────────────

variable "image" {
  type        = string
  description = "Container image URL (built by the pipeline)"
}

variable "port" {
  type        = number
  default     = 8080
  description = "Container port the service listens on"
}

# ── Resources & Scaling ──────────────────────────────────────

variable "cpu" {
  type        = string
  default     = "1"
  description = "CPU allocation (e.g., '1', '2', '0.5')"
}

variable "memory" {
  type        = string
  default     = "512Mi"
  description = "Memory allocation (e.g., '256Mi', '1Gi')"
}

variable "min_instances" {
  type        = number
  default     = 1
  description = "Minimum number of instances (0 = scale to zero)"
}

variable "max_instances" {
  type        = number
  default     = 5
  description = "Maximum number of instances"
}

# ── Networking ───────────────────────────────────────────────

variable "expose" {
  type        = string
  default     = "private"
  description = "Service visibility: 'private' (default, internal only) or 'public'"

  validation {
    condition     = contains(["private", "public"], var.expose)
    error_message = "expose must be 'private' or 'public'"
  }
}

variable "ingress" {
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  description = "Cloud Run ingress setting"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    ], var.ingress)
    error_message = "Invalid ingress value"
  }
}

variable "vpc_connector" {
  type        = string
  default     = ""
  description = "VPC Access connector name (for private networking to VPC resources)"
}

# ── Application ──────────────────────────────────────────────

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the container"
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "HTTP path for startup and liveness probes"
}

variable "timeout_seconds" {
  type        = number
  default     = 300
  description = "Request timeout in seconds"
}

variable "concurrency" {
  type        = number
  default     = 80
  description = "Maximum concurrent requests per instance"
}

# ── IAM / Service Account ───────────────────────────────────

variable "service_account" {
  type        = string
  default     = ""
  description = "GCP service account email for the Cloud Run service runtime identity"
}

# ── Labels ───────────────────────────────────────────────────

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to the Cloud Run service"
}
