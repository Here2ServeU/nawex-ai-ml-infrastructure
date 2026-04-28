# ADR 0001: Multi-cloud strategy

- **Status:** Accepted
- **Date:** 2026-01-15

## Context

The platform must run on AWS, GCP, and Azure to honor enterprise customer cloud preferences and to avoid lock-in. We have to decide how "multi-cloud" the platform really is.

## Decision

We adopt **portable, single-cloud-per-deployment**, not active/active multi-cloud:

- Every cluster lives entirely in one cloud (one EKS, one GKE, one AKS).
- The application data plane (rag-api, ingest-worker, vector DB) is identical across clouds — same Helm charts, same FluxCD manifests.
- Cloud-specific concerns (load balancers, DNS, secret stores, IAM) are abstracted behind cloud-neutral controllers (External Secrets, ingress-nginx, cert-manager) so that switching clouds means swapping a Terraform module, not rewriting the platform.

We explicitly do **not** attempt:
- Cross-cloud Kubernetes federation
- Cross-cloud vector-DB replication
- Cross-cloud disaster recovery (DR is intra-cloud, multi-AZ)

## Consequences

**Positive**
- Lower operational complexity. Every team can reason about a single cluster at a time.
- Customer-facing portability: a SOC2 customer that mandates Azure gets the same product without compromise.
- Cloud-vendor leverage: pricing negotiations are credible.

**Negative**
- We can't sell "the platform survives an entire cloud going down" — but no enterprise customer has actually asked for that, and the engineering cost would be enormous.
- Some incident response is duplicated across clouds (three sets of runbooks for cloud-specific issues like NAT exhaustion).

## Alternatives considered

- **Cross-cloud federation (KubeFed)**: rejected — operational burden too high for the value.
- **Single cloud only**: rejected — gates major customer segments.
