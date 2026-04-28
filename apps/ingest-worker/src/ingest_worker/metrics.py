from prometheus_client import Counter, Gauge, Histogram

JOBS_TOTAL = Counter(
    "ingest_jobs_total",
    "Ingest jobs processed.",
    labelnames=("status",),  # ok | failed
)

DOCUMENTS_INDEXED = Counter(
    "ingest_documents_indexed_total",
    "Documents indexed into the vector DB.",
)

QUEUE_DEPTH = Gauge(
    "ingest_queue_depth",
    "Pending ingest jobs awaiting processing.",
    labelnames=("queue",),
)

INGEST_LAG = Histogram(
    "ingest_lag_seconds",
    "Lag between document submission and indexing.",
    buckets=(1, 5, 30, 60, 300, 600, 900, 1800, 3600),
)

EMBED_LATENCY = Histogram(
    "ingest_embed_duration_seconds",
    "Embedding call latency.",
    buckets=(0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10),
)
