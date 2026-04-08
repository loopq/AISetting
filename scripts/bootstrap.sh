#!/bin/bash
# AI Dotfiles Bootstrap Script
# 用途：在新机器上初始化 AI 开发环境配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/dotfiles-ai"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "========================================"
echo "  AI Dotfiles Bootstrap"
echo "========================================"
echo ""

# 检查 dotfiles 目录是否存在
if [ ! -d "$DOTFILES_DIR" ]; then
    echo -e "${RED}Error: $DOTFILES_DIR not found${NC}"
    echo "Please clone your dotfiles repository first:"
    echo "  git clone git@github.com:loopq/AISetting.git ~/dotfiles-ai"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}备份目录: $BACKUP_DIR${NC}"
echo ""

# 函数：安全创建 symlink
safe_link() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ -L "$dest" ]; then
        echo "  $name: 已存在 symlink，更新..."
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "  $name: 已存在文件，备份到 backup/"
        mv "$dest" "$BACKUP_DIR/"
    fi

    ln -s "$src" "$dest"
    echo -e "  ${GREEN}✓ $name 已配置${NC}"
}

# 函数：安全复制（如果不存在）
safe_copy() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ -e "$dest" ]; then
        echo "  $name: 已存在，跳过"
    else
        cp -r "$src" "$dest"
        echo -e "  ${GREEN}✓ $name 已复制${NC}"
    fi
}

echo "1. 配置 Claude Code..."
if [ -d "$HOME/.claude" ]; then
    safe_link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json" "settings.json"
    safe_link "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents" "agents"
    safe_link "$DOTFILES_DIR/claude/hooks" "$HOME/.claude/hooks" "hooks"
    safe_link "$DOTFILES_DIR/claude/skills" "$HOME/.claude/skills" "skills"
else
    echo "  创建 ~/.claude 目录..."
    mkdir -p "$HOME/.claude"
    ln -s "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    ln -s "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
    ln -s "$DOTFILES_DIR/claude/hooks" "$HOME/.claude/hooks"
    ln -s "$DOTFILES_DIR/claude/skills" "$HOME/.claude/skills"
    echo -e "  ${GREEN}✓ Claude 配置完成${NC}"
fi
echo ""

echo "2. 配置 Codex..."
if [ -d "$HOME/.codex" ]; then
    safe_link "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml" "config.toml"
    safe_link "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md" "AGENTS.md"
    safe_link "$DOTFILES_DIR/codex/rules" "$HOME/.codex/rules" "rules"
else
    echo "  创建 ~/.codex 目录..."
    mkdir -p "$HOME/.codex"
    ln -s "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
    ln -s "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    ln -s "$DOTFILES_DIR/codex/rules" "$HOME/.codex/rules"
    echo -e "  ${GREEN}✓ Codex 配置完成${NC}"
fi
echo ""

echo "3. 配置 Zsh..."
safe_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" ".zshrc"
echo ""

echo "4. 检查 AI Secrets..."
if [ ! -f "$HOME/.config/ai-secrets.env" ]; then
    echo -e "  ${YELLOW}⚠ ai-secrets.env 不存在${NC}"
    echo "  创建模板..."
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/ai-secrets.env" << 'EOF'
# AI 工具敏感信息配置
# 此文件不应被提交到 Git

# Anthropic (Claude Code)
export ANTHROPIC_AUTH_TOKEN="your_token_here"
export ANTHROPIC_BASE_URL="http://127.0.0.1:15721"

# Telegram Bot (用于 hooks/send-to-telegram.sh)
export TELEGRAM_BOT_TOKEN="your_bot_token_here"

# OpenAI/Codex (如果需要)
# export OPENAI_API_KEY="your_key_here"
EOF
    echo -e "  ${GREEN}✓ 模板已创建: ~/.config/ai-secrets.env${NC}"
    echo -e "  ${YELLOW}请编辑该文件，填入你的真实 API Key${NC}"
else
    echo -e "  ${GREEN}✓ ai-secrets.env 已存在${NC}"
fi
echo ""

echo "5. 设置权限..."
if [ -f "$HOME/.claude/hooks/send-to-telegram.sh" ]; then
    chmod +x "$HOME/.claude/hooks/send-to-telegram.sh"
    echo "  ✓ send-to-telegram.sh 已设为可执行"
fi
echo ""

echo "========================================"
echo -e "${GREEN}Bootstrap 完成!${NC}"
echo "========================================"
echo ""
echo "下一步:"
echo "  1. 编辑 ~/.config/ai-secrets.env 填入你的 API Key"
echo "  2. 运行 'source ~/.zshrc' 加载配置"
echo "  3. 运行 'claude' 或 'codex' 测试"
echo ""
echo "备份文件位于: $BACKUP_DIR"
