# Runbooks

Every alert in `helm/charts/*/templates/prometheusrule.yaml` and `observability/prometheus/*.yaml` links to a runbook here via `annotations.runbook_url`. PRs that introduce new alerts must include a runbook.

| Runbook | Linked alert |
| --- | --- |
| [rag-api-high-error-rate](rag-api-high-error-rate.md) | `RagApiHighErrorRate` |
| [rag-api-high-latency](rag-api-high-latency.md) | `RagApiHighLatencyP95`, `RagApiAvailability`, `RagApiLatencyP99` |
| [vector-db-oom](vector-db-oom.md) | qdrant OOM / saturation |
| [pvc-almost-full](pvc-almost-full.md) | `PvcAlmostFull` |
| [node-not-ready](node-not-ready.md) | `KubeNodeNotReady` |

Format: each runbook starts with a one-line "TL;DR" and a 3-step decision tree, then the diagnostic and mitigation procedure. The on-call should be able to act in under 60 seconds from opening the page.
