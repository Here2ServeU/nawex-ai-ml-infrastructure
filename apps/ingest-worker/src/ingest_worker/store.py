"""Thin Qdrant client wrapper that upserts chunks idempotently."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Protocol

from .chunker import Chunk


class VectorStore(Protocol):
    def upsert(self, chunks: Iterable[Chunk], embeddings: list[list[float]]) -> int: ...


class QdrantStore:
    def __init__(self, address: str, collection: str) -> None:
        # Lazy import keeps the module test-friendly without the dep.
        from qdrant_client import QdrantClient
        from qdrant_client.http.models import Distance, VectorParams

        host, _, port = address.partition(":")
        self._client = QdrantClient(host=host, grpc_port=int(port or 6334), prefer_grpc=True)
        self._collection = collection
        self._VectorParams = VectorParams
        self._Distance = Distance

    def ensure_collection(self, dim: int) -> None:
        existing = {c.name for c in self._client.get_collections().collections}
        if self._collection not in existing:
            self._client.create_collection(
                collection_name=self._collection,
                vectors_config=self._VectorParams(size=dim, distance=self._Distance.COSINE),
            )

    def upsert(self, chunks: Iterable[Chunk], embeddings: list[list[float]]) -> int:
        from qdrant_client.http.models import PointStruct

        chunks_list = list(chunks)
        if len(chunks_list) != len(embeddings):
            raise ValueError("chunks and embeddings length mismatch")
        if not chunks_list:
            return 0

        self.ensure_collection(len(embeddings[0]))
        points = [
            PointStruct(
                id=c.id,
                vector=emb,
                payload={"document_id": c.document_id, "ordinal": c.ordinal, "text": c.text},
            )
            for c, emb in zip(chunks_list, embeddings, strict=True)
        ]
        self._client.upsert(collection_name=self._collection, points=points, wait=True)
        return len(points)
