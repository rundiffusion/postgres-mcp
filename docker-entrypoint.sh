#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-postgres-mcp}"
shift || true

DB_URI="${DATABASE_URL:-${DATABASE_URI:-}}"

need_transport=true
need_sse_host=true
need_sse_port=true

# Optional: test the DB connection on boot for clearer errors
if command -v psql >/dev/null 2>&1 && [[ -n "$DB_URI" ]]; then
  echo "Health: testing DB connection..."
  PGPASSWORD="" psql "$DB_URI" -c "SELECT 1;" >/dev/null && \
    echo "Health: DB OK" || echo "Health: DB FAILED"
fi

for a in "$@"; do
  [[ "$a" == "--transport" ]] && need_transport=false
  [[ "$a" == "--sse-host"  ]] && need_sse_host=false
  [[ "$a" == "--sse-port"  ]] && need_sse_port=false
done

$need_transport && set -- "$@" --transport sse
$need_sse_host  && set -- "$@" --sse-host 0.0.0.0
if [[ -n "${PORT:-}" && "$need_sse_port" == true ]]; then
  set -- "$@" --sse-port "$PORT"
fi

# Append DB URL as positional if not already provided
if [[ -n "$DB_URI" ]]; then
  has_db=false
  for a in "$@"; do
    if [[ "$a" =~ ^postgres(ql)?:// ]]; then has_db=true; break; fi
  done
  [[ "$has_db" == false ]] && set -- "$@" "$DB_URI"
fi

exec "$cmd" "$@"
