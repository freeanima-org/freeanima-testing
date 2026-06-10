#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FREEANIMA_DIR="${FREEANIMA_DIR:-$ROOT/freeanima}"
export PG_PASSWORD="${PG_PASSWORD:-testing-blackbox}"
export PG_HOST_PORT="${PG_HOST_PORT:-15432}"
export REDIS_HOST_PORT="${REDIS_HOST_PORT:-16379}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-sk-blackbox-unused}"
export ANIMA_PORT="${ANIMA_PORT:-2658}"
export ANIMA_WEBUI_DEV="${ANIMA_WEBUI_DEV:-0}"
export FREEANIMA_HOME="${FREEANIMA_HOME:-$ROOT/.anima-runtime}"

if [[ ! -d "$FREEANIMA_DIR" ]]; then
  echo "[stack-up] 未找到 freeanima 源码: $FREEANIMA_DIR" >&2
  echo "  git submodule update --init 或设置 FREEANIMA_DIR" >&2
  exit 1
fi

echo "[stack-up] 启动 PG + Redis …"
docker compose -f "$ROOT/docker/docker-compose.infra.yml" up -d --wait

bash "$ROOT/scripts/write-test-config.sh"

echo "[stack-up] bun install @ freeanima …"
(cd "$FREEANIMA_DIR" && bun install)

LOG="$ROOT/.anima-service.log"
PID_FILE="$ROOT/.anima.pid"
rm -f "$LOG"

echo "[stack-up] 启动 anima service (port ${ANIMA_PORT}) …"
(
  cd "$FREEANIMA_DIR"
  exec bun cli/src/cli.ts service start --foreground --host 127.0.0.1 --port "$ANIMA_PORT"
) >"$LOG" 2>&1 &
echo $! >"$PID_FILE"

bash "$ROOT/scripts/wait-for-health.sh"
echo "[stack-up] 完成"
