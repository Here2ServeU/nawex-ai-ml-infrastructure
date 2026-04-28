# ADR 0002: Continuous delivery with FluxCD

- **Status:** Accepted
- **Date:** 2026-01-22

## Context

We need a continuous delivery model for ~3 clusters and growing, that is:
- Auditable (every change reviewable as a PR)
- Reversible (any change `git revert`-able)
- Cluster-pull rather than CI-push (CI must not need cluster credentials)

The two leading options are FluxCD and ArgoCD.

## Decision

Use **FluxCD v2**.

Drivers:
- Small surface area: each capability is its own controller (Source, Kustomize, Helm, Image Reflector, Image Automation), so we adopt only what we need.
- Native image-update automation produces commits to the same Git repo, keeping the audit trail in one place.
- Multi-tenant Kustomization model fits our cluster topology (per-cluster directory under `flux/clusters/`).

## Consequences

**Positive**
- CI never holds cluster kubeconfigs. Image build/push only.
- Promotion is a commit, rollback is a `git revert`.
- Drift is auto-corrected on the reconciliation interval.

**Negative**
- No graphical UI out of the box (we run the Capacitor sidecar for read-only dashboards).
- Learning curve: engineers need to think in terms of Kustomizations and dependsOn DAGs rather than imperative `kubectl apply`.

## Alternatives considered

- **ArgoCD**: also fine; rejected on the basis that we're a small platform team and prefer Flux's smaller, more composable surface.
- **Push-from-CI**: rejected — requires CI to hold cluster credentials, which violates least privilege.
