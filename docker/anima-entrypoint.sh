#!/usr/bin/env sh
set -e

mkdir -p "${FREEANIMA_HOME}"
cd /app/freeanima
bun install --frozen-lockfile
if [ "${ANIMA_PREBUILD_WEB:-0}" = "1" ]; then
  echo "[anima-entrypoint] 预构建 Web UI dist …"
  # 与 blackbox.config remote_auth.token 一致，避免浏览器壳层落到 /setup 引导页
  export FREEANIMA_REMOTE_AUTH_TOKEN="${FREEANIMA_REMOTE_AUTH_TOKEN:-${REMOTE_AUTH_TOKEN:-}}"
  export FREEANIMA_URL="${FREEANIMA_URL:-http://127.0.0.1:2658}"
  bun run --filter @freeanima/app-web build
fi
exec bun cli/src/cli.ts service start --foreground --host 0.0.0.0 --port 2658
