#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd "$ROOT"
[[ -f ".venv/bin/activate" ]] && source .venv/bin/activate
command -v ffmpeg >/dev/null || { echo "[!] ffmpeg not found"; exit 1; }
exec uvicorn gui.app:app --host 0.0.0.0 --port 8000 --reload
