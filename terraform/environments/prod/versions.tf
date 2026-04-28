terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = ">= 3.110" }
    helm       = { source = "hashicorp/helm", version = ">= 2.13" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.30" }
  }

  backend "azurerm" {
    resource_group_name  = "REPLACE-tfstate-rg"
    storage_account_name = "REPLACEtfstateaccount"
    container_name       = "tfstate"
    key                  = "rag-platform/prod.tfstate"
  }
}
