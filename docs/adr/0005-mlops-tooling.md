# ADR 0005: MLOps tooling — MLflow + Airflow (KubeFlow deferred)

- **Status:** Accepted
- **Date:** 2026-02-26

## Context

The platform serves an AI/ML product. We need to track which model version produced which embeddings, replay ingest runs deterministically, and orchestrate batch ingest jobs. The candidate tools:

- **MLflow** — model registry + experiment tracking
- **Airflow** — generic DAG orchestration
- **KubeFlow** — opinionated end-to-end ML platform on Kubernetes
- **Ray** — distributed compute for training and online serving

## Decision

Adopt **MLflow + Airflow** now. Defer KubeFlow and Ray.

- MLflow: every ingest run logs to MLflow with `(model_version, doc count, indexed count, runtime, error)`. Cheap to operate (single Postgres + object store) and gives ML and platform engineers a shared view of what shipped.
- Airflow: existing org expertise; ingest scheduling is naturally DAG-shaped.
- KubeFlow / Ray: revisit when (a) we own model training in-cluster — currently outsourced to a managed model service — and (b) we need distributed inference workers larger than what KEDA + Deployment can express.

## Consequences

- We don't get KubeFlow's pipeline UI; Airflow's UI is acceptable for now.
- We lose Ray's distributed inference capabilities — the model server (KServe / Triton) handles scale-out today.
