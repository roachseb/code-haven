variable "service_name" {
  type        = string
  description = "Name of the Kubernetes deployment / Helm release"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region for the GKE cluster"
}

variable "cluster_name" {
  type        = string
  description = "Existing GKE cluster name to deploy into"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace"
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

variable "cpu" {
  type        = string
  default     = "500m"
  description = "CPU request (Kubernetes format: 100m, 500m, 1)"
}

variable "memory" {
  type        = string
  default     = "512Mi"
  description = "Memory request"
}

variable "min_instances" {
  type        = number
  default     = 1
  description = "Minimum replicas (HPA minReplicas)"
}

variable "max_instances" {
  type        = number
  default     = 5
  description = "Maximum replicas (HPA maxReplicas)"
}

variable "expose" {
  type        = string
  default     = "private"
  description = "'private' (ClusterIP) or 'public' (LoadBalancer)"

  validation {
    condition     = contains(["private", "public"], var.expose)
    error_message = "expose must be 'private' or 'public'"
  }
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables"
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Liveness/readiness probe path"
}

variable "service_account" {
  type        = string
  default     = ""
  description = "GCP service account for workload identity"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all Kubernetes resources"
}
