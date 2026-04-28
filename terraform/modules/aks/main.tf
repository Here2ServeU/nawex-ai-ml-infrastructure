terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.110" }
  }
}

resource "azurerm_user_assigned_identity" "cluster" {
  name                = "${var.cluster_name}-id"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.cluster_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.cluster_name
  kubernetes_version                = var.kubernetes_version
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true
  private_cluster_enabled           = var.private_cluster_enabled
  sku_tier                          = "Standard"

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D4s_v5"
    vnet_subnet_id       = var.node_subnet_id
    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 4
    only_critical_addons_enabled = true
    upgrade_settings { max_surge = "33%" }
    node_labels = { workload = "system" }
    tags        = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    outbound_type     = "userAssignedNATGateway"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.app_node_vm_size
  vnet_subnet_id        = var.node_subnet_id
  auto_scaling_enabled  = true
  min_count             = var.app_node_min
  max_count             = var.app_node_max
  upgrade_settings { max_surge = "33%" }
  node_labels = { workload = "apps" }
  tags        = var.tags
}
