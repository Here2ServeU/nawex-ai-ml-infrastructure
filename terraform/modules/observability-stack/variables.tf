variable "kube_prometheus_stack_version" {
  type    = string
  default = "61.3.2"
}

variable "loki_version" {
  type    = string
  default = "6.6.4"
}

variable "tempo_version" {
  type    = string
  default = "1.10.1"
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
  description = "Bootstrap Grafana admin password. Should be rotated to OIDC SSO post-bootstrap."
}

variable "storage_class" {
  type        = string
  description = "PV storage class for Prometheus / Alertmanager / Loki PVCs."
}
