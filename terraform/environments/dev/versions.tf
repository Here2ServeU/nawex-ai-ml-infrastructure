terraform {
  required_version = ">= 1.6"
  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 5.40" }
    helm       = { source = "hashicorp/helm", version = ">= 2.13" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.30" }
    tls        = { source = "hashicorp/tls", version = ">= 4.0" }
  }

  backend "s3" {
    bucket         = "REPLACE-with-tfstate-bucket"
    key            = "rag-platform/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-locks"
    encrypt        = true
  }
}
