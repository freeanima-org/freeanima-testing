#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

if [[ ! -d "$FREEANIMA_DIR" ]]; then
  echo "[stack-up] 未找到 freeanima 源码: $FREEANIMA_DIR" >&2
  echo "  git submodule update --init 或设置 FREEANIMA_DIR" >&2
  exit 1
fi

echo "[stack-up] 启动 postgres + redis + anima …"
compose up -d postgres redis anima --wait
echo "[stack-up] 完成"
