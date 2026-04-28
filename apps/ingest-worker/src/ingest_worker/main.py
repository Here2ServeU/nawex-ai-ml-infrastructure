"""Process entrypoint: starts the metrics/health server and the work loop."""

from __future__ import annotations

import logging
import signal
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import structlog
from prometheus_client import generate_latest
from prometheus_client.exposition import CONTENT_TYPE_LATEST

from .config import Settings


def _configure_logging(level: str) -> None:
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        stream=sys.stdout,
        format="%(message)s",
    )
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, level.upper(), logging.INFO)
        ),
    )


class _Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):  # noqa: A002 - silence default access log
        return

    def do_GET(self):  # noqa: N802
        if self.path == "/metrics":
            body = generate_latest()
            self.send_response(200)
            self.send_header("Content-Type", CONTENT_TYPE_LATEST)
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path in {"/healthz", "/readyz"}:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return
        self.send_response(404)
        self.end_headers()


def _serve_metrics(port: int = 9090) -> ThreadingHTTPServer:
    server = ThreadingHTTPServer(("0.0.0.0", port), _Handler)
    t = threading.Thread(target=server.serve_forever, name="metrics", daemon=True)
    t.start()
    return server


def main() -> int:
    settings = Settings()
    _configure_logging(settings.log_level)
    log = structlog.get_logger()
    log.info("ingest_worker.start", endpoint=settings.embedder_endpoint)

    metrics = _serve_metrics()

    stop = threading.Event()
    signal.signal(signal.SIGINT, lambda *_: stop.set())
    signal.signal(signal.SIGTERM, lambda *_: stop.set())

    # Hot loop placeholder. In production this consumes from a queue
    # (Pub/Sub, SQS, Service Bus) and dispatches into IngestPipeline.run.
    # The main() entrypoint is kept thin so unit tests target IngestPipeline
    # directly rather than the runtime wiring.
    stop.wait()
    log.info("ingest_worker.shutdown")
    metrics.shutdown()
    return 0


if __name__ == "__main__":
    sys.exit(main())
