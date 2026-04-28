# ADR 0003: Observability stack

- **Status:** Accepted
- **Date:** 2026-02-05

## Context

We want a single, vendor-agnostic observability stack across AWS, GCP, and Azure. Cloud-native options (CloudWatch, Stackdriver, Azure Monitor) lock us in and split engineers' attention three ways. A managed SaaS (Datadog, New Relic) is easier to run but is a multi-million-dollar line item at our scale and exfiltrates customer data.

## Decision

Self-host the **kube-prometheus-stack + Loki + Tempo** trio in every cluster, with the option to remote-write metrics to a central Mimir / Cortex tier when we exceed single-cluster Prometheus retention needs.

- Metrics:  Prometheus (kube-prometheus-stack)
- Logs:     Loki (Promtail agent on every node)
- Traces:   Tempo (OpenTelemetry collector)
- Dashboards: Grafana, dashboards as JSON in Git, loaded via the Grafana sidecar
- SLOs:    Sloth-format YAML compiled to PrometheusRules in CI

We accept that we run our own observability — that is the price of portability.

## Consequences

**Positive**
- Zero vendor data exfiltration; every byte of telemetry stays in customer-owned cloud accounts.
- Same query language and dashboards in every cluster.
- Cost scales with usage we control, not with seat count.

**Negative**
- We are responsible for storage sizing, retention, and HA of the observability tier itself.
- Long-term metric retention requires a remote-write tier (deferred until single-cluster needs are exceeded).

## Alternatives considered

- **Cloud-native per cluster**: rejected for the engineer-attention split and the loss of cross-cluster query.
- **Datadog**: rejected on cost and data-residency concerns.
