# Observability

The observability stack is provisioned in two phases:

1. **Terraform** brings up `kube-prometheus-stack`, `loki`, and `tempo` in the `observability` namespace at cluster-create time (so the platform is observable from minute one).
2. **FluxCD** then reconciles the application-specific `PrometheusRule`, SLO definitions, and Grafana dashboards from this directory on every commit.

## Layout

```
observability/
├── prometheus/      # Cluster-wide PrometheusRule manifests
├── slo/             # Sloth-format SLO definitions (compiled to PrometheusRules in CI)
└── grafana/
    └── dashboards/  # JSON dashboards loaded by the Grafana sidecar via configmap-generator
```

## Adding a Grafana dashboard

1. Drop the JSON file under `grafana/dashboards/`.
2. CI generates a ConfigMap labeled `grafana_dashboard=1` per dashboard (the kube-prometheus-stack Grafana sidecar discovers and loads it).

## Adding an SLO

1. Create a Sloth file under `slo/`.
2. The `sloth.yml` GitHub Actions workflow validates and renders it to a PrometheusRule alongside the source. Both files are committed.
3. Flux applies the rendered PrometheusRule on the next reconciliation.

## Golden signals

Every service exposes Prometheus metrics at `/metrics` on port `:9090`:

| Signal | Metric (rag-api example) |
| --- | --- |
| Latency | `rag_api_request_duration_seconds` (histogram) |
| Traffic | `rag_api_requests_total` (counter) |
| Errors | `rag_api_requests_total{status=~"5.."}` |
| Saturation | `rag_api_in_flight_requests` (gauge) |

Tracing uses OpenTelemetry over OTLP/gRPC to the Tempo collector.

## Multi-burn-rate alerting

SLOs compile into the standard Google SRE multi-window, multi-burn-rate alerts (1h / 6h fast burn pages, 24h / 72h slow burn tickets). See `slo/rag-api.slo.yaml`.
