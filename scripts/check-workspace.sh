#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

missing=0
for dir in mails-backend mails-frontend; do
  if [[ ! -d "$root/$dir" ]]; then
    echo "error: $dir/ not found — clone child repos first (see README)"
    missing=1
  fi
done

if [[ "$missing" -eq 1 ]]; then
  exit 1
fi

if [[ ! -f "$root/mails-backend/.env" ]]; then
  echo "warn: mails-backend/.env missing — copy from .env.example"
fi

if [[ ! -f "$root/mails-frontend/.env.local" ]]; then
  echo "warn: mails-frontend/.env.local missing — copy from .env.example"
fi
