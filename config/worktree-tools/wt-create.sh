#!/usr/bin/env bash
# wt-create.sh — 在当前 git 仓基于 <base> 创建一个 worktree
#
# 用法: wt-create.sh <base-branch> [new-branch-name]
# 约定: 所有人类可读信息走 stderr；stdout 只在成功时打印一行 = 新 worktree 的绝对路径
#       （供 zsh 包装函数捕获后 cd 进去）。

set -euo pipefail

WORKTREE_ROOT="/Users/loopq/dev/worktrees"

die() { echo "❌ $*" >&2; exit 1; }

base="${1:-}"
newname="${2:-}"
[ -n "$base" ] || die "用法: create-worktree <base-branch> [new-branch-name]"

# 必须在 git 仓内
git rev-parse --git-dir >/dev/null 2>&1 || die "当前不在 git 仓内"

# repo 名 = git 公共目录(.git)父目录的 basename。
# 用 --git-common-dir 保证从主仓或任意 worktree 调用都解析到同一 repo 名；
# 用 --path-format=absolute 修正主仓根目录下返回相对 ".git" 的坑。
common=$(git rev-parse --path-format=absolute --git-common-dir)
repo=$(basename "$(dirname "$common")")

# 解析 base 分支
if git show-ref --verify --quiet "refs/heads/$base"; then
  :  # 本地已有，直接用
elif git show-ref --verify --quiet "refs/remotes/origin/$base"; then
  # 本地无、origin 有：只建本地 ref，绝不动当前 HEAD
  git branch "$base" "origin/$base" >&2 || die "从 origin/$base 建本地分支失败"
  echo "ℹ️  已从 origin/$base 落地本地分支 $base" >&2
else
  die "本地和 origin 都没有分支: $base"
fi

# 新分支名：不给则按 base + 时间戳生成
if [ -z "$newname" ]; then
  newname="${base}-wt-$(date +%m%d-%H%M%S)"
fi

# 新分支名不能已占用
if git show-ref --verify --quiet "refs/heads/$newname"; then
  die "分支已存在: $newname"
fi

dir="$WORKTREE_ROOT/$repo/$newname"
if [ -e "$dir" ]; then
  die "目标路径已存在: $dir"
fi

mkdir -p "$WORKTREE_ROOT/$repo"
git worktree add -b "$newname" "$dir" "$base" >&2 || die "git worktree add 失败"

# 记录 base，apply 时据此精确算 cherry-pick 范围
git -C "$dir" config worktree.base "$base"

echo "✅ worktree 已创建: $newname (base=$base)" >&2
echo "$dir"
