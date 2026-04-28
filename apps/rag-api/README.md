# rag-api (Go)

HTTP API that turns a user query into a ranked list of retrieved documents.

## Endpoints

| Method | Path | Description |
| --- | --- | --- |
| GET | `/healthz` | Liveness — always 200 once the process is up. |
| GET | `/readyz` | Readiness — 200 when downstream config validates. |
| POST | `/v1/query` | `{ "query": "...", "top_k": 8 }` → ranked `documents`. |
| GET | `/metrics` (port 9090) | Prometheus metrics. |

## Configuration (env vars)

| Var | Default |
| --- | --- |
| `LOG_LEVEL` | `info` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | _(unset = no tracing)_ |
| `VECTOR_DB_ADDRESS` | `qdrant.qdrant.svc.cluster.local:6334` |
| `VECTOR_DB_COLLECTION` | `documents` |
| `EMBEDDER_ENDPOINT` | `http://embedder.ml.svc.cluster.local/embed` |
| `EMBEDDER_TIMEOUT_MS` | `1500` |
| `RETRIEVAL_TOP_K` | `8` |
| `RETRIEVAL_CONTEXT_TOKENS` | `4096` |

## Local run

```bash
go run ./cmd/server
curl -s -XPOST localhost:8080/v1/query -d '{"query":"how do I rotate keys?"}'
```

## Test

```bash
go test -race -count=1 ./...
```

## Production wiring

- The Qdrant client in `internal/retrieval/qdrant.go` is intentionally a stub so this module vendors cleanly without grpc/qdrant deps. To wire production, depend on `github.com/qdrant/go-client` and replace `Search` with the gRPC call. Tests use `retrieval.NewWithDeps` to inject fakes and don't depend on the real client.
- The embedder client speaks JSON to a model server (KServe / Triton with the OpenAI-compatible adaptor, or any HTTP embedder).
- Tracing emits OTLP/gRPC to whatever endpoint `OTEL_EXPORTER_OTLP_ENDPOINT` points at — typically the OTel collector or Tempo's OTLP ingest.

## Image

```bash
docker build -t ghcr.io/your-org/rag-api:dev .
```

The image is distroless static, runs as UID 65532, exposes 8080 (HTTP) and 9090 (metrics).
