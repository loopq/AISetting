#!/bin/bash
# 本机配置 → 仓库：白名单全量覆盖，过泄密门禁后 commit + push
# 用法：./scripts/sync.sh [--no-push]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/scripts/manifest.sh"

NO_PUSH=0
[ "${1:-}" = "--no-push" ] && NO_PUSH=1

# 1. 清空受管目录（全量覆盖语义：本机已删的东西不会在仓库留尸体）
for dir in "${MANAGED_DIRS[@]}"; do
  rm -rf "${REPO_DIR:?}/$dir"
done

# 2. 按白名单复制，-L 解引用 symlink
for entry in "${MANIFEST[@]}"; do
  src="$HOME/${entry%%:*}"
  dest="$REPO_DIR/${entry#*:}"
  if [ ! -e "$src" ]; then
    echo "⚠️  跳过（本机不存在）：$src"
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  rsync -aL "${RSYNC_EXCLUDES[@]}" "$src" "$dest"
done

# 3. 泄密门禁：仓库是公开的，命中任何疑似秘密立即中止
PATTERNS='figd_[A-Za-z0-9_-]{20,}|[0-9]{8,}:AA[A-Za-z0-9_-]{20,}|sk-ant-[A-Za-z0-9_-]{10,}|sk-[A-Za-z0-9]{30,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}'
if leaks=$(grep -rInE "$PATTERNS" "${MANAGED_DIRS[@]/#/$REPO_DIR/}" 2>/dev/null); then
  echo "🔴 泄密门禁拦截！以下内容疑似秘密，已中止（未 commit）："
  echo "$leaks"
  exit 1
fi
echo "✅ 泄密门禁通过"

# 4. commit（无变更则安静退出）
cd "$REPO_DIR"
git add -A
if git diff --cached --quiet; then
  echo "无变更，跳过 commit"
  exit 0
fi
git commit -m "sync: $(hostname -s) $(date +%Y-%m-%d)"

if [ "$NO_PUSH" = "1" ]; then
  echo "✅ 已 commit（--no-push 模式，请手动 git push）"
else
  git push
  echo "✅ 已推送"
fi
