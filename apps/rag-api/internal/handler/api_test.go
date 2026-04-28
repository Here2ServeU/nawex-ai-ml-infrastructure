package handler

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/nawex/devops-ai-ml-infrastructure/apps/rag-api/internal/retrieval"
)

type stubEmbedder struct{}

func (stubEmbedder) Embed(ctx context.Context, text string) ([]float32, error) {
	return []float32{0.1, 0.2, 0.3}, nil
}

type stubStore struct{}

func (stubStore) Search(ctx context.Context, vec []float32, topK int) ([]retrieval.Document, error) {
	return []retrieval.Document{{ID: "1", Score: 0.9, Text: "doc"}}, nil
}

func newTestHandler() http.Handler {
	r := retrieval.NewWithDeps(retrieval.Config{TopK: 5}, stubEmbedder{}, stubStore{})
	return NewAPI(r, slog.New(slog.NewTextHandler(io.Discard, nil)))
}

func TestHealthz(t *testing.T) {
	h := newTestHandler()
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	w := httptest.NewRecorder()
	h.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}

func TestQuery_RejectsEmpty(t *testing.T) {
	h := newTestHandler()
	req := httptest.NewRequest(http.MethodPost, "/v1/query", strings.NewReader(`{"query":""}`))
	w := httptest.NewRecorder()
	h.ServeHTTP(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("want 400, got %d", w.Code)
	}
}

func TestQuery_HappyPath(t *testing.T) {
	h := newTestHandler()
	req := httptest.NewRequest(http.MethodPost, "/v1/query", strings.NewReader(`{"query":"hello"}`))
	w := httptest.NewRecorder()
	h.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}
