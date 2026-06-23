#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

on_fail() {
  local stage=$1
  echo "::error title=Blackbox 失败::阶段=${stage}（详见下方调试上下文与 artifacts）" >&2
  bash "$ROOT/scripts/debug-context.sh" "$stage" || true
  exit 1
}

cleanup() {
  if [[ "${KEEP_STACK:-0}" != "1" ]]; then
    bash "$ROOT/scripts/stack-down.sh" || true
  fi
}
trap cleanup EXIT

wait_bg() {
  local pid=$1
  local label=$2
  if ! wait "$pid"; then
    on_fail "$label"
  fi
}

ensure_image() {
  local image=$1
  if docker image inspect "$image" >/dev/null 2>&1; then
    echo "[run-blackbox] 镜像已存在，跳过拉取: $image"
    return 0
  fi
  docker pull "$image"
}

pids=()
labels=()

start_bg() {
  local label=$1
  shift
  echo "[run-blackbox] 并行: $label …"
  "$@" &
  pids+=($!)
  labels+=("$label")
}

if [[ -n "${TESTER_IMAGE:-}" ]]; then
  start_bg "拉取 tester 镜像" ensure_image "${TESTER_IMAGE}"
else
  start_bg "构建 tester 镜像" compose build tester
fi

start_bg "拉取 stack 镜像" compose pull -q postgres redis anima
start_bg "启动 stack" bash "$ROOT/scripts/stack-up.sh"

for i in "${!pids[@]}"; do
  wait_bg "${pids[$i]}" "${labels[$i]}"
done

echo "[run-blackbox] API 测试 …"
if ! compose run --rm --no-deps tester bun test blackbox/api; then
  on_fail "api-tests"
fi

echo "[run-blackbox] Playwright UI …"
if ! compose run --rm --no-deps tester node node_modules/@playwright/test/cli.js test; then
  on_fail "ui-tests"
fi

echo "[run-blackbox] 全部通过"
