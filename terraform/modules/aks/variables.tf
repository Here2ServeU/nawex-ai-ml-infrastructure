variable "cluster_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "node_subnet_id" { type = string }
variable "log_analytics_workspace_id" { type = string }

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "private_cluster_enabled" {
  type    = bool
  default = true
}

variable "app_node_vm_size" {
  type    = string
  default = "Standard_D8s_v5"
}

variable "app_node_min" {
  type    = number
  default = 3
}

variable "app_node_max" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
