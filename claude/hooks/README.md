# Claude Hooks

## send-to-telegram.sh

Claude Code 的 Stop hook，用于将响应发送回 Telegram。

### 安装步骤

1. 复制脚本到 `~/.claude/hooks/` 目录
2. 在 `~/.config/ai-secrets.env` 中配置 Telegram Bot Token：
   ```bash
   export TELEGRAM_BOT_TOKEN="your_bot_token_here"
   ```
3. 确保脚本可执行：
   ```bash
   chmod +x ~/.claude/hooks/send-to-telegram.sh
   ```

### 工作原理

- 当 Claude Code 完成响应时，脚本会自动将结果发送到 Telegram
- 仅响应从 Telegram 发起的消息（通过 `telegram_pending` 文件标记）
- 自动移除 memory 块，只发送实际回复内容
- 支持 HTML 格式化（粗体、斜体、代码块等）
