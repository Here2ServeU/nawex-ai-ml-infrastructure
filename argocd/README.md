# ArgoCD GitOps (alternative to FluxCD)

This directory provides an **ArgoCD-based** reconciliation path for the same clusters and workloads that [`flux/`](../flux/) reconciles.

The platform supports either tool — pick one per cluster. Both consume the same [Helm charts](../helm/charts/) and target the same namespaces, so swapping is non-destructive.

```
argocd/
├── install/                  # ArgoCD self-install manifests (per cluster, run once)
├── projects/                 # AppProject definitions (RBAC + source/destination scopes)
├── infrastructure/           # Application manifests for cluster-wide platform components
└── clusters/                 # Per-cluster app-of-apps roots
    ├── dev-eks/
    ├── staging-gke/
    └── prod-aks/
```

## Bootstrap

```bash
# 1. Install ArgoCD into the target cluster
kubectl apply -k argocd/install/

# 2. Wait for the control plane to come up
kubectl -n argocd rollout status deploy/argocd-server --timeout=5m

# 3. Apply the AppProject and the cluster's root Application (app-of-apps)
kubectl apply -f argocd/projects/rag-platform.yaml
kubectl apply -f argocd/clusters/dev-eks/root-app.yaml

# 4. Verify
argocd app list
argocd app get rag-platform-dev-eks
```

The root Application reconciles the rest of `argocd/clusters/dev-eks/` and `argocd/infrastructure/`, which in turn deploy the same Helm charts that Flux would deploy.

## Promotion

Image promotion uses the [argocd-image-updater](https://argocd-image-updater.readthedocs.io/) annotations in `argocd/clusters/<env>/apps.yaml`:

- `dev-eks` follows `^v0\..*` (any pre-release).
- `staging-gke` follows strict `0.x` semver.
- `prod-aks` follows `>=v1.0.0` only.

Image updater commits the new tag back to this repo on `main`; the cluster Application then syncs.

## Rollback

`git revert <promotion commit>` — ArgoCD will reconcile back to the prior tag automatically. For an immediate rollback: `argocd app rollback rag-api-prod <revision>`.

## Choosing between Flux and ArgoCD

| | FluxCD | ArgoCD |
| --- | --- | --- |
| UI | None (CLI + dashboards) | Built-in web UI |
| Image automation | First-party (`image-reflector`/`image-automation`) | `argocd-image-updater` add-on |
| Multi-tenancy | Kustomization sources + RBAC | `AppProject` + SSO/RBAC |
| Bootstrap | `flux bootstrap` | `kubectl apply -k argocd/install/` |
| Reconciliation model | Pull, per-Kustomization interval | Pull, per-Application interval |

Both are first-class in this repo. Flux is the default in the docs (`make flux-bootstrap`); ArgoCD is wired up under `make argocd-bootstrap` for teams that prefer the UI-driven workflow.
