#!/usr/bin/env sh
set -e

cd /workspace
stamp=node_modules/.deps-stamp
if [ ! -f "$stamp" ] || [ package.json -nt "$stamp" ] || [ bun.lock -nt "$stamp" ]; then
  bun install --frozen-lockfile
  touch "$stamp"
fi
exec "$@"
