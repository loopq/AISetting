#!/bin/bash
# 仓库 → 本机：全量复制（新机器初始化 / 已有机器更新），先备份再覆盖，零 symlink
# 用法：./scripts/apply.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/scripts/manifest.sh"

BACKUP_DIR="$HOME/.ai-setting-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for entry in "${MANIFEST[@]}"; do
  src="$REPO_DIR/${entry#*:}"
  dest="$HOME/${entry%%:*}"
  if [ ! -e "$src" ]; then
    echo "⚠️  跳过（仓库不存在）：$src"
    continue
  fi
  # 备份现有配置（含 symlink 本体），然后清掉
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${entry%%:*}")"
    cp -RP "$dest" "$BACKUP_DIR/${entry%%:*}" || true
    rm -rf "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  rsync -a "${RSYNC_EXCLUDES[@]}" "$src" "$dest"
done

# CLAUDE.md 单一事实源：仓库只存 codex/AGENTS.md，这里复制成真实文件（不做 symlink）
rm -f "$HOME/.claude/CLAUDE.md"
cp "$REPO_DIR/codex/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# 秘密文件：只建模板，真实 token 必须手动填
if [ ! -f "$HOME/.config/ai-secrets.env" ]; then
  mkdir -p "$HOME/.config"
  cp "$REPO_DIR/docs/secrets-template.env" "$HOME/.config/ai-secrets.env"
  chmod 600 "$HOME/.config/ai-secrets.env"
  echo "⚠️  已创建 ~/.config/ai-secrets.env 模板，请填入真实 token"
fi

echo "✅ 配置已应用，原配置备份于 $BACKUP_DIR"
