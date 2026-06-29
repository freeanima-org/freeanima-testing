#!/usr/bin/env sh
set -e

mkdir -p "${FREEANIMA_HOME}"
cd /app/freeanima
bun install --frozen-lockfile
if [ "${ANIMA_PREBUILD_WEB:-0}" = "1" ]; then
  echo "[anima-entrypoint] 预构建 Web UI dist …"
  bun run --filter @freeanima/app-web build
fi
exec bun cli/src/cli.ts service start --foreground --host 0.0.0.0 --port 2658
