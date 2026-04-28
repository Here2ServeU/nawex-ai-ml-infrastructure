"""Whitespace-aware text chunker.

A real ingest pipeline would use semantic / token-based chunkers (e.g.
`tiktoken` aware), but for the platform demo we use a deterministic
character-window chunker with overlap. Chunk IDs are derived from a content
hash so re-runs converge (idempotency).
"""

from __future__ import annotations

import hashlib
from collections.abc import Iterator
from dataclasses import dataclass


@dataclass(frozen=True)
class Chunk:
    id: str
    text: str
    document_id: str
    ordinal: int


def chunk_text(
    document_id: str,
    text: str,
    *,
    chunk_size: int = 800,
    overlap: int = 100,
) -> Iterator[Chunk]:
    if chunk_size <= 0:
        raise ValueError("chunk_size must be positive")
    if overlap < 0 or overlap >= chunk_size:
        raise ValueError("overlap must be in [0, chunk_size)")

    text = text.strip()
    if not text:
        return

    step = chunk_size - overlap
    ordinal = 0
    for start in range(0, len(text), step):
        slice_ = text[start : start + chunk_size]
        if not slice_:
            break
        cid = _stable_id(document_id, ordinal, slice_)
        yield Chunk(id=cid, text=slice_, document_id=document_id, ordinal=ordinal)
        ordinal += 1
        if start + chunk_size >= len(text):
            break


def _stable_id(document_id: str, ordinal: int, text: str) -> str:
    h = hashlib.sha256()
    h.update(document_id.encode())
    h.update(b"\x00")
    h.update(str(ordinal).encode())
    h.update(b"\x00")
    h.update(text.encode())
    return h.hexdigest()[:32]
