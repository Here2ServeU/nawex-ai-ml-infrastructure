package observability

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	RequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "rag_api_requests_total",
			Help: "Total HTTP requests handled by the RAG API.",
		},
		[]string{"route", "method", "status"},
	)

	RequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "rag_api_request_duration_seconds",
			Help:    "End-to-end request latency.",
			Buckets: []float64{0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10},
		},
		[]string{"route", "method"},
	)

	InFlight = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "rag_api_in_flight_requests",
			Help: "In-flight HTTP requests (saturation signal).",
		},
	)

	VectorDBDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "rag_api_vector_db_duration_seconds",
			Help:    "Latency of vector DB calls.",
			Buckets: []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2},
		},
		[]string{"operation"},
	)

	EmbedderDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "rag_api_embedder_duration_seconds",
			Help:    "Latency of embedder calls.",
			Buckets: []float64{0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5},
		},
		[]string{"outcome"},
	)
)
