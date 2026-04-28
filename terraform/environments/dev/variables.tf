variable "admin_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint. Restrict to your VPN egress."
  type        = list(string)
  default     = []
}

variable "grafana_admin_password" {
  description = "Initial Grafana admin password. Rotate to SSO after bootstrap."
  type        = string
  sensitive   = true
}
