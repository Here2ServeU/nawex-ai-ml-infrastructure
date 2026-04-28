// Command rag-api serves the RAG retrieval HTTP API.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/your-org/devops-ai-ml-infrastructure/apps/rag-api/internal/config"
	"github.com/your-org/devops-ai-ml-infrastructure/apps/rag-api/internal/handler"
	"github.com/your-org/devops-ai-ml-infrastructure/apps/rag-api/internal/observability"
	"github.com/your-org/devops-ai-ml-infrastructure/apps/rag-api/internal/retrieval"
)

func main() {
	cfg := config.FromEnv()

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: cfg.LogLevel.SlogLevel(),
	}))
	slog.SetDefault(logger)

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	shutdownTracer, err := observability.InitTracer(ctx, cfg.OTLPEndpoint, "rag-api")
	if err != nil {
		logger.Warn("tracer init failed; continuing without tracing", "err", err)
	} else {
		defer func() {
			shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			_ = shutdownTracer(shutdownCtx)
		}()
	}

	retriever, err := retrieval.New(retrieval.Config{
		VectorDBAddress:    cfg.VectorDBAddress,
		Collection:         cfg.VectorDBCollection,
		EmbedderEndpoint:   cfg.EmbedderEndpoint,
		EmbedderTimeout:    cfg.EmbedderTimeout,
		TopK:               cfg.RetrievalTopK,
		MaxContextTokens:   cfg.RetrievalContextTokens,
	})
	if err != nil {
		logger.Error("retrieval init failed", "err", err)
		os.Exit(1)
	}

	apiSrv := &http.Server{
		Addr:              ":8080",
		Handler:           handler.NewAPI(retriever, logger),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	metricsSrv := &http.Server{
		Addr:              ":9090",
		Handler:           handler.NewMetrics(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	go runServer(ctx, apiSrv, "api", logger)
	go runServer(ctx, metricsSrv, "metrics", logger)

	<-ctx.Done()
	logger.Info("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()
	_ = apiSrv.Shutdown(shutdownCtx)
	_ = metricsSrv.Shutdown(shutdownCtx)
	logger.Info("shutdown complete")
}

func runServer(ctx context.Context, srv *http.Server, name string, logger *slog.Logger) {
	logger.Info("server starting", "name", name, "addr", srv.Addr)
	err := srv.ListenAndServe()
	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		logger.Error("server failed", "name", name, "err", err)
	}
}
