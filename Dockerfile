# syntax=docker/dockerfile:1.7-labs

# ---- builder ----
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0
WORKDIR /app

RUN apt-get update \
  && apt-get install -y libpq-dev gcc \
  && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project --no-dev

ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev

# ---- final ----
FROM python:3.12-slim-bookworm

# Create the app user/group BEFORE chowning
RUN groupadd -g 10001 app && useradd -m -u 10001 -g app app

# Copy the venv + app files and assign ownership to app:app
COPY --from=builder --chown=app:app /app /app

ENV PATH="/app/.venv/bin:$PATH"

# Runtime deps
RUN apt-get update && apt-get install -y \
  libpq-dev iputils-ping dnsutils net-tools \
  && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 8000
USER app

# Railway will append your Start Command after this ENTRYPOINT
ENTRYPOINT ["/app/docker-entrypoint.sh", "postgres-mcp"]
CMD []
