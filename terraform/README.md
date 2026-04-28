# Terraform

Infrastructure as Code for the RAG platform's multi-cloud Kubernetes footprint.

## Layout

```
terraform/
├── modules/
│   ├── eks/                  # AWS EKS cluster + managed node groups + IRSA
│   ├── gke/                  # GCP GKE Autopilot/Standard + Workload Identity
│   ├── aks/                  # Azure AKS + Workload Identity
│   ├── vpc-aws/              # VPC + public/private subnets + NAT
│   ├── network-gcp/          # VPC + subnets + Cloud NAT
│   ├── network-azure/        # VNet + subnets + NAT gateway
│   └── observability-stack/  # Helm releases for kube-prometheus-stack + Loki + Tempo
└── environments/
    ├── dev/                  # AWS (EKS) — us-east-1
    ├── staging/              # GCP (GKE) — us-central1
    └── prod/                 # Azure (AKS) — eastus2
```

## Conventions

- Each environment is a self-contained root module with its own remote state backend.
- Modules accept a `tags` / `labels` map and apply it to every taggable resource. Required keys: `env`, `owner`, `cost-center`, `managed-by=terraform`.
- Cluster outputs are written to a Terraform output and consumed by FluxCD bootstrap (see `Makefile`).
- Versions are pinned in `versions.tf` per environment.

## State

Production-grade state backends are configured per environment:

| Env | Backend |
| --- | --- |
| `dev` | AWS S3 + DynamoDB lock table |
| `staging` | GCS bucket with object versioning |
| `prod` | Azure Storage Account with blob locking |

The backend blocks are stubbed; fill in the bucket/account names before running `terraform init`.
