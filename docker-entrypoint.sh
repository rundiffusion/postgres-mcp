#!/usr/bin/env bash
set -euo pipefail

# Command is first arg (default provided by ENTRYPOINT)
cmd="${1:-postgres-mcp}"
shift || true

# Prefer DATABASE_URL if present; otherwise DATABASE_URI; otherwise nothing.
DB_URI="${DATABASE_URL:-${DATABASE_URI:-}}"

# If Railway provided $PORT but caller didn't pass --port, append it.
append_port=true
for a in "$@"; do
  if [[ "$a" == "--port" || "$a" == "-p" ]]; then
    append_port=false
    break
  fi
done
if [[ "${PORT:-}" != "" && "$append_port" == true ]]; then
  set -- "$@" --port "$PORT"
fi

# If we have a DB URI and user didn't pass one positionally, append it.
if [[ -n "$DB_URI" ]]; then
  has_db=false
  for a in "$@"; do
    if [[ "$a" =~ ^postgres(ql)?:// ]]; then
      has_db=true
      break
    fi
  done
  if [[ "$has_db" == false ]]; then
    set -- "$@" "$DB_URI"
  fi
fi

exec "$cmd" "$@"
