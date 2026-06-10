#!/usr/bin/env bash
# 将 config 模板写入 FREEANIMA_HOME（展开 env 在 anima 读盘时进行）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export FREEANIMA_HOME="${FREEANIMA_HOME:-$ROOT/.anima-runtime}"
export PG_PASSWORD="${PG_PASSWORD:-testing-blackbox}"
export PG_HOST_PORT="${PG_HOST_PORT:-15432}"
export REDIS_HOST_PORT="${REDIS_HOST_PORT:-16379}"

mkdir -p "$FREEANIMA_HOME"
cp "$ROOT/config/blackbox.config.yaml" "$FREEANIMA_HOME/config.yaml"
chmod 700 "$FREEANIMA_HOME"
