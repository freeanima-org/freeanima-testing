#!/usr/bin/env bash
# 黑盒失败时收集调试上下文，输出到 stdout 并写入 blackbox-debug/ 供 CI 归档。
set -uo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

STAGE="${1:-unknown}"
DEBUG_DIR="${BLACKBOX_DEBUG_DIR:-$ROOT/blackbox-debug}"
TAIL_LINES="${BLACKBOX_LOG_TAIL:-200}"

mkdir -p "$DEBUG_DIR"

section() {
  echo ""
  echo "========== $1 =========="
}

write_section() {
  section "$1" | tee -a "$DEBUG_DIR/full.log"
}

run_logged() {
  local label=$1
  shift
  section "$label"
  "$@" 2>&1 | tee -a "$DEBUG_DIR/full.log"
}

freeanima_git() {
  local field=$1
  if [[ ! -d "${FREEANIMA_DIR:-}/.git" ]]; then
    echo "（无 git 信息，FREEANIMA_DIR=${FREEANIMA_DIR:-未设置}）"
    return
  fi
  case "$field" in
    sha) git -C "$FREEANIMA_DIR" rev-parse HEAD 2>/dev/null || echo unknown ;;
    short) git -C "$FREEANIMA_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown ;;
    subject) git -C "$FREEANIMA_DIR" log -1 --format=%s 2>/dev/null || echo unknown ;;
    author) git -C "$FREEANIMA_DIR" log -1 --format='%an <%ae>' 2>/dev/null || echo unknown ;;
    date) git -C "$FREEANIMA_DIR" log -1 --format=%ci 2>/dev/null || echo unknown ;;
  esac
}

write_section "Blackbox 失败上下文"
{
  echo "stage: $STAGE"
  echo "time_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "freeanima_dir: ${FREEANIMA_DIR:-}"
  echo "freeanima_sha: $(freeanima_git sha)"
  echo "freeanima_short_sha: $(freeanima_git short)"
  echo "freeanima_subject: $(freeanima_git subject)"
  echo "freeanima_author: $(freeanima_git author)"
  echo "freeanima_commit_date: $(freeanima_git date)"
  echo "tester_image: ${TESTER_IMAGE:-（本地 compose build）}"
  echo "compose_file: $COMPOSE_FILE"
  echo "ci: ${CI:-}"
  echo "github_actions: ${GITHUB_ACTIONS:-}"
  echo "freeanima_pr: ${FREEANIMA_PR:-}"
  echo "freeanima_repo: ${FREEANIMA_REPO:-}"
  echo "dispatch_sha: ${FREEANIMA_SHA:-}"
} | tee -a "$DEBUG_DIR/full.log"

echo "$STAGE" >"$DEBUG_DIR/fail-stage.txt"

write_section "Compose 服务状态"
compose ps -a 2>&1 | tee "$DEBUG_DIR/compose-ps.txt" | tee -a "$DEBUG_DIR/full.log" || true

for svc in anima postgres redis; do
  write_section "服务日志: $svc（最近 ${TAIL_LINES} 行）"
  compose logs --no-color --tail="$TAIL_LINES" "$svc" 2>&1 \
    | tee "$DEBUG_DIR/${svc}.log" \
    | tee -a "$DEBUG_DIR/full.log" || true
done

write_section "Anima 容器内 health 探针"
compose exec -T anima bun -e "
const checks = [
  ['hub', 'http://127.0.0.1:2658/api/health'],
  ['web', 'http://127.0.0.1:2659/health'],
];
for (const [label, url] of checks) {
  try {
    const r = await fetch(url);
    const text = await r.text();
    console.log('---', label, url, '---');
    console.log('status:', r.status, r.statusText);
    console.log('body:', text.slice(0, 2000));
  } catch (e) {
    console.error('---', label, url, '---');
    console.error('probe_error:', e);
  }
}
" 2>&1 | tee "$DEBUG_DIR/anima-health-probe.log" | tee -a "$DEBUG_DIR/full.log" || true

write_section "Tester 网络 API 探针（与测试相同网络）"
compose run --rm --no-deps tester bun -e "
const apiBase = process.env.ANIMA_BASE_URL ?? 'http://anima:2658';
for (const path of ['/api/health']) {
  try {
    const r = await fetch(apiBase + path);
    const text = await r.text();
    console.log('---', path, '---');
    console.log('status:', r.status, r.statusText);
    console.log('body:', text.slice(0, 2000));
  } catch (e) {
    console.error('---', path, '---');
    console.error('error:', e);
  }
}
" 2>&1 | tee "$DEBUG_DIR/api-probe.log" | tee -a "$DEBUG_DIR/full.log" || true

write_section "Tester 网络 Web 探针"
compose run --rm --no-deps tester bun -e "
const webBase = process.env.ANIMA_WEB_BASE_URL ?? 'http://anima:2659';
for (const path of ['/health', '/settings']) {
  try {
    const r = await fetch(webBase + path);
    const text = await r.text();
    console.log('---', path, '---');
    console.log('status:', r.status, r.statusText);
    console.log('body:', text.slice(0, 500));
  } catch (e) {
    console.error('---', path, '---');
    console.error('error:', e);
  }
}
" 2>&1 | tee "$DEBUG_DIR/web-probe.log" | tee -a "$DEBUG_DIR/full.log" || true

# 供 GitHub Step Summary / 主仓快速浏览
{
  echo "# Blackbox 失败摘要"
  echo ""
  echo "| 项 | 值 |"
  echo "|---|---|"
  echo "| 失败阶段 | \`${STAGE}\` |"
  echo "| 时间 (UTC) | $(date -u +%Y-%m-%dT%H:%M:%SZ) |"
  echo "| 被测 SHA | \`$(freeanima_git short)\` (\`$(freeanima_git sha)\`) |"
  echo "| 被测 commit | $(freeanima_git subject) |"
  echo "| 作者 | $(freeanima_git author) |"
  if [[ -n "${FREEANIMA_PR:-}" ]]; then
    echo "| PR | ${FREEANIMA_REPO:-freeanima-org/freeanima}#${FREEANIMA_PR} |"
  fi
  echo ""
  echo "## Compose 服务状态"
  echo "\`\`\`"
  cat "$DEBUG_DIR/compose-ps.txt" 2>/dev/null || echo "（无法获取）"
  echo "\`\`\`"
  echo ""
  echo "## API 探针（tester 网络）"
  echo "\`\`\`"
  cat "$DEBUG_DIR/api-probe.log" 2>/dev/null || echo "（探针未执行或失败）"
  echo "\`\`\`"
  echo ""
  echo "## Anima 日志末尾（50 行）"
  echo "\`\`\`"
  tail -n 50 "$DEBUG_DIR/anima.log" 2>/dev/null || echo "（无 anima 日志）"
  echo "\`\`\`"
  echo ""
  echo "完整日志见 workflow artifacts：\`blackbox-debug\`、\`anima-service-log\`、\`playwright-report\`（若 UI 测试已运行）。"
} >"$DEBUG_DIR/summary.md"

cat "$DEBUG_DIR/summary.md"
