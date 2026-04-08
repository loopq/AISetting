# AI Dotfiles

可跨机器同步的 AI 开发环境配置仓库。

## 包含内容

- **Claude Code** 配置（settings.json、agents、hooks、skills）
- **Codex CLI** 配置（config.toml、AGENTS.md、rules）
- **Zsh** 配置（.zshrc）

## 快速开始

### 1. 克隆仓库

```bash
git clone git@github.com:loopq/AISetting.git ~/dotfiles-ai
cd ~/dotfiles-ai
```

### 2. 运行初始化脚本

```bash
./scripts/bootstrap.sh
```

### 3. 配置敏感信息

```bash
# 编辑 secrets 文件
vim ~/.config/ai-secrets.env

# 填入你的 API Key
export ANTHROPIC_AUTH_TOKEN="your_token_here"
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
```

### 4. 加载配置

```bash
source ~/.zshrc
```

## 目录结构

```
dotfiles-ai/
├── claude/
│   ├── settings.json      # Claude Code 核心配置
│   ├── agents/            # 自定义 Agents
│   │   ├── feishu-doc-converter.md
│   │   └── product-manager.md
│   ├── hooks/             # 钩子脚本
│   │   ├── send-to-telegram.sh
│   │   └── README.md
│   └── skills/            # 自定义 Skills
│       ├── codex/
│       ├── commit-staged/
│       ├── co_execute/
│       ├── execute-with-review/
│       ├── feishu-prd/
│       ├── git-commit-helper/
│       ├── plan-review/
│       └── skill-creator/
├── codex/
│   ├── config.toml        # Codex CLI 配置
│   ├── AGENTS.md          # Linus 角色定义
│   └── rules/
│       └── default.rules  # 自动审批规则
├── zsh/
│   └── .zshrc             # Zsh 配置
├── scripts/
│   └── bootstrap.sh       # 初始化脚本
├── docs/
│   └── secrets-template.env  # 敏感信息模板
└── .gitignore             # Git 忽略规则
```

## 工作原理

使用 **symlink** 方式管理配置：

```
~/.claude/settings.json -> ~/dotfiles-ai/claude/settings.json
~/.codex/config.toml    -> ~/dotfiles-ai/codex/config.toml
~/.zshrc                -> ~/dotfiles-ai/zsh/.zshrc
```

修改 `~/dotfiles-ai` 中的文件后，直接在仓库内提交即可。

## 安全说明

- ✅ 同步：配置、脚本、alias、agents
- ❌ 不同步：缓存、日志、历史记录、认证信息
- 🔒 敏感信息统一放在 `~/.config/ai-secrets.env`（不会被提交）

## 手动管理

如果不想使用 bootstrap.sh，可以手动创建 symlink：

```bash
# Claude
ln -s ~/dotfiles-ai/claude/settings.json ~/.claude/settings.json
ln -s ~/dotfiles-ai/claude/agents ~/.claude/agents
ln -s ~/dotfiles-ai/claude/hooks ~/.claude/hooks
ln -s ~/dotfiles-ai/claude/skills ~/.claude/skills

# Codex
ln -s ~/dotfiles-ai/codex/config.toml ~/.codex/config.toml
ln -s ~/dotfiles-ai/codex/AGENTS.md ~/.codex/AGENTS.md
ln -s ~/dotfiles-ai/codex/rules ~/.codex/rules

# Zsh
ln -s ~/dotfiles-ai/zsh/.zshrc ~/.zshrc
```

## 更新配置

```bash
cd ~/dotfiles-ai
git pull
# 配置会自动生效（通过 symlink）
```

## 注意事项

1. **代理端口**：`.zshrc` 中的代理端口为 52019，请根据你的实际代理软件调整
2. **项目路径**：`.zshrc` 中的 alias（如 `/neku`、`/oc`）需要根据你的实际项目路径调整
3. **硬编码路径**：已统一替换为 `$HOME`，可跨机器使用
