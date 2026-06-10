# GitHub Secrets 配置

## freeanima（主仓）

Settings → Secrets and variables → Actions → New repository secret：

| Name | 说明 |
| ---- | ---- |
| `TESTING_REPO_DISPATCH_PAT` | Fine-grained PAT：对 `freeanima-org/freeanima-testing` 有 **Actions: Read and write** |

未配置时 `blackbox-dispatch` job 会失败；Quality 仍可通过。

## freeanima-testing

| Name | 说明 |
| ---- | ---- |
| `MAIN_REPO_STATUS_PAT` | （可选）对 `freeanima-org/freeanima` 有 **Commit statuses: Read and write**；用于 PR Checks 显示 `freeanima/blackbox` |

未配置时黑盒仍跑，只是不回写主仓 status。
