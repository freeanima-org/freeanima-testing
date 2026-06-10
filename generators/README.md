# generators

将 `raw-conversations/` 转为符合当前 freeanima PG schema 的测试数据。

- `sessions.ts` — 对话 → messages（待实现）
- schema 变更时在 CI 或本地对 submodule 指向的 freeanima 跑一次生成
