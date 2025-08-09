#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ -f ".venv/bin/activate" ]]; then
  source .venv/bin/activate
fi

# Prefer installed console script if present, else uvicorn
if command -v kydras-echo >/dev/null 2>&1; then
  exec kydras-echo --host 0.0.0.0 --port 8000 --reload
else
  exec uvicorn gui.app:app --host 0.0.0.0 --port 8000 --reload
fi
