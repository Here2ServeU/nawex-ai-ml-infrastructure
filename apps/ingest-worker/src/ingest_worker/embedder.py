from __future__ import annotations

import time
from typing import Sequence

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential_jitter,
)

from .metrics import EMBED_LATENCY


class EmbedderError(RuntimeError):
    pass


class HTTPEmbedder:
    """Speaks JSON to a remote model server.

    POST {endpoint}  body: {"texts": [...]}  -> {"embeddings": [[...], [...]]}
    """

    def __init__(self, endpoint: str, batch_size: int = 32, timeout: float = 5.0) -> None:
        self.endpoint = endpoint
        self.batch_size = batch_size
        self._client = httpx.Client(timeout=timeout)

    def close(self) -> None:
        self._client.close()

    @retry(
        retry=retry_if_exception_type((httpx.TransportError, httpx.HTTPStatusError)),
        wait=wait_exponential_jitter(initial=0.2, max=3.0),
        stop=stop_after_attempt(4),
        reraise=True,
    )
    def _post(self, texts: Sequence[str]) -> list[list[float]]:
        start = time.perf_counter()
        try:
            resp = self._client.post(self.endpoint, json={"texts": list(texts)})
            resp.raise_for_status()
            payload = resp.json()
        finally:
            EMBED_LATENCY.observe(time.perf_counter() - start)
        embeddings = payload.get("embeddings")
        if not isinstance(embeddings, list) or not embeddings:
            raise EmbedderError("embedder returned no embeddings")
        return embeddings

    def embed(self, texts: Sequence[str]) -> list[list[float]]:
        if not texts:
            return []
        out: list[list[float]] = []
        for i in range(0, len(texts), self.batch_size):
            batch = texts[i : i + self.batch_size]
            out.extend(self._post(batch))
        return out
