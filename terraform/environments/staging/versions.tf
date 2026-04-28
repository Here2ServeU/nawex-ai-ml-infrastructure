terraform {
  required_version = ">= 1.6"
  required_providers {
    google     = { source = "hashicorp/google", version = ">= 5.30" }
    helm       = { source = "hashicorp/helm", version = ">= 2.13" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.30" }
  }

  backend "gcs" {
    bucket = "REPLACE-with-tfstate-bucket"
    prefix = "rag-platform/staging"
  }
}
