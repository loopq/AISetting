---
name: co_execute
description: Codex 执行 plan（写代码），Claude 对 git diff 做 code review，发现问题则让 Codex 修复，最多 3 轮修复。上下文隔离在 subagent 内部。
---

# co_execute

## 触发方式

```
/co_execute plans/my-plan.md
```

## Claude Code 的职责（主线程）

1. 验证 `$ARGUMENTS` 指向的 plan 文件存在，不存在则报错退出
2. 记录当前 git HEAD 作为 diff 基准：`git rev-parse HEAD`（如果不是 git 仓库则记为空）
3. 用 **Agent tool**（`general-purpose`）启动 subagent，传入下方的 subagent prompt（替换 `{PLAN_FILE}` 和 `{BASE_COMMIT}`）
4. 等待 subagent 完成
5. 把 subagent 返回的摘要报告给用户，不做额外处理

## Subagent Prompt 模板

将以下内容作为 Agent tool 的 prompt，替换占位符：

---

你是一个 plan 执行与 review 协调员。你的任务是：
1. 让 Codex 执行 `{PLAN_FILE}` 中描述的开发任务
2. 对 Codex 的产出做 code review
3. 发现问题则让 Codex 修复，最多 **3 轮修复**

### 前置检查

1. 读取 `{PLAN_FILE}`，确认文件存在且有内容
2. 确认 `~/.claude/skills/codex/scripts/ask_codex.sh` 可执行
3. 生成本次执行的 review ID：`REVIEW_ID=$(date +%Y%m%d-%H%M%S)`
4. 确保 `reviews/` 目录存在

### Phase 1：Codex 执行 Plan

调用 Codex 执行 plan，使用 `--reasoning high` 保证代码质量：

```bash
~/.claude/skills/codex/scripts/ask_codex.sh \
  "$(cat {PLAN_FILE})" \
  --file "{PLAN_FILE}" \
  --reasoning high
```

- 从输出中提取 `session_id=xxx`，保存为 `exec_session_id`（后续修复轮次复用）
- 读取 `output_path=xxx`，查看 Codex 的执行摘要
- 如果调用失败（exit code 非 0），停止并报告错误

### Review 文件格式（每轮通用）

写入 `reviews/co-execute-{REVIEW_ID}-round{N}.md`：

```markdown
# co_execute Review — Round {N}

**Plan**: {PLAN_FILE}
**Date**: {YYYY-MM-DD HH:MM}
**Diff base**: {BASE_COMMIT 或 "uncommitted changes"}

## Changed Files
{git log 摘要}

## Issues Found

### Issue 1 ({severity}): {title}
**File**: {file}:{line}
{问题描述}
**Fix needed**: {具体修复建议}

...

## Summary
- Critical: {N}
- High: {N}
- Medium: {N}
- Low: {N}

**Review Status**: APPROVED / NEEDS_FIX
```

### Review 维度（每轮 Claude 亲自执行，不调用 Codex）

对照 `{PLAN_FILE}` 验收标准检查：
- **功能完整性**：Plan 中每个功能点是否实现，是否有遗漏场景
- **代码质量**：可读性、命名、复杂度（超过 3 层缩进？）、重复代码
- **安全性**：输入验证、SQL 注入/XSS/命令注入风险、硬编码密钥
- **测试覆盖**（如 plan 要求）：新功能是否有测试，是否覆盖边界和错误路径

### Codex 修复指令模板

```bash
~/.claude/skills/codex/scripts/ask_codex.sh \
  "请修复以下 code review 发现的问题：

{从 review 文件提取的 Issues 列表，包含文件路径、行号、问题描述和修复建议}

修复要求：
- 只修复上述列出的问题，不要做额外的重构
- 保持与已有代码风格一致
- 如果某个问题的修复会影响其他文件，一并修复" \
  --session {exec_session_id} \
  --reasoning medium
```

---

### Phase 2：Review 步骤（严格按顺序，共 3 轮，不多不少）

> ⚠️ **硬性规则**：总共只有下面 Review 1 / Review 2 / Review 3 三个节点。无论任何情况，执行完 Review 3 后必须停止，不得继续。

---

#### Review 1

1. 获取变更：
   - 若 `{BASE_COMMIT}` 不为空：`git diff {BASE_COMMIT}..HEAD` 和 `git log {BASE_COMMIT}..HEAD --oneline`
   - 若为空：`git diff HEAD` 和 `git diff --cached`
2. 对照 plan 做 code review（按上方维度）
3. 写入 `reviews/co-execute-{REVIEW_ID}-round1.md`

**Review 1 决策**：
- `APPROVED` → 输出成功摘要，**立即停止，不执行 Review 2**
- `NEEDS_FIX` → 调用 Codex 修复（使用上方修复指令模板），**继续 Review 2**

---

#### Review 2

1. 重新获取完整 diff（同 Review 1 的方式，不只看增量）
2. 对照 plan 做 code review
3. 写入 `reviews/co-execute-{REVIEW_ID}-round2.md`

**Review 2 决策**：
- `APPROVED` → 输出成功摘要，**立即停止，不执行 Review 3**
- `NEEDS_FIX` → 调用 Codex 修复，**继续 Review 3**

---

#### Review 3（最后一轮）

1. 重新获取完整 diff
2. 对照 plan 做 code review
3. 写入 `reviews/co-execute-{REVIEW_ID}-round3.md`

**Review 3 决策（无论结果如何，执行完必须停止）**：
- `APPROVED` → 输出成功摘要，**停止**
- `NEEDS_FIX` → 不再调用 Codex，**直接输出预警，停止**

### 3 轮未通过时的预警输出

```
⚠️ co_execute：3 轮修复后 code review 仍未通过

Codex 已执行 plan 并经过 3 轮 review + 修复，仍有未解决问题。建议人工介入。

未解决问题（来自 Round 3）：
{从 round 3 review 文件提取 Critical 和 High severity issues}

已变更文件：
{git log {BASE_COMMIT}..HEAD --oneline 或 git diff --name-only}

Review 记录：
- reviews/co-execute-{REVIEW_ID}-round1.md
- reviews/co-execute-{REVIEW_ID}-round2.md
- reviews/co-execute-{REVIEW_ID}-round3.md
```

### 重要规则

- exec_session_id 必须在所有修复轮次中复用，保证 Codex 对整个代码库有完整上下文
- Phase 1 执行失败（ask_codex.sh 非 0 退出）→ 立即停止，不进入 review 循环
- review 是你（Claude subagent）亲自做的，不调用 Codex 做 review
- 修复指令要具体：包含文件路径、行号、问题描述，不要模糊地说"修复问题"
- 每轮修复后重新读取完整 diff，不要只看增量变更

---

**完成后将以上摘要返回给调用者。**
