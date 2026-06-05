#!/bin/bash
# 同步白名单 —— 唯一事实源，sync.sh / apply.sh 都迭代这一份清单
# 格式："本机路径(相对 $HOME):仓库路径(相对仓库根)"，目录以 / 结尾
# 本机的 symlink 在入仓时一律解引用为真实文件（仓库零 symlink）

MANIFEST=(
  ".claude/settings.json:claude/settings.json"
  ".claude/agents/:claude/agents/"
  ".claude/commands/:claude/commands/"
  ".claude/hooks/:claude/hooks/"
  ".claude/scripts/:claude/scripts/"
  ".claude/skills/:claude/skills/"
  ".claude/statusline-command.sh:claude/statusline-command.sh"
  ".claude/figma-asset-export-guide.md:claude/figma-asset-export-guide.md"
  ".codex/AGENTS.md:codex/AGENTS.md"
  ".codex/config.toml:codex/config.toml"
  ".codex/rules/:codex/rules/"
  ".zshrc:zsh/.zshrc"
  ".config/fish/:zsh/fish/"
  ".config/worktree-tools/:config/worktree-tools/"
)

# 仓库内受 sync 管理的顶层目录：sync 前整体清空再重建，孤儿文件自动消亡
MANAGED_DIRS=(claude codex zsh config)

# 复制时统一排除的垃圾
RSYNC_EXCLUDES=(--exclude '.DS_Store' --exclude '*.log' --exclude '.runtime/')
