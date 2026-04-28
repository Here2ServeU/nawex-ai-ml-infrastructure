# Runbook: Qdrant OOM / high memory

## Symptoms

- `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}` for `qdrant-*`
- Latency on `rag-api` rises in lockstep with Qdrant restarts
- `qdrant_collection_vector_count` flat or growing

## Diagnose

```bash
kubectl -n qdrant top pods
kubectl -n qdrant get statefulset
kubectl -n qdrant logs sts/qdrant --tail=200
```

Check the snapshot CronJob — is a snapshot in progress? Snapshots double the working set briefly.

## Mitigation

1. **Short-term**: bump memory request/limit in `flux/clusters/<env>/apps.yaml`:
   ```yaml
   vector-db:
     resources:
       requests: { memory: 12Gi }
       limits:   { memory: 24Gi }
   ```
   Push, let Flux reconcile, watch `kubectl rollout status sts/qdrant -n qdrant`.

2. **If sustained**: the workload outgrew the shard. Increase `replicaCount` and re-shard offline (Qdrant docs → "moving shards"). Schedule a maintenance window — sharding involves brief read pauses.

## Prevention

- The `pvc-resizer` self-healing controller already grows storage. There is no equivalent yet for memory — that is a follow-up.
- Track collection size as a monthly trend and project the cross-over with current memory budget.
