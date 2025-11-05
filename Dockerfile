# syntax=docker/dockerfile:1.7-labs

# ---- builder ----
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0
WORKDIR /app

RUN apt-get update \
  && apt-get install -y libpq-dev gcc \
  && rm -rf /var/lib/apt/lists/*

# Install dependencies (no cache mounts)
COPY uv.lock pyproject.toml ./
RUN uv sync --frozen --no-install-project --no-dev

# Copy the rest of your app
COPY . .
RUN uv sync --frozen --no-dev

# ---- final ----
FROM python:3.12-slim-bookworm

# Create the app user/group BEFORE chowning
RUN groupadd -g 10001 app && useradd -m -u 10001 -g app app

# Copy the built app
COPY --from=builder --chown=app:app /app /app

ENV PATH="/app/.venv/bin:$PATH"

# Runtime deps - install before switching to app user
RUN apt-get update && apt-get install -y \
  ca-certificates \
  libpq-dev \
  iputils-ping \
  dnsutils \
  net-tools \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 8000
USER app

ENTRYPOINT ["/app/docker-entrypoint.sh", "postgres-mcp"]
CMD []
