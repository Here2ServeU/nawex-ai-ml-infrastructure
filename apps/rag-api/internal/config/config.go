package config

import (
	"log/slog"
	"os"
	"strconv"
	"strings"
	"time"
)

type LogLevel string

func (l LogLevel) SlogLevel() slog.Level {
	switch strings.ToLower(string(l)) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

type Config struct {
	LogLevel               LogLevel
	OTLPEndpoint           string
	VectorDBAddress        string
	VectorDBCollection     string
	EmbedderEndpoint       string
	EmbedderTimeout        time.Duration
	RetrievalTopK          int
	RetrievalContextTokens int
}

func FromEnv() Config {
	return Config{
		LogLevel:               LogLevel(getenv("LOG_LEVEL", "info")),
		OTLPEndpoint:           os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT"),
		VectorDBAddress:        getenv("VECTOR_DB_ADDRESS", "qdrant.qdrant.svc.cluster.local:6334"),
		VectorDBCollection:     getenv("VECTOR_DB_COLLECTION", "documents"),
		EmbedderEndpoint:       getenv("EMBEDDER_ENDPOINT", "http://embedder.ml.svc.cluster.local/embed"),
		EmbedderTimeout:        time.Duration(getenvInt("EMBEDDER_TIMEOUT_MS", 1500)) * time.Millisecond,
		RetrievalTopK:          getenvInt("RETRIEVAL_TOP_K", 8),
		RetrievalContextTokens: getenvInt("RETRIEVAL_CONTEXT_TOKENS", 4096),
	}
}

func getenv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func getenvInt(key string, fallback int) int {
	v, ok := os.LookupEnv(key)
	if !ok {
		return fallback
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return fallback
	}
	return n
}
