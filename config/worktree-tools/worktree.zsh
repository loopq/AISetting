# worktree.zsh — git worktree 工具链（在 ~/.zshrc 里 source 本文件）
#
#   /create-worktree <base> [name]   建 worktree（CC 命令 + shell 别名同名，底层共享 wt-create.sh）
#   /apply-worktree  <branch>        cherry-pick base..branch 回本地 base 后删 worktree+分支（仅 shell）
#   /destroy-worktree <branch>       直接删 worktree+分支，不合入（仅 shell）
#
# apply/destroy 是删除型操作：删 worktree 前若 shell 正站在里面，先 cd 出去，
# 否则 cwd 悬空。这正是它们必须是 zsh 函数（而非 skill 子进程）的原因。

# 反查某分支对应的 worktree 路径（用 substr 解析，容忍路径含空格）
_wt_path_of() {
  git worktree list --porcelain | awk -v b="refs/heads/$1" '
    /^worktree /{p=substr($0,10)}
    /^branch /{if(substr($0,8)==b){print p; exit}}'
}

# 主仓工作目录（git 公共目录的父目录）
_wt_main_dir() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  dirname "$common"
}

_wt_create() {
  emulate -L zsh
  local out dir
  out=$(bash ~/.config/worktree-tools/wt-create.sh "$@") || return $?
  dir=${out##*$'\n'}   # 只取最后一行（约定：脚本 stdout 末行 = worktree 路径）
  if [[ -n "$dir" ]]; then
    cd "$dir" && echo "→ 已进入 $dir"
  fi
}

_wt_destroy() {
  emulate -L zsh
  local branch="$1"
  [[ -n "$branch" ]] || { echo "❌ 用法: /destroy-worktree <branch>" >&2; return 1 }
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "❌ 当前不在 git 仓内" >&2; return 1 }

  local main wt
  main=$(_wt_main_dir) || return 1
  wt=$(_wt_path_of "$branch")

  # 删 worktree 前无条件把 shell 迁出到主仓，避免站在被删目录里导致 cwd 悬空
  cd "$main" 2>/dev/null || cd ~

  if [[ -n "$wt" ]]; then
    git -C "$main" worktree remove --force "$wt" || { echo "❌ worktree remove 失败: $wt" >&2; return 1 }
    echo "✅ 已删 worktree $wt" >&2
  else
    echo "ℹ️  没找到 $branch 的 worktree，只尝试删分支" >&2
  fi
  git -C "$main" worktree prune
  if git -C "$main" branch -D "$branch" 2>/dev/null; then
    echo "✅ 已删分支 $branch" >&2
  else
    echo "ℹ️  分支 $branch 不存在或已删" >&2
  fi
}

_wt_apply() {
  emulate -L zsh
  local branch="$1"
  [[ -n "$branch" ]] || { echo "❌ 用法: /apply-worktree <branch>" >&2; return 1 }
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "❌ 当前不在 git 仓内" >&2; return 1 }

  local wt
  wt=$(_wt_path_of "$branch")
  [[ -n "$wt" ]] || { echo "❌ 找不到分支 $branch 的 worktree" >&2; return 1 }

  # 读 create 时记录的 base
  local base
  base=$(git -C "$wt" config --get worktree.base 2>/dev/null)
  [[ -n "$base" ]] || { echo "❌ worktree 未记录 worktree.base，无法确定合入目标" >&2; return 1 }

  # 本地 base 必须存在（绝不从远程拉）
  git show-ref --verify --quiet "refs/heads/$base" || {
    echo "❌ 本地没有 base 分支 $base（收尾阶段缺 base 属异常，拒绝从远程拉）" >&2; return 1 }

  # 空范围门禁
  local n
  n=$(git -C "$wt" rev-list --count "$base..$branch")
  [[ "$n" -gt 0 ]] || { echo "❌ $branch 相对 $base 没有新提交，无需 apply" >&2; return 1 }

  # 定位 base 持有工作区（base 通常 checkout 在主仓或某 worktree；git 不许同分支双 checkout）
  local holder
  holder=$(_wt_path_of "$base")
  [[ -n "$holder" ]] || {
    echo "❌ base $base 没在任何工作区 checkout（若主仓处于 detached HEAD，请先 git checkout $base），先 checkout 再 apply" >&2
    return 1 }

  # clean 门禁：不动持有区里用户未提交的活
  [[ -z "$(git -C "$holder" status --porcelain)" ]] || {
    echo "❌ base 持有区 $holder 有未提交改动，先处理干净再 apply" >&2; return 1 }

  echo "ℹ️  cherry-pick $base..$branch（$n 个 commit）→ $holder" >&2
  git -C "$holder" cherry-pick "$base..$branch"
  local rc=$?
  while (( rc != 0 )); do
    # 区分「空提交暂停」与「真冲突」：真冲突会留下未合并文件；
    # 空提交（改动已在 base 上）则工作区干净，自动 --skip 丢弃后继续。
    if [[ -z "$(git -C "$holder" diff --name-only --diff-filter=U)" ]] \
       && git -C "$holder" rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null 2>&1; then
      echo "ℹ️  跳过一个空提交（改动已在 $base 上）" >&2
      git -C "$holder" cherry-pick --skip
      rc=$?
    else
      echo "❌ cherry-pick 冲突，已停。worktree 和分支保留。" >&2
      echo "   去 $holder 用 git cherry-pick --continue / --abort 处理。" >&2
      return 1
    fi
  done

  # 成功 → 清理。无条件先把 shell 迁出被删 worktree，停到 holder
  cd "$holder" 2>/dev/null || cd ~
  git -C "$holder" worktree remove --force "$wt" || {
    echo "❌ worktree remove 失败: $wt（cherry-pick 已成功，请手动清理）" >&2; return 1 }
  git -C "$holder" worktree prune
  git -C "$holder" branch -D "$branch"
  echo "✅ 已合入 $branch → $base 并清理 worktree（停在 $holder）" >&2
}

alias "/create-worktree"="_wt_create"
alias "/destroy-worktree"="_wt_destroy"
alias "/apply-worktree"="_wt_apply"
