#!/usr/bin/env sh
set -e

mkdir -p "${FREEANIMA_HOME}"
cd /app/freeanima
bun install --frozen-lockfile
exec bun cli/src/cli.ts service start --foreground --host 0.0.0.0 --port 2658
