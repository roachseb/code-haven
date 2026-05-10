variable "team_name" {
  type        = string
  description = "Team identifier (e.g., 'platform', 'ml-team', 'shared')"
}

variable "project_id" {
  type        = string
  description = "GCP project ID where the service account is created"
}

variable "github_org" {
  type        = string
  description = "GitHub organization name for workload identity"
}

variable "github_repos" {
  type        = list(string)
  default     = ["*"]
  description = "List of GitHub repo names this team can deploy from ('*' = all repos in the org)"
}

variable "deploy_roles" {
  type        = list(string)
  default     = [
    "roles/run.developer",
    "roles/iam.serviceAccountUser",
    "roles/storage.objectAdmin",
  ]
  description = "IAM roles to grant to the deploy service account"
}

variable "runtime_roles" {
  type        = list(string)
  default     = []
  description = "Additional IAM roles for the runtime service account (e.g., roles/cloudsql.client)"
}

variable "state_bucket" {
  type        = string
  default     = ""
  description = "GCS bucket for Terraform state (grants objectAdmin if set)"
}

variable "workload_identity_pool_id" {
  type        = string
  description = "Existing Workload Identity Pool ID for GitHub OIDC"
}

variable "workload_identity_provider_id" {
  type        = string
  description = "Existing Workload Identity Provider ID in the pool"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for the service accounts"
}
