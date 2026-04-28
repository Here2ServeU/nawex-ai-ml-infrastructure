// Package handler provides the HTTP handlers for the RAG API.
package handler

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/nawex/devops-ai-ml-infrastructure/apps/rag-api/internal/observability"
	"github.com/nawex/devops-ai-ml-infrastructure/apps/rag-api/internal/retrieval"
)

type API struct {
	mux       *http.ServeMux
	retriever *retrieval.Retriever
	logger    *slog.Logger
}

func NewAPI(r *retrieval.Retriever, logger *slog.Logger) http.Handler {
	api := &API{
		mux:       http.NewServeMux(),
		retriever: r,
		logger:    logger,
	}
	api.mux.HandleFunc("GET /healthz", api.healthz)
	api.mux.HandleFunc("GET /readyz", api.readyz)
	api.mux.HandleFunc("POST /v1/query", api.query)
	return instrument(api.mux)
}

type queryRequest struct {
	Query string `json:"query"`
	TopK  int    `json:"top_k,omitempty"`
}

type queryResponse struct {
	Documents []retrieval.Document `json:"documents"`
}

func (a *API) query(w http.ResponseWriter, r *http.Request) {
	var req queryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid JSON body"})
		return
	}
	if req.Query == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "query is required"})
		return
	}

	docs, err := a.retriever.Query(r.Context(), req.Query, req.TopK)
	if err != nil {
		a.logger.Error("query failed", "err", err)
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "retrieval failed"})
		return
	}
	writeJSON(w, http.StatusOK, queryResponse{Documents: docs})
}

func (a *API) healthz(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

func (a *API) readyz(w http.ResponseWriter, _ *http.Request) {
	// Readiness checks downstream dependencies. For now, the retriever
	// constructor enforces config validity, so we report ready.
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ready"))
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// instrument wraps the mux with a metrics + status-capture middleware.
func instrument(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		observability.InFlight.Inc()
		defer observability.InFlight.Dec()

		start := time.Now()
		sw := &statusWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(sw, r)

		route := routeOf(r)
		dur := time.Since(start).Seconds()
		observability.RequestDuration.WithLabelValues(route, r.Method).Observe(dur)
		observability.RequestsTotal.WithLabelValues(route, r.Method, strconv.Itoa(sw.status)).Inc()
	})
}

// routeOf returns a low-cardinality label for the route.
func routeOf(r *http.Request) string {
	switch r.URL.Path {
	case "/healthz", "/readyz", "/v1/query":
		return r.URL.Path
	default:
		return "other"
	}
}

type statusWriter struct {
	http.ResponseWriter
	status int
}

func (s *statusWriter) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}
