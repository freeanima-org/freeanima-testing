# raw-conversations

LLM 生成的纯文本对话（Issue #2）。每条场景一个 `.txt`，标注格式示例：

```
[USER] 帮我看看 freeanima 目录下有什么文件
[TOOL_CALL: terminal] {"command": "ls"}
[TOOL_RESULT: terminal] {"output": "..."}
[ASSISTANT] 有三个目录
```

由 `generators/` 在 schema 变更时转换为结构化 JSON，**不重复调 LLM**。
