output "cluster_name" {
  value = module.gke.cluster_name
}

output "kubeconfig_command" {
  value = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${local.region} --project ${var.project_id}"
}

output "workload_pool" {
  value = module.gke.workload_pool
}
