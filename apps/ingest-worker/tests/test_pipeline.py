from collections.abc import Iterable
from unittest.mock import MagicMock

import mlflow
import pytest

from ingest_worker.chunker import Chunk
from ingest_worker.config import Settings
from ingest_worker.pipeline import IngestPipeline


class FakeEmbedder:
    def __init__(self, dim: int = 4) -> None:
        self.dim = dim
        self.calls = 0

    def embed(self, texts):
        self.calls += 1
        return [[0.1] * self.dim for _ in texts]


class FakeStore:
    def __init__(self) -> None:
        self.upserted: list[Chunk] = []

    def upsert(self, chunks: Iterable[Chunk], embeddings: list[list[float]]) -> int:
        chunks_list = list(chunks)
        self.upserted.extend(chunks_list)
        return len(chunks_list)


@pytest.fixture(autouse=True)
def _no_mlflow(monkeypatch, tmp_path):
    """Use a local file-store MLflow tracking URI so tests don't hit the network."""
    monkeypatch.setenv("MLFLOW_TRACKING_URI", f"file://{tmp_path}/mlruns")
    mlflow.set_tracking_uri(f"file://{tmp_path}/mlruns")


def test_pipeline_indexes_chunks():
    s = Settings()
    p = IngestPipeline(s, FakeEmbedder(), FakeStore())
    n = p.run("doc-1", "hello world. " * 200, submitted_at=None)
    assert n > 0


def test_pipeline_increments_failed_metric_on_embedder_error():
    class BoomEmbedder:
        def embed(self, texts):
            raise RuntimeError("boom")

    s = Settings()
    p = IngestPipeline(s, BoomEmbedder(), FakeStore())
    with pytest.raises(RuntimeError):
        p.run("doc-1", "hello", submitted_at=None)


def test_pipeline_handles_empty_text():
    s = Settings()
    store = FakeStore()
    p = IngestPipeline(s, FakeEmbedder(), store)
    assert p.run("doc-1", "", submitted_at=None) == 0
    assert store.upserted == []
