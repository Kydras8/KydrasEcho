#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
if [[ ! -d ".venv" ]]; then python3 -m venv .venv; fi
source .venv/bin/activate
pip install -U pip wheel
[[ -f requirements.txt ]] && pip install -r requirements.txt
echo; echo "[✓] Installed. Run with: ./run.sh"
