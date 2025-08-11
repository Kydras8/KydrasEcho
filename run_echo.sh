#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$ROOT/.logs"; PIDFILE="$LOGDIR/echo.pid"
mkdir -p "$LOGDIR"
. "$ROOT/.venv/bin/activate" 2>/dev/null || { echo "[!] venv missing"; exit 1; }

TARGETS=("gui.app:app" "app:app" "main:app")
APP_TARGET=""
for t in "${TARGETS[@]}"; do
  python - <<PY 2>/dev/null && APP_TARGET="$t" && break || true
import importlib
mod, var = "$t".split(":")
m = importlib.import_module(mod)
getattr(m, var)
print("ok")
PY
done
[[ -n "$APP_TARGET" ]] || { echo "[!] Could not locate FastAPI app object (tried: ${TARGETS[*]})"; exit 1; }

start() {
  if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "[ok] already running (pid $(cat "$PIDFILE"))"; exit 0
  fi
  nohup "$ROOT/.venv/bin/uvicorn" "$APP_TARGET" --host 0.0.0.0 --port 8000 --reload \
    > "$LOGDIR/echo.log" 2>&1 &
  echo $! > "$PIDFILE"
  echo "[ok] started (pid $(cat "$PIDFILE")), logs: $LOGDIR/echo.log"
}

stop() {
  if [[ -f "$PIDFILE" ]]; then
    PID="$(cat "$PIDFILE")"
    kill "$PID" 2>/dev/null || true
    sleep 1
    kill -9 "$PID" 2>/dev/null || true
    rm -f "$PIDFILE"
    echo "[ok] stopped"
  else
    pkill -f "uvicorn.*(gui\.app:app|app:app|main:app)" 2>/dev/null || true
    echo "[ok] nothing to stop"
  fi
}

status() {
  if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "[ok] running (pid $(cat "$PIDFILE"))"
  else
    echo "[..] not running"
  fi
}

logs() { tail -n 200 -f "$LOGDIR/echo.log"; }

case "${1:-status}" in
  start) start ;;
  stop) stop ;;
  restart) stop; start ;;
  status) status ;;
  logs) logs ;;
  *) echo "Usage: $0 {start|stop|restart|status|logs}"; exit 1 ;;
esac
