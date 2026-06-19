#!/usr/bin/env bash
# Free local dev ports if orphaned processes are still listening.
# Used after Overmind quit or a crashed backend/frontend.
set -euo pipefail

free_port() {
  local port="$1"
  local pids

  pids=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -z "$pids" ]]; then
    return 0
  fi

  echo "warn: freeing port $port (PIDs: $(echo "$pids" | tr '\n' ' ' | sed 's/ $//'))"
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true
  sleep 0.3

  pids=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
  fi
}

for port in "$@"; do
  free_port "$port"
done
