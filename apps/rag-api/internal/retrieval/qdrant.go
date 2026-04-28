package retrieval

import (
	"context"
	"fmt"
)

// qdrantStore is a placeholder implementation. In production this connects to
// Qdrant via gRPC (github.com/qdrant/go-client), but the dependency is omitted
// here to keep the module easy to vendor offline. See README for the wiring.
type qdrantStore struct {
	address    string
	collection string
}

func newQdrantStore(address, collection string) *qdrantStore {
	return &qdrantStore{address: address, collection: collection}
}

func (q *qdrantStore) Search(ctx context.Context, vec []float32, topK int) ([]Document, error) {
	if len(vec) == 0 {
		return nil, fmt.Errorf("empty embedding vector")
	}
	// Production code path:
	//   client, err := qdrantgo.NewClient(q.address, qdrantgo.WithTLS(...))
	//   resp, err := client.Search(ctx, &pb.SearchPoints{
	//       CollectionName: q.collection,
	//       Vector:         vec,
	//       Limit:          uint64(topK),
	//       WithPayload:    &pb.WithPayloadSelector{...},
	//   })
	//   ...
	// For local dev / unit tests, use NewWithDeps to inject a fake.
	return nil, fmt.Errorf("qdrant client not wired in this build; inject a VectorStore via retrieval.NewWithDeps")
}
