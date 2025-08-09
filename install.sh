#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Create venv if missing
if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi
source .venv/bin/activate

# Upgrade pip & install deps
pip install -U pip wheel
if [[ -f requirements.txt ]]; then
  pip install -r requirements.txt
fi

echo
echo "[✓] Installed. To run:"
echo "    ./run.sh"
