# Self-healing automation

Small, single-purpose controllers that handle the top recurring incidents so the on-call doesn't get woken up for known-class issues.

| Script | Trigger | Action |
| --- | --- | --- |
| `pvc-resizer.go` | PVC > 85% full alert | Patches the PVC `spec.resources.requests.storage` up by 50% (StorageClass must allow expansion). |
| `crashloop-bouncer.sh` | Pod crash-looping > 30m AND OOMKilled | Bumps container memory request by 25% via Helm value override and creates a remediation PR. |
| `qdrant-compactor.go` | Qdrant compaction backlog metric | Triggers an offline compaction RPC against the affected shard. |

All scripts are designed to:
- be **idempotent** — safe to re-run.
- emit Prometheus metrics so we know they ran (`selfheal_actions_total{action,outcome}`).
- write a structured audit log to stdout (JSON) so it ships through Loki.
- fail closed: if anything looks unfamiliar, exit non-zero rather than improvise.

## Running

These run as CronJobs in the `self-healing` namespace, with a service account scoped to only the verbs they need on the resources they touch (no cluster-admin).
