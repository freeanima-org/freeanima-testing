#!/usr/bin/env bash
# 供 stack 脚本 source：统一 COMPOSE 路径与 env
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FREEANIMA_DIR="${FREEANIMA_DIR:-$ROOT/freeanima}"
if [[ -d "$FREEANIMA_DIR" ]]; then
  export FREEANIMA_DIR="$(cd "$FREEANIMA_DIR" && pwd)"
else
  export FREEANIMA_DIR
fi
export PG_PASSWORD="${PG_PASSWORD:-testing-blackbox}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-sk-blackbox-unused}"
export COMPOSE_FILE="${COMPOSE_FILE:-$ROOT/docker/docker-compose.yml}"

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}
