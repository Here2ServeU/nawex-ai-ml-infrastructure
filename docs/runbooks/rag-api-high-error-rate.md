# Runbook: rag-api high error rate

Linked alert: `RagApiHighErrorRate` (5xx ratio > 2% for 10 min)

## TL;DR

1. Check whether the spike is a single status code (500 vs 502 vs 503) — that determines the layer.
2. If 502/503, dependency is the cause: vector DB or embedder.
3. If 500, app code is the cause — check recent deploys.

## Quick checks (under 2 minutes)

```bash
kubectl -n rag get hr rag-api    # last reconciled tag and status
kubectl -n rag rollout status deploy/rag-api
kubectl -n rag logs deploy/rag-api --tail=100 | jq -r 'select(.level=="ERROR")'
```

Grafana dashboard: **RAG API — Golden Signals** → "Error ratio" panel, break down by status.

## Diagnosis

### 502 / 503 — downstream dependency

Look at:
- `rag_api_vector_db_duration_seconds` — is the p95 spiking?
- `rag_api_embedder_duration_seconds{outcome="error"}` — is the embedder failing?
- `kube_pod_status_ready{namespace="qdrant"}` — are vector DB replicas Ready?

Likely actions:
- **Embedder unreachable**: page the model-serving on-call; consider failing open to a stub embedder *only* if explicitly approved.
- **Qdrant unhealthy**: see [vector-db-oom.md](vector-db-oom.md).

### 500 — app crash / unhandled error

```bash
kubectl -n rag logs deploy/rag-api --tail=500 | jq -r 'select(.level=="ERROR")' | head -50
```

If a recent deploy correlates: revert via Flux.

```bash
git revert <promotion-commit-sha>
git push
flux reconcile kustomization flux-system
```

## Mitigation

If burn rate is fast and no clear fix in 10 min:

```bash
# Cap traffic at the ingress to drop excess load.
kubectl -n ingress-nginx annotate ingress rag-api \
  nginx.ingress.kubernetes.io/limit-rps="50" --overwrite
```

## Post-incident

- Update this runbook with anything that surprised you.
- File a postmortem ticket with the SEV level, customer impact, and 5-whys.
