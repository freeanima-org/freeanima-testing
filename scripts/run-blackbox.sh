#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

cleanup() {
  if [[ "${KEEP_STACK:-0}" != "1" ]]; then
    bash "$ROOT/scripts/stack-down.sh" || true
  fi
}
trap cleanup EXIT

bash "$ROOT/scripts/stack-up.sh"

if [[ -n "${TESTER_IMAGE:-}" ]]; then
  echo "[run-blackbox] 拉取 tester 镜像: ${TESTER_IMAGE}"
  docker pull "${TESTER_IMAGE}"
else
  echo "[run-blackbox] 构建 tester 镜像 …"
  compose build tester
fi

echo "[run-blackbox] API …"
compose run --rm tester bun test blackbox/api

echo "[run-blackbox] Playwright UI …"
compose run --rm tester node node_modules/@playwright/test/cli.js test

echo "[run-blackbox] 全部通过"
