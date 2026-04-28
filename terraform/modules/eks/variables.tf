variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "kubernetes_version" {
  type        = string
  description = "Control-plane Kubernetes version."
  default     = "1.30"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the cluster and node groups."
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether the API server endpoint is publicly reachable. Disable for prod and access via VPN/bastion."
  default     = false
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public API endpoint (when enabled)."
  default     = []
}

variable "app_node_instance_types" {
  type    = list(string)
  default = ["m6i.xlarge"]
}

variable "app_node_min" {
  type    = number
  default = 3
}

variable "app_node_max" {
  type    = number
  default = 20
}

variable "app_node_desired" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}
