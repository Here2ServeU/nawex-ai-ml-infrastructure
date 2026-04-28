# Runbook: rag-api high latency (p95)

Linked alert: `RagApiHighLatencyP95` (p95 > 1.5s for 10 min)

## Decision tree

1. **Embedder slow?** — `rag_api_embedder_duration_seconds` p95 > 500ms?
   → page model-serving; consider raising the embedder timeout *only* with their concurrence (don't paper over).
2. **Vector DB slow?** — `rag_api_vector_db_duration_seconds` p95 > 200ms?
   → check Qdrant CPU/memory saturation, look for ongoing compaction.
3. **Saturation?** — `rag_api_in_flight_requests` ≈ replicas × maxConn?
   → bump HPA min replicas via Flux PR; verify cluster-autoscaler can satisfy.
4. **Cold start?** — recent rollout in the last 10 min and pod count > 2× steady state?
   → ride it out; the `scaleDown.stabilizationWindowSeconds` will settle it.

## Mitigation choices

| Symptom | Action |
| --- | --- |
| Embedder p95 > 500ms | Page model-serving; do not silently raise the timeout. |
| Qdrant CPU > 80% | Manually scale the Qdrant StatefulSet replicas; see [vector-db-oom.md](vector-db-oom.md). |
| API saturated, headroom exists | Edit `flux/clusters/<env>/apps.yaml` → `autoscaling.minReplicas`, push. |
| Cluster autoscaler stuck | Check `cluster-autoscaler` pod logs for `NotTriggerScaleUp` events. |

## Permanent fixes (post-incident)

- Add a vector-DB call-budget per request and short-circuit retrieval when budget is exceeded.
- Move the embedder to a smaller / quantized model if quality permits.
- Consider a result cache keyed on `(model_version, query_hash)`.
