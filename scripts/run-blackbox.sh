#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ANIMA_BASE_URL="${ANIMA_BASE_URL:-http://127.0.0.1:${ANIMA_PORT:-2658}}"

cleanup() {
  bash "$ROOT/scripts/stack-down.sh" || true
}
trap cleanup EXIT

bash "$ROOT/scripts/stack-up.sh"

cd "$ROOT"
echo "[run-blackbox] API …"
bun test blackbox/api

echo "[run-blackbox] Playwright UI …"
bunx playwright test

echo "[run-blackbox] 全部通过"
