locals {
  env          = "dev"
  cluster_name = "rag-dev-eks"
  region       = "us-east-1"

  tags = {
    env          = local.env
    project      = "rag-platform"
    owner        = "platform-team"
    "cost-center" = "engineering"
    "managed-by" = "terraform"
  }
}

provider "aws" {
  region = local.region

  default_tags { tags = local.tags }
}

module "vpc" {
  source       = "../../modules/vpc-aws"
  name         = local.cluster_name
  cluster_name = local.cluster_name
  cidr         = "10.20.0.0/16"
  az_count     = 3
  tags         = local.tags
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = local.cluster_name
  kubernetes_version = "1.30"
  subnet_ids         = module.vpc.private_subnet_ids

  endpoint_public_access = true
  public_access_cidrs    = var.admin_cidrs

  app_node_instance_types = ["m6i.xlarge"]
  app_node_min            = 2
  app_node_max            = 10
  app_node_desired        = 2

  tags = local.tags
}

# Configure Helm + Kubernetes providers using cluster outputs.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

module "observability" {
  source                  = "../../modules/observability-stack"
  storage_class           = "gp3"
  grafana_admin_password  = var.grafana_admin_password

  depends_on = [module.eks]
}
