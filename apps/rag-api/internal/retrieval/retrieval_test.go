package retrieval

import (
	"context"
	"errors"
	"testing"
	"time"
)

type fakeEmbedder struct {
	vec []float32
	err error
}

func (f *fakeEmbedder) Embed(ctx context.Context, text string) ([]float32, error) {
	return f.vec, f.err
}

type fakeStore struct {
	docs []Document
	err  error
}

func (f *fakeStore) Search(ctx context.Context, vec []float32, topK int) ([]Document, error) {
	if f.err != nil {
		return nil, f.err
	}
	if topK > len(f.docs) {
		topK = len(f.docs)
	}
	return f.docs[:topK], nil
}

func TestRetriever_Query_HappyPath(t *testing.T) {
	r := NewWithDeps(
		Config{TopK: 3, EmbedderTimeout: time.Second},
		&fakeEmbedder{vec: []float32{0.1, 0.2}},
		&fakeStore{docs: []Document{{ID: "a"}, {ID: "b"}, {ID: "c"}, {ID: "d"}}},
	)

	docs, err := r.Query(context.Background(), "hello", 0)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(docs) != 3 {
		t.Fatalf("want 3 docs (TopK fallback), got %d", len(docs))
	}
}

func TestRetriever_Query_EmbedderFailure(t *testing.T) {
	r := NewWithDeps(
		Config{TopK: 3},
		&fakeEmbedder{err: errors.New("boom")},
		&fakeStore{},
	)
	if _, err := r.Query(context.Background(), "hello", 5); err == nil {
		t.Fatal("expected error")
	}
}

func TestNew_RejectsZeroTopK(t *testing.T) {
	if _, err := New(Config{TopK: 0}); err == nil {
		t.Fatal("expected error for TopK=0")
	}
}
