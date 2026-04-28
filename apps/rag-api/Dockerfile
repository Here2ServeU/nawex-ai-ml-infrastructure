# syntax=docker/dockerfile:1.7

FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src

# Cache modules.
COPY go.mod go.sum* ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/rag-api ./cmd/server

# Distroless static — no shell, no libc, no package manager.
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /
COPY --from=build /out/rag-api /rag-api
USER 65532:65532
EXPOSE 8080 9090
ENTRYPOINT ["/rag-api"]
