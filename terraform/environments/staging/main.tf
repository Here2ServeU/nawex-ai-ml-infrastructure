locals {
  env          = "staging"
  cluster_name = "rag-staging-gke"
  region       = "us-central1"

  labels = {
    env         = local.env
    project     = "rag-platform"
    owner       = "platform-team"
    cost_center = "engineering"
    managed_by  = "terraform"
  }
}

provider "google" {
  project = var.project_id
  region  = local.region
}

resource "google_compute_network" "vpc" {
  name                    = "${local.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "nodes" {
  name          = "${local.cluster_name}-nodes"
  ip_cidr_range = "10.30.0.0/20"
  region        = local.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.32.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.36.0.0/20"
  }

  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "${local.cluster_name}-router"
  region  = local.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = local.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

module "gke" {
  source              = "../../modules/gke"
  project_id          = var.project_id
  cluster_name        = local.cluster_name
  region              = local.region
  network             = google_compute_network.vpc.name
  subnetwork          = google_compute_subnetwork.nodes.name
  pods_range_name     = "pods"
  services_range_name = "services"

  master_authorized_cidrs = [
    for c in var.admin_cidrs : { name = "admin", cidr = c }
  ]

  app_node_min          = 2
  app_node_max          = 10
  deletion_protection   = false # staging only
  labels                = local.labels
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

module "observability" {
  source                 = "../../modules/observability-stack"
  storage_class          = "standard-rwo"
  grafana_admin_password = var.grafana_admin_password

  depends_on = [module.gke]
}
