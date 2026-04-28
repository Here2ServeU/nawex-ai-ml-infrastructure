variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach the GKE master endpoint."
  type        = list(string)
  default     = []
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
