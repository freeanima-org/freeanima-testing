#!/usr/bin/env bash
# CI 专用：配合 actions/cache 保存/恢复 blackbox 用到的 Docker 镜像
set -euo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

CACHE_DIR="${DOCKER_CACHE_DIR:-/tmp/docker-blackbox-cache}"
CACHE_FILE="$CACHE_DIR/images.tar"

stack_images() {
  printf '%s\n' \
    "pgvector/pgvector:pg17" \
    "redis:7-alpine" \
    "oven/bun:1.3.14"
}

tester_image() {
  if [[ -n "${TESTER_IMAGE:-}" ]]; then
    printf '%s\n' "$TESTER_IMAGE"
  fi
}

collect_images() {
  stack_images
  tester_image
}

cmd="${1:-}"
case "$cmd" in
  load)
    if [[ ! -f "$CACHE_FILE" ]]; then
      echo "[docker-cache] 无缓存文件，跳过加载"
      exit 0
    fi
    echo "[docker-cache] 从缓存加载镜像 …"
    docker load -i "$CACHE_FILE"
    ;;
  save)
    mkdir -p "$CACHE_DIR"
    mapfile -t existing < <(
      while IFS= read -r img; do
        [[ -z "$img" ]] && continue
        if docker image inspect "$img" >/dev/null 2>&1; then
          printf '%s\n' "$img"
        fi
      done < <(collect_images)
    )
    if ((${#existing[@]} == 0)); then
      echo "[docker-cache] 无本地镜像可保存"
      exit 0
    fi
    echo "[docker-cache] 保存 ${#existing[@]} 个镜像到缓存 …"
    docker save -o "$CACHE_FILE" "${existing[@]}"
    ;;
  *)
    echo "用法: $0 load|save" >&2
    exit 1
    ;;
esac
