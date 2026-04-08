# AI Dotfiles

面向 AI 的可跨机器同步开发环境配置仓库。

## 仓库概述

此仓库使用 **symlink** 方式管理配置，所有配置文件通过符号链接指向 `~/dotfiles-ai` 目录。

```
~/.claude/settings.json -> ~/dotfiles-ai/claude/settings.json
~/.codex/config.toml    -> ~/dotfiles-ai/codex/config.toml
~/.zshrc                -> ~/dotfiles-ai/zsh/.zshrc
```

## 目录结构

```
dotfiles-ai/
├── claude/
│   ├── settings.json      # Claude Code 核心配置
│   ├── agents/            # 自定义 Agents
│   ├── hooks/             # 钩子脚本
│   └── skills/            # 自定义 Skills
├── codex/
│   ├── config.toml        # Codex CLI 配置
│   ├── AGENTS.md          # Linus 角色定义
│   └── rules/             # 自动审批规则
├── zsh/
│   └── .zshrc             # Zsh 配置
├── scripts/
│   └── bootstrap.sh       # 初始化脚本
└── .gitignore             # 忽略缓存/状态/敏感信息
```

---

## 场景一：同步到本地（新机器初始化）

当用户要求"配置 AI 环境"或"同步配置"时，执行以下步骤：

### 步骤 1：克隆仓库

```bash
# 检查是否已存在
test -d ~/dotfiles-ai && echo "已存在" || git clone git@github.com:loopq/AISetting.git ~/dotfiles-ai
```

### 步骤 2：运行初始化脚本

```bash
cd ~/dotfiles-ai && ./scripts/bootstrap.sh
```

此脚本会：
- 创建 `~/.claude` 和 `~/.codex` 目录（如不存在）
- 建立 symlink 链接配置文件
- 创建 `~/.config/ai-secrets.env` 模板（如不存在）
- 备份原有配置到 `~/.dotfiles-backup-时间戳/`

### 步骤 3：配置敏感信息

**必须检查** `~/.config/ai-secrets.env` 是否存在且已配置：

```bash
# 检查文件是否存在
test -f ~/.config/ai-secrets.env && echo "存在" || echo "需要创建"
```

如不存在，创建并提示用户填入：

```bash
cat > ~/.config/ai-secrets.env << 'EOF'
# AI 工具敏感信息配置
export ANTHROPIC_AUTH_TOKEN="your_token_here"
export ANTHROPIC_BASE_URL="http://127.0.0.1:15721"
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
EOF
```

### 步骤 4：加载配置

```bash
source ~/.zshrc
```

### 验证安装

```bash
# 检查 symlink 是否正确
ls -la ~/.claude/settings.json
ls -la ~/.codex/config.toml
ls -la ~/.zshrc

# 检查环境变量
echo $ANTHROPIC_AUTH_TOKEN
```

---

## 场景二：本地修改同步到远端

当用户对配置做了修改（如新增 skill、修改 agent、调整 alias），需要同步到远端仓库。

### 工作流程

```bash
# 1. 进入仓库目录
cd ~/dotfiles-ai

# 2. 检查修改状态
git status

# 3. 查看具体变更（确认无敏感信息）
git diff

# 4. 添加所有修改
git add -A

# 5. 提交（使用中文描述变更内容）
git commit -m "描述做了什么修改"

# 6. 推送到远端
git push origin main
```

### 常见修改场景

#### 新增 Skill

```bash
# Skill 已创建在 ~/.claude/skills/new-skill/
# 由于 symlink 关系，实际文件已在 ~/dotfiles-ai/claude/skills/

cd ~/dotfiles-ai
git add claude/skills/new-skill/
git commit -m "新增 skill: new-skill，用于 xxx 功能"
git push origin main
```

#### 修改 Agent

```bash
# 修改后提交
cd ~/dotfiles-ai
git add claude/agents/
git commit -m "更新 agent: product-manager，优化了 xxx 逻辑"
git push origin main
```

#### 修改 Zsh Alias

```bash
# 编辑 zsh/.zshrc 后
cd ~/dotfiles-ai
git add zsh/.zshrc
git commit -m "zsh: 添加 xxx alias"
git push origin main
```

### 提交规范

- **feat**: 新功能（skill、agent、alias）
- **fix**: 修复问题
- **update**: 更新配置
- **refactor**: 重构（不影响功能）

---

## 场景三：远端有更新，同步到本地

当远端仓库有更新，需要拉取到本地：

```bash
cd ~/dotfiles-ai
git pull origin main

# 由于使用 symlink，配置会自动生效
# 重新加载 zsh 配置
source ~/.zshrc
```

---

## 安全规则

**绝对禁止提交以下内容：**

- API keys、tokens、credentials
- `~/.config/ai-secrets.env`
- 缓存文件、日志、历史记录
- 包含本机绝对路径的配置（应使用 `$HOME`）

**提交前检查：**

```bash
cd ~/dotfiles-ai
git diff --cached

# 检查是否有敏感信息泄露
grep -r "sk-" . --include="*.json" --include="*.toml" 2>/dev/null || echo "无 sk- 开头的 key"
grep -r "[0-9]*:[a-zA-Z0-9_-]*" . --include="*.sh" 2>/dev/null | grep -v "docs/" | head -5
```

---

## 快速参考

| 操作 | 命令 |
|------|------|
| 查看配置状态 | `cd ~/dotfiles-ai && git status` |
| 查看变更 | `git diff` |
| 提交修改 | `git add -A && git commit -m "xxx" && git push` |
| 拉取更新 | `git pull origin main && source ~/.zshrc` |
| 查看 symlink | `ls -la ~/.claude/` |

---

## 注意事项

1. **代理端口**：`.zshrc` 中代理端口为 52019，新机器可能需要调整
2. **项目路径**：`.zshrc` 中的 alias（如 `/neku`）需要根据实际项目路径修改
3. **权限问题**：hooks 脚本需要可执行权限，`bootstrap.sh` 会自动设置
