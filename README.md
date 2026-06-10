# freeanima-testing

[freeanima](https://github.com/freeanima-org/freeanima) 的**黑盒测试编排仓**（Issue #2）：Compose 基础设施 + 源码启动被测实例 + HTTP / Playwright 断言。

主仓仍保留单元测试与集成测试；本仓负责 **全栈黑盒** 与（日后）性能基线。

## 架构

```
PG + Redis (docker compose)
        ↓
freeanima @ 指定 SHA（bun service start，127.0.0.1:2658）
        ↓
blackbox/api (bun test) + blackbox/ui (Playwright)
```

被测代码通过 **checkout 指定 SHA** 注入，不用主仓 Dockerfile 里的 npm `@freeanima/cli` 镜像，以便 PR 验证真实源码。

## 本地

```bash
git clone --recurse-submodules https://github.com/freeanima-org/freeanima-testing.git
cd freeanima-testing
cp .env.example .env   # 可选

# 若未 submodule，可指向本地主仓：
# export FREEANIMA_DIR=/path/to/freeanima

bun install
bunx playwright install chromium

# 一键：起栈 → 测 API + UI →  teardown
bun run test:blackbox
```

分步：

```bash
bun run stack:up      # docker PG/Redis + anima 前台日志 → .anima-service.log
bun run test:api
bun run test:ui
bun run stack:down
```

## CI

| Workflow | 触发 |
|----------|------|
| `blackbox.yml` | `repository_dispatch` (`pr-verify`)、`workflow_dispatch`、`pull_request`（本仓） |
| `nightly.yml` | 每日 UTC 02:00、`workflow_dispatch` |

### 主仓 dispatch（稍后接入）

主仓 PR 在 quality 通过后 dispatch：

```yaml
event-type: pr-verify
client-payload: { "sha": "...", "pr_number": 123, "repo_full_name": "freeanima-org/freeanima" }
```

本仓 Secrets（可选）：

| Secret | 用途 |
|--------|------|
| `MAIN_REPO_STATUS_PAT` | 向主仓 PR 写 `freeanima/blackbox` commit status |

## 目录

```
blackbox/api/          # fetch 契约测试
blackbox/ui/           # Playwright（含原 chamber smoke）
config/                # 黑盒专用 config 模板
docker/                # PG + Redis only
generators/            # 测试数据转换（Issue #2）
raw-conversations/     # LLM 生成文本（Issue #2）
scripts/               # stack-up / run-blackbox
freeanima/             # git submodule → 主仓
```

## License

与 freeanima 组织策略一致；测试数据与脚本随本仓分发。
