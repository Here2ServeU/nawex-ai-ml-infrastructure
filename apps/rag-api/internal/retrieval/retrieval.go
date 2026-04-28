// Package retrieval performs query embedding and vector lookup for the RAG API.
//
// The implementation is structured around two seams: an Embedder and a
// VectorStore. The default wiring uses HTTP and gRPC clients, but tests inject
// in-memory fakes via the same interfaces.
package retrieval

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.opentelemetry.io/otel"

	"github.com/nawex/devops-ai-ml-infrastructure/apps/rag-api/internal/observability"
)

var tracer = otel.Tracer("rag-api/retrieval")

type Document struct {
	ID       string            `json:"id"`
	Score    float32           `json:"score"`
	Text     string            `json:"text"`
	Metadata map[string]string `json:"metadata,omitempty"`
}

type Embedder interface {
	Embed(ctx context.Context, text string) ([]float32, error)
}

type VectorStore interface {
	Search(ctx context.Context, vec []float32, topK int) ([]Document, error)
}

type Config struct {
	VectorDBAddress    string
	Collection         string
	EmbedderEndpoint   string
	EmbedderTimeout    time.Duration
	TopK               int
	MaxContextTokens   int
}

type Retriever struct {
	embedder Embedder
	store    VectorStore
	cfg      Config
}

func New(cfg Config) (*Retriever, error) {
	if cfg.TopK <= 0 {
		return nil, errors.New("retrieval: TopK must be > 0")
	}
	emb := newHTTPEmbedder(cfg.EmbedderEndpoint, cfg.EmbedderTimeout)
	store := newQdrantStore(cfg.VectorDBAddress, cfg.Collection)
	return &Retriever{embedder: emb, store: store, cfg: cfg}, nil
}

// NewWithDeps lets tests inject fakes.
func NewWithDeps(cfg Config, emb Embedder, store VectorStore) *Retriever {
	return &Retriever{embedder: emb, store: store, cfg: cfg}
}

func (r *Retriever) Query(ctx context.Context, query string, topK int) ([]Document, error) {
	ctx, span := tracer.Start(ctx, "retrieval.Query")
	defer span.End()

	if topK <= 0 || topK > r.cfg.TopK {
		topK = r.cfg.TopK
	}

	embStart := time.Now()
	vec, err := r.embedder.Embed(ctx, query)
	if err != nil {
		observability.EmbedderDuration.WithLabelValues("error").Observe(time.Since(embStart).Seconds())
		return nil, fmt.Errorf("embed: %w", err)
	}
	observability.EmbedderDuration.WithLabelValues("ok").Observe(time.Since(embStart).Seconds())

	vdbStart := time.Now()
	docs, err := r.store.Search(ctx, vec, topK)
	observability.VectorDBDuration.WithLabelValues("search").Observe(time.Since(vdbStart).Seconds())
	if err != nil {
		return nil, fmt.Errorf("vector search: %w", err)
	}
	return docs, nil
}
