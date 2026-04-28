"""Airflow DAG that drives the ingest pipeline.

This DAG is intentionally infrastructure-light: it lists new documents in an
object store, fans out one task per document, and lets each task call into the
ingest worker through a thin Python operator. The worker handles chunking,
embedding, and upsert; MLflow records each run.
"""

from __future__ import annotations

import os
import time
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

DEFAULT_ARGS = {
    "owner": "platform-team",
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
    "execution_timeout": timedelta(minutes=20),
}


def list_new_documents(**_):
    """Replace with a hook to S3/GCS/Blob. Returns a list of (doc_id, uri)."""
    return []


def ingest_one(doc_id: str, uri: str, **_):
    from ingest_worker.config import Settings
    from ingest_worker.embedder import HTTPEmbedder
    from ingest_worker.pipeline import IngestPipeline
    from ingest_worker.store import QdrantStore

    s = Settings()
    embedder = HTTPEmbedder(s.embedder_endpoint, batch_size=s.embedder_batch_size)
    store = QdrantStore(s.vector_db_address, s.vector_db_collection)
    pipeline = IngestPipeline(s, embedder, store)

    with open(uri, "r", encoding="utf-8") as f:
        text = f.read()
    submitted_at = float(os.environ.get("INGEST_SUBMITTED_AT", time.time()))
    pipeline.run(doc_id, text, submitted_at=submitted_at)


with DAG(
    dag_id="rag_ingest",
    description="Chunk, embed, and index new documents into the RAG vector DB.",
    default_args=DEFAULT_ARGS,
    schedule="*/15 * * * *",  # every 15 minutes
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["rag", "ingest"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    list_docs = PythonOperator(
        task_id="list_new_documents",
        python_callable=list_new_documents,
    )

    # In a real DAG, list_docs.output feeds an expand() over PythonOperator.
    # Here we wire the structure; the operator body would be expanded at runtime.
    ingest = PythonOperator(
        task_id="ingest_one",
        python_callable=ingest_one,
        op_kwargs={"doc_id": "{{ params.doc_id }}", "uri": "{{ params.uri }}"},
    )

    start >> list_docs >> ingest >> end
