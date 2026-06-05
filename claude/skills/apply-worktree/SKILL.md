---
name: apply-worktree
description: 在 CC 内把当前（或指定）git worktree 的 base..branch cherry-pick 回本地 base，成功后删 worktree + 分支。底层复用 ~/.config/worktree-tools/worktree.zsh 的 _wt_apply（单一事实源）。关键：apply 是删 worktree 的终结操作，删完当前会话的 cwd 就没了——所以它必须是本会话最后一条 Bash，且结果只看命令输出里的 ✅/❌。触发：用户说 /apply-worktree、apply worktree、合入/收尾 worktree。
---

# Apply Worktree（CC 内安全合入）

把一个 git worktree 的 `base..branch` cherry-pick 回**本地** base 持有区（holder），成功后删除该 worktree + 分支。全程不碰远程。

底层直接调用 `~/.config/worktree-tools/worktree.zsh` 里的 `_wt_apply`（含全部门禁：本地 base 存在、空范围拦截、holder clean 门禁、空提交自动 `--skip`、冲突即停并保留）。**本 skill 不重写这套逻辑**。

## CC 内的 cwd 真相（必读，决定了执行方式）

实测：本 harness 把 CC 的 Bash 工作目录**钉死在项目根（即当前 worktree）**，任何 `cd`（独立或复合）跑完都会被**重置回 worktree**。所以：

- ❌ 「先 `cd` 到主仓再删」在 CC 里**做不到**——cd 不持久，会被重置。
- ✅ 真正的 cwd-safety 由 `_wt_apply` **自己**保证：它在 `git worktree remove` 之前会 `cd "$holder"`（在它自己的子 shell 内），所以**单条 apply 命令内部**删 worktree 是安全的、能正常打印 ✅。
- ⚠️ 唯一会出错的是**删完之后再跑下一条 Bash**——那时 CC 的 cwd（被删的 worktree）已悬空。

**结论 = 执行铁律**：apply 命令必须是本会话**最后一条 Bash**；它跑完后**不要再调用任何 Bash 工具**（包括"验证一下"），直接根据这条命令的 stdout 里的 `✅ / ❌` 写最终汇报。

> 最干净的用法（可选）：从一个**项目根不是目标 worktree** 的 CC 会话里调本 skill（比如在主仓里开的会话），那样删 worktree 完全不碰 CC 的 cwd，毫无副作用。但从 worktree 内部调也行——只要把它当终结操作。

## 步骤

### 1. 预检（只读，worktree 还在，安全）

分支名 = 用户传入参数；没传且当前在 worktree 内就用当前分支。

```bash
BR="<用户参数，没有则留空>"
zsh -c 'source ~/.config/worktree-tools/worktree.zsh
  br="'"$BR"'"; [ -z "$br" ] && br=$(git rev-parse --abbrev-ref HEAD)
  wt=$(_wt_path_of "$br")
  base=$(git -C "$wt" config --get worktree.base 2>/dev/null)
  holder=$(_wt_path_of "$base")
  echo "branch=$br"; echo "wt=$wt"; echo "base=$base"; echo "holder=$holder"
  echo "ahead=$(git -C "$wt" rev-list --count "$base..$br" 2>/dev/null)"
  echo "holder_dirty=$(git -C "$holder" status --porcelain 2>/dev/null | wc -l | tr -d " ")"'
```

任一不满足就**转述原因并停止**（绝不自己用 git 兜底 / fetch / push）：
- 不在 git 仓 / `wt` 空 → 找不到该分支的 worktree。
- `base` 空 → worktree 没记 `worktree.base`。
- `holder` 空 → base 没在任何工作区 checkout（提示用户先 `git checkout <base>`）。
- `ahead` 不是 >0 整数 → 没有新提交，无需 apply。
- `holder_dirty` ≠ 0 → base 持有区有未提交改动，先弄干净。

预检通过后，**把要合入的内容和落点（`branch → base @ holder`，ahead 个 commit）讲给用户**。若这是个不可逆且需要确认的合入，先确认再下一步。

### 2. 执行合入 + 清理（**本会话最后一条 Bash**）

```bash
zsh -c 'source ~/.config/worktree-tools/worktree.zsh && _wt_apply "<BR>"'
```

- `_wt_apply` 内部已 `cd "$holder"` 再 `git worktree remove`，这条命令本身能安全跑完。
- **看这条命令的 stdout 判定结果**（别再开新 Bash 去验证，那会因 cwd 悬空报错）：
  - 含 `✅ 已合入 ... 并清理 worktree` → 成功。
  - 含 `❌ cherry-pick 冲突，已停。worktree 和分支保留。` → 冲突，worktree 仍在。
  - 其他 `❌` → 门禁失败，worktree 仍在。
- 命令尾部可能附带 harness 的 `Shell cwd was reset ...`/getcwd 警告（因为 worktree 已被删）——这是预期的，**不是失败信号**，以 stdout 里的 ✅/❌ 为准。

### 3. 报告（直接写文字，不要再调 Bash）

- 成功 → 告知已合入 `<BR>` → `<base>`（holder=`<holder>`）并删除 worktree；提示：本会话原 worktree 已不存在，后续若要继续干活请在 `<holder>`（或主仓）新开一个 CC 会话。
- 冲突 / 门禁失败 → 原样转述 `_wt_apply` 的提示，说明 worktree 与分支仍保留，给出后续手动步骤（去 holder `git cherry-pick --continue/--abort`）。

## 硬性规则

- **apply 命令之后不再调用任何 Bash 工具**（这是避免 cwd 悬空报错的唯一可靠手段）。
- 删除型操作，宁停勿猜：门禁不过就停下转述，绝不自动 fetch / push / 强制兜底。
- 只动**本地** base，不碰远程。
- 不修改 `worktree.zsh`——它是单一事实源，本 skill 只调用它。
