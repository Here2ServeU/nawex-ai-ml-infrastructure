# ingest-worker (Python)

Document ingest pipeline for the RAG platform. Chunks documents, calls a remote embedder, upserts vectors into Qdrant, and records every run to MLflow.

## Layout

```
apps/ingest-worker/
├── pyproject.toml
├── src/ingest_worker/
│   ├── chunker.py      # Idempotent content-hash chunking
│   ├── embedder.py     # Remote embedder client with retry/jitter
│   ├── store.py        # Qdrant adapter
│   ├── pipeline.py     # chunk -> embed -> upsert, with MLflow run tracking
│   ├── metrics.py      # Prometheus counters / gauges / histograms
│   ├── config.py       # pydantic-settings env loader
│   └── main.py         # Process entrypoint + /metrics, /healthz, /readyz
├── tests/              # pytest unit tests
├── airflow/dags/       # ingest DAG (every 15m)
├── Dockerfile
└── docker-compose.yaml # qdrant + mlflow + airflow + worker for local dev
```

## Run locally

```bash
docker compose up --build
```

Then:

- Airflow UI:  http://localhost:8080
- MLflow UI:   http://localhost:5000
- Qdrant:      http://localhost:6333
- Worker /metrics:  http://localhost:9090/metrics

## Test

```bash
pip install -e ".[dev]"
pytest -q
ruff check . && ruff format --check .
```

## Production wiring

The worker runs as a Deployment (see `helm/charts/ingest-worker`) and is scaled by KEDA against Prometheus queue-depth metrics. Airflow lives in its own namespace and triggers the worker by writing to the queue, or by calling the worker's task entrypoint directly.

Idempotency comes from `chunker._stable_id`: chunk IDs are SHA-256 derived from `document_id + ordinal + text`, so re-running a job converges on the same point set in Qdrant.
