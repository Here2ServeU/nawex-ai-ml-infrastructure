output "cluster_name" {
  value = module.aks.cluster_name
}

output "kubeconfig_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name}"
}

output "oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}
