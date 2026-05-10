variable "service_name" {
  type        = string
  description = "Name of the Container App"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group name"
}

variable "location" {
  type        = string
  default     = "canadacentral"
  description = "Azure region"
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
  type        = number
  default     = 0.5
  description = "CPU cores (0.25, 0.5, 1, 2, 4)"
}

variable "memory" {
  type        = string
  default     = "1Gi"
  description = "Memory (0.5Gi, 1Gi, 2Gi, etc.)"
}

variable "min_instances" {
  type        = number
  default     = 1
  description = "Minimum replicas"
}

variable "max_instances" {
  type        = number
  default     = 5
  description = "Maximum replicas"
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
  description = "Environment variables"
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Liveness probe path"
}

variable "managed_environment_id" {
  type        = string
  default     = ""
  description = "Existing Container Apps Environment ID (created if empty)"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = ""
  description = "Existing Log Analytics workspace ID (created if empty)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for all resources"
}
