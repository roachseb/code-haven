variable "service_name" {
  type        = string
  description = "Name of the VM instance"
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

variable "zone" {
  type        = string
  default     = ""
  description = "GCP zone (defaults to region-a)"
}

variable "image" {
  type        = string
  description = "Container image URL"
}

variable "port" {
  type        = number
  default     = 8080
  description = "Container port"
}

variable "machine_type" {
  type        = string
  default     = "e2-small"
  description = "GCE machine type (e2-micro, e2-small, e2-medium, n2-standard-2, etc.)"
}

variable "expose" {
  type        = string
  default     = "private"
  description = "'private' or 'public'"

  validation {
    condition     = contains(["private", "public"], var.expose)
    error_message = "expose must be 'private' or 'public'"
  }
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables passed to the container"
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Health check path"
}

variable "service_account" {
  type        = string
  default     = ""
  description = "GCP service account email for the VM"
}

variable "network" {
  type        = string
  default     = "default"
  description = "VPC network name"
}

variable "subnetwork" {
  type        = string
  default     = ""
  description = "VPC subnetwork name"
}

variable "disk_size_gb" {
  type        = number
  default     = 20
  description = "Boot disk size in GB"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all resources"
}
