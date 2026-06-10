#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${ANIMA_BASE_URL:-http://127.0.0.1:${ANIMA_PORT:-2658}}"
DEADLINE=$((SECONDS + ${ANIMA_HEALTH_TIMEOUT_SEC:-120}))

echo "[wait-for-health] 探测 ${BASE}/api/health …"

while (( SECONDS < DEADLINE )); do
  if curl -sf "${BASE}/api/health" >/dev/null; then
    echo "[wait-for-health] 就绪"
    exit 0
  fi
  sleep 2
done

LOG="${ANIMA_SERVICE_LOG:-$ROOT/.anima-service.log}"
echo "[wait-for-health] 超时 (${ANIMA_HEALTH_TIMEOUT_SEC:-120}s)" >&2
if [[ -f "$LOG" ]]; then
  echo "[wait-for-health] --- anima service log (last 40 lines) ---" >&2
  tail -n 40 "$LOG" >&2
  echo "[wait-for-health] --- end ---" >&2
fi
exit 1
