#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$ROOT/.anima.pid"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE")"
  if kill -0 "$PID" 2>/dev/null; then
    echo "[stack-down] 停止 anima pid=$PID"
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
fi

echo "[stack-down] 停止 docker infra …"
docker compose -f "$ROOT/docker/docker-compose.infra.yml" down -v --remove-orphans 2>/dev/null || true
