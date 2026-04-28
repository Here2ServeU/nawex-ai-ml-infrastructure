# ADR 0004: Default storage classes per cloud

- **Status:** Accepted
- **Date:** 2026-02-12

## Decision

Every stateful workload (vector DB, Prometheus, Loki, Tempo) uses the cloud's expandable, SSD-backed storage class as default:

| Cloud | StorageClass | Notes |
| --- | --- | --- |
| AWS  | `gp3` | Default; `allowVolumeExpansion: true`. |
| GCP  | `standard-rwo` | Pd-balanced; expandable. |
| Azure | `managed-csi` | Standard SSD; expandable. Premium variant for prod vector DB. |

This guarantees the `pvc-resizer` self-healing controller can resize without manual intervention, and that capacity tuning is reversible.

## Consequences

- Cost: SSD is the default, but the alternative (HDD) doesn't meet vector-DB latency SLOs anyway.
- Migration: existing workloads on non-expandable classes must be migrated via snapshot / restore (one-time effort, tracked separately).
