# AISetting：symlink 方案迁移为全量复制同步

## 背景与动机

旧方案：仓库 clone 到 `~/dotfiles-ai`，`bootstrap.sh` 把 `~/.claude`、`~/.codex`、`~/.zshrc` 等做成指向仓库的 symlink。问题：

1. **symlink 危险**：仓库目录被移动/删除时本机配置直接失效；工具改写配置文件时实际写入仓库工作区，未 review 即成为待提交内容。
2. **已发生秘密泄露**：`claude/hooks/send-to-telegram.sh` 硬编码 Telegram Bot Token 被推到公开仓库（需 BotFather 换 token 补救）。
3. 仓库混入 `.idea/` 等 IDE 垃圾。

## 新方案：单向全量复制

仓库位置固定为 `/Users/loopq/dev/tools/AISetting`（普通 clone，零 symlink）。

```
本机配置 --sync.sh（白名单全量覆盖入仓 + 泄密门禁 + commit/push）--> GitHub
GitHub  --apply.sh（备份现有配置后全量复制出仓）------------------> 其他机器
```

## 数据结构：一份白名单清单

`scripts/manifest.sh` 是唯一事实源，`sync.sh` 和 `apply.sh` 都迭代同一数组：

| 本机路径 | 仓库路径 |
|---|---|
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/agents/` | `claude/agents/` |
| `~/.claude/commands/` | `claude/commands/` |
| `~/.claude/hooks/` | `claude/hooks/` |
| `~/.claude/scripts/` | `claude/scripts/` |
| `~/.claude/skills/` | `claude/skills/`（42 个全量，symlink 解引用为真实文件） |
| `~/.claude/statusline-command.sh` | `claude/statusline-command.sh` |
| `~/.claude/figma-asset-export-guide.md` | `claude/figma-asset-export-guide.md` |
| `~/.codex/AGENTS.md` | `codex/AGENTS.md` |
| `~/.codex/config.toml` | `codex/config.toml` |
| `~/.codex/rules/` | `codex/rules/` |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.config/fish/` | `zsh/fish/` |
| `~/.config/worktree-tools/` | `config/worktree-tools/` |

要点：

- **白名单制**：sessions / history / cache / plugins 等垃圾根本不进同步范围，无需 .gitignore 体操。
- **全量覆盖语义**：sync 前先清空仓库内的受管目录（`claude/ codex/ zsh/ config/`）再复制，孤儿文件自动消亡（如本机已不存在的 `starship.toml`）。
- **`~/.claude/CLAUDE.md` 特例消除**：它是指向 `~/.codex/AGENTS.md` 的 symlink，仓库只存 `codex/AGENTS.md` 一份；apply 时复制成两个真实文件。
- **泄密门禁**：sync 复制完成后 grep 受管目录（`figd_`、`[0-9]+:AA`、`sk-ant`、`ghp_`、`AKIA` 等模式），命中即中止，不 commit。

## 秘密管理

所有 token 进 `~/.config/ai-secrets.env`（chmod 600，永不进仓库）：

- `~/.zshrc` source 它（FIGMA_TOKEN 已迁出）
- `send-to-telegram.sh` 自行 source 它（不依赖 shell 环境，token 为空直接退出）
- 模板见 `docs/secrets-template.env`

## 执行步骤

1. ✅ 本地排雷：两个 token 迁入 ai-secrets.env，改 `.zshrc` 与 hook 脚本
2. 仓库重构：删 `.idea/`、`scripts/bootstrap.sh`；写 `manifest.sh` / `sync.sh` / `apply.sh`；重写 README；更新 secrets-template
3. 首次 sync（不含 push）→ 门禁验证 → commit
4. **用户动作**：`git push`；BotFather `/revoke` 作废已泄露的 Bot Token 并更新 ai-secrets.env
