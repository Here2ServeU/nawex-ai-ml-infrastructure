# FluxCD GitOps (default)

This directory is the FluxCD reconciliation tree. It is the **default** GitOps path; an equivalent ArgoCD tree lives in [`../argocd/`](../argocd/) for teams that prefer the UI-driven workflow. Pick one per cluster — both consume the same [Helm charts](../helm/charts/).

```
flux/
├── clusters/                  # Per-cluster entrypoints (one Kustomization root each)
│   ├── dev-eks/
│   ├── staging-gke/
│   └── prod-aks/
└── infrastructure/            # Cluster-wide platform components, shared
    ├── sources/               # HelmRepositories, GitRepositories
    ├── controllers/           # cert-manager, ingress-nginx, external-secrets, KEDA
    └── observability/         # kube-prometheus-stack, Loki, Tempo (when not provisioned by Terraform)
```

## Bootstrap

```bash
flux bootstrap git \
  --url=ssh://git@github.com/nawex/devops-ai-ml-infrastructure \
  --branch=main \
  --path=flux/clusters/dev-eks \
  --components-extra=image-reflector-controller,image-automation-controller
```

## Promotion

Image promotion uses Flux's `ImagePolicy` + `ImageRepository` + `ImageUpdateAutomation`:

- `dev-eks` follows the `^v0\\..*` semver range (any pre-release).
- `staging-gke` follows `^0\\..* || ^v0\\..*` strict semver.
- `prod-aks` follows `>=v1.0.0` only.

A new image tag is detected by the image reflector, the matching policy picks the next allowed version, and the image automation controller opens a commit on `main` that updates the relevant Kustomization. The cluster Kustomization then reconciles the new tag.

## Rollback

`git revert <promotion commit>` — the cluster will reconcile back to the prior tag automatically.
