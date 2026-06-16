#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
sock="$root/.overmind.sock"

if [[ ! -e "$sock" ]]; then
  exit 0
fi

cd "$root"

if overmind status >/dev/null 2>&1; then
  exit 0
fi

echo "warn: removing stale Overmind socket (no running instance)"
rm -f "$sock"
