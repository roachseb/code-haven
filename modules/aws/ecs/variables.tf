# ── Service Identity ──────────────────────────────────────────

variable "service_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

# ── Networking ───────────────────────────────────────────────

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ECS service"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Fargate tasks"
}

variable "expose" {
  type        = string
  default     = "private"
  description = "'private' (internal ALB) or 'public' (internet-facing ALB)"

  validation {
    condition     = contains(["private", "public"], var.expose)
    error_message = "expose must be 'private' or 'public'"
  }
}

# ── Container ────────────────────────────────────────────────

variable "image" {
  type        = string
  description = "Container image URL"
}

variable "port" {
  type        = number
  default     = 8080
  description = "Container port"
}

# ── Resources & Scaling ──────────────────────────────────────

variable "cpu" {
  type        = number
  default     = 256
  description = "Fargate CPU units (256=0.25 vCPU, 512=0.5, 1024=1, 2048=2, 4096=4)"
}

variable "memory" {
  type        = number
  default     = 512
  description = "Fargate memory in MiB"
}

variable "min_instances" {
  type        = number
  default     = 1
  description = "Minimum task count"
}

variable "max_instances" {
  type        = number
  default     = 5
  description = "Maximum task count"
}

# ── Application ──────────────────────────────────────────────

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables"
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Health check path for ALB target group"
}

# ── IAM ──────────────────────────────────────────────────────

variable "execution_role_arn" {
  type        = string
  default     = ""
  description = "ECS task execution role ARN (created if empty)"
}

variable "task_role_arn" {
  type        = string
  default     = ""
  description = "ECS task role ARN (created if empty)"
}

# ── Labels ───────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for all resources"
}
