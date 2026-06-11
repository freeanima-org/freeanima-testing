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

wait_bg() {
  local pid=$1
  local label=$2
  if ! wait "$pid"; then
    echo "[run-blackbox] 失败: $label" >&2
    exit 1
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

echo "[run-blackbox] API + Playwright UI …"
compose run --rm --no-deps tester sh -c \
  'bun test blackbox/api && node node_modules/@playwright/test/cli.js test'

echo "[run-blackbox] 全部通过"
