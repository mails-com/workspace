#!/usr/bin/env bash
# Tear down any previous Overmind session and free dev ports before make dev / after make stop.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

backend_port=3000
frontend_port=3001

if [[ -f "$root/mails-backend/.env" ]]; then
  port_line=$(grep -E '^PORT=' "$root/mails-backend/.env" 2>/dev/null | tail -1 || true)
  if [[ -n "$port_line" ]]; then
    backend_port="${port_line#PORT=}"
  fi
fi

if [[ -e "$root/.overmind.sock" ]] && overmind status >/dev/null 2>&1; then
  echo "Stopping Overmind session..."
  overmind quit 2>/dev/null || true
  for _ in $(seq 1 24); do
    if ! overmind status >/dev/null 2>&1; then
      break
    fi
    sleep 0.25
  done
fi

"$root/scripts/clean-overmind-socket.sh"
"$root/scripts/free-dev-ports.sh" "$backend_port" "$frontend_port"
