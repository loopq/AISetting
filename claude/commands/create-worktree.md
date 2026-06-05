---
description: 在当前 git 仓基于 <base> 创建 worktree（落到 /Users/loopq/dev/worktrees/<repo>/<branch>），记录 base 并报告路径。
---

运行 `bash ~/.config/worktree-tools/wt-create.sh $ARGUMENTS` 创建 git worktree。

- 第一个参数 = base 分支名；第二个可选 = 新分支名（不给则脚本按 `<base>-wt-<时间戳>` 自动生成）。
- 脚本会：解析/落地本地 base（本地无、origin 有则 `git branch` 建本地 ref，**不动当前 HEAD**）→ `git worktree add` 到 `/Users/loopq/dev/worktrees/<repo>/<新分支>` → 写入 `worktree.base`。
- 把脚本 stdout **最后一行**的 worktree 绝对路径清晰报给用户，并附一条可直接复制的 `cd <path>`，方便他新开终端 tab 跑独立 Claude。
- **不要**在当前会话里 cd 进该 worktree 干活（它在项目根之外，CC 文件权限通常需要在新 tab 里另起独立 Claude 承载）——除非用户明确要求。
- 脚本非零退出 → 把 stderr 的错误原样转述给用户，**不要**自己用 git 兜底重试。

合入 / 销毁 worktree 用 shell 里的 `/apply-worktree <branch>` 和 `/destroy-worktree <branch>`（删除型操作，CC 内不提供）。
