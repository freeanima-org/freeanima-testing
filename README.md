# freeanima-testing

[freeanima](https://github.com/freeanima-org/freeanima) 的**黑盒测试编排仓**（Issue #2）：Docker Compose 全栈 + HTTP / Playwright 断言。

主仓仍保留单元测试与集成测试；本仓负责 **全栈黑盒** 与（日后）性能基线。

## 架构

```
Compose 内部网络（固定端口，不映射宿主机）
  postgres:5432 ─┐
  redis:6379    ─┼→ anima:2658（oven/bun + 源码 volume mount）
                 └→ tester（Playwright 官方镜像 + bun）→ http://anima:2658
```

被测代码通过 **checkout / submodule 指定 SHA** 挂载进 anima 容器，不用主仓 npm `@freeanima/cli` 镜像，以便 PR 验证真实源码。

## 前置

- Docker + Docker Compose v2
- freeanima 源码（submodule 或 `FREEANIMA_DIR`）

## 本地

```bash
git clone --recurse-submodules https://github.com/freeanima-org/freeanima-testing.git
cd freeanima-testing
cp .env.example .env   # 可选

# 若未 submodule，可指向本地主仓：
# export FREEANIMA_DIR=/path/to/freeanima

# 一键：起栈 → 测 API + UI → teardown
bun run test:blackbox
```

分步：

```bash
bun run stack:up      # postgres + redis + anima（compose healthcheck 就绪）
bun run test:api
bun run test:ui
bun run stack:down
```

调试 anima 日志：

```bash
docker compose -f docker/docker-compose.yml logs -f anima
```

## CI

| Workflow | 触发 |
|----------|------|
| `blackbox.yml` | `repository_dispatch` (`pr-verify`)、`workflow_dispatch`、`pull_request`（本仓） |
| `nightly.yml` | 每日 UTC 02:00、`workflow_dispatch` |

CI 仅需 Docker：构建 `tester` 镜像（基于 `mcr.microsoft.com/playwright` + bun）并在 compose 网络内跑测试。首次构建会拉取较大基础镜像，workflow 超时设为 30 分钟。

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
config/                # 黑盒专用 config 模板（compose 服务名）
docker/                # compose 栈 + tester Dockerfile（Playwright 基础镜像）
generators/            # 测试数据转换（Issue #2）
raw-conversations/     # LLM 生成文本（Issue #2）
scripts/               # stack-up / run-blackbox / compose-env
freeanima/             # git submodule → 主仓
```

## License

与 freeanima 组织策略一致；测试数据与脚本随本仓分发。
