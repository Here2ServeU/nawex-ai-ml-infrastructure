locals {
  env          = "prod"
  cluster_name = "rag-prod-aks"
  location     = "eastus2"

  tags = {
    env          = local.env
    project      = "rag-platform"
    owner        = "platform-team"
    "cost-center" = "engineering"
    "managed-by" = "terraform"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "rag-prod-rg"
  location = local.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.cluster_name}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  address_space       = ["10.40.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "nodes"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.40.0.0/20"]
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.cluster_name}-laws"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

module "aks" {
  source                     = "../../modules/aks"
  cluster_name               = local.cluster_name
  location                   = local.location
  resource_group_name        = azurerm_resource_group.this.name
  node_subnet_id             = azurerm_subnet.nodes.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  app_node_vm_size = "Standard_D8s_v5"
  app_node_min     = 3
  app_node_max     = 30

  tags = local.tags
}

provider "kubernetes" {
  host                   = yamldecode(module.aks.kube_config).clusters[0].cluster.server
  cluster_ca_certificate = base64decode(yamldecode(module.aks.kube_config).clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(yamldecode(module.aks.kube_config).users[0].user["client-certificate-data"])
  client_key             = base64decode(yamldecode(module.aks.kube_config).users[0].user["client-key-data"])
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(module.aks.kube_config).clusters[0].cluster.server
    cluster_ca_certificate = base64decode(yamldecode(module.aks.kube_config).clusters[0].cluster["certificate-authority-data"])
    client_certificate     = base64decode(yamldecode(module.aks.kube_config).users[0].user["client-certificate-data"])
    client_key             = base64decode(yamldecode(module.aks.kube_config).users[0].user["client-key-data"])
  }
}

module "observability" {
  source                 = "../../modules/observability-stack"
  storage_class          = "managed-csi"
  grafana_admin_password = var.grafana_admin_password

  depends_on = [module.aks]
}
