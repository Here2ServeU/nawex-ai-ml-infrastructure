# SLO policy

Service Level Objectives govern release pace and incident severity for the RAG platform. This document is the contract between the platform and its consumers.

## Principles

1. **SLOs are user-facing.** They measure what a customer experiences (request succeeded, query was fresh enough), not what the system was doing internally.
2. **Burn-rate alerts page, not threshold alerts.** Pages fire on multi-window burn (1h fast / 6h slow). Single-percentile threshold alarms generate tickets, not pages.
3. **Error-budget gates releases.** When the trailing 30-day error budget is exhausted, only changes that demonstrably improve reliability ship until the budget recovers.
4. **One owner per SLO.** Every SLO has a named team and a Grafana dashboard.

## Active SLOs

| Service | SLO | Objective | Window | Owner |
| --- | --- | --- | --- | --- |
| rag-api | `/v1/query` availability (non-5xx) | 99.9% | 30 days | platform |
| rag-api | `/v1/query` p99 latency ≤ 2s | 99.0% | 30 days | platform |
| ingest-worker | Job success rate | 99.5% | 30 days | platform |
| ingest-worker | Freshness: indexed within 15m | 99.0% | 30 days | platform |
| vector-db (qdrant) | Read availability | 99.95% | 30 days | platform |

Definitions live in [observability/slo/](../observability/slo/) as Sloth files; PrometheusRules are generated in CI.

## Error budget policy

| Budget consumed (30d) | Engineering response |
| --- | --- |
| < 50% | Ship freely. |
| 50-90% | Ship freely; review postmortems weekly. |
| 90-100% | Freeze non-reliability changes for the affected service. Daily SLO review. |
| 100% (exhausted) | All non-reliability changes blocked. Reliability-only PRs ship. Incident review with leadership. |

## Severity matrix

| Severity | Trigger |
| --- | --- |
| **SEV-1** | Customer-visible outage; primary SLO actively burning at >14.4× rate (burn-rate page). |
| **SEV-2** | Partial outage; secondary SLO breached or single primary SLO burning at 6× rate. |
| **SEV-3** | Single replica unhealthy; ticket alert with no immediate user impact. |

## Out of scope

- The SLO does **not** cover the model server's *quality* (relevance / hallucination rate). That is the ML team's evaluation framework and lives outside this platform repo.
- The SLO **does** cover availability and latency of the embedder and re-ranker as observed by `rag-api`, since those affect end-user experience.
