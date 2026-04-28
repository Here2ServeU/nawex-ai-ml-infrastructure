"""Ingest pipeline: chunk -> embed -> upsert. MLflow tracks each run."""

from __future__ import annotations

import time

import mlflow
import structlog

from .chunker import chunk_text
from .config import Settings
from .embedder import HTTPEmbedder
from .metrics import DOCUMENTS_INDEXED, INGEST_LAG, JOBS_TOTAL
from .store import VectorStore

log = structlog.get_logger()


class IngestPipeline:
    def __init__(
        self,
        settings: Settings,
        embedder: HTTPEmbedder,
        store: VectorStore,
    ) -> None:
        self.settings = settings
        self.embedder = embedder
        self.store = store
        mlflow.set_tracking_uri(settings.mlflow_tracking_uri)
        mlflow.set_experiment(settings.mlflow_experiment)

    def run(self, document_id: str, text: str, submitted_at: float | None = None) -> int:
        """Index a single document. Returns chunks indexed.

        `submitted_at` is the Unix timestamp at which the document was
        submitted; used to record the end-to-end ingest lag for the
        freshness SLO.
        """
        with mlflow.start_run(run_name=f"ingest:{document_id}"):
            mlflow.log_params(
                {
                    "document_id": document_id,
                    "chunk_size": self.settings.chunk_size,
                    "chunk_overlap": self.settings.chunk_overlap,
                    "embedder_endpoint": self.settings.embedder_endpoint,
                    "embedder_batch_size": self.settings.embedder_batch_size,
                }
            )
            try:
                chunks = list(
                    chunk_text(
                        document_id,
                        text,
                        chunk_size=self.settings.chunk_size,
                        overlap=self.settings.chunk_overlap,
                    )
                )
                mlflow.log_metric("chunks", len(chunks))
                if not chunks:
                    JOBS_TOTAL.labels(status="ok").inc()
                    return 0

                embeddings = self.embedder.embed([c.text for c in chunks])
                indexed = self.store.upsert(chunks, embeddings)
                DOCUMENTS_INDEXED.inc(indexed)
                mlflow.log_metric("indexed", indexed)

                if submitted_at is not None:
                    INGEST_LAG.observe(time.time() - submitted_at)

                JOBS_TOTAL.labels(status="ok").inc()
                log.info("ingest.ok", document_id=document_id, indexed=indexed)
                return indexed
            except Exception as e:
                JOBS_TOTAL.labels(status="failed").inc()
                mlflow.log_param("error", repr(e))
                log.error("ingest.failed", document_id=document_id, err=repr(e))
                raise
