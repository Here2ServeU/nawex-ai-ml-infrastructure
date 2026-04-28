# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS build
WORKDIR /app

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip build && \
    pip install .

FROM python:3.12-slim AS runtime
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Run as non-root.
RUN groupadd -g 65532 nonroot && useradd -u 65532 -g 65532 -s /usr/sbin/nologin nonroot

COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /usr/local/bin/ingest-worker /usr/local/bin/ingest-worker

USER 65532:65532
EXPOSE 9090
ENTRYPOINT ["ingest-worker"]
