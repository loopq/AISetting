---
name: android-feature-execute
description: Orchestrate full PRD execution from tdd.md through all journeys. Takes a folder path under docs/plans/, reads index.md execution queue, runs subagents sequentially, updates progress. Replaces android-journey-execute.
---

# Android Feature Execute

从功能文件夹开始，自动串联执行 `tdd.md` → `j1` → `j2` → … 直到完成。每个文件由独立 subagent 执行，进度实时写回 `index.md`。

---

## 调用方式

```
/android-feature-execute docs/plans/2026-04-19-{feature}/
```

传文件夹路径（不是文件路径）。

---

## 执行步骤

### Step 1 — 读取 index.md，解析执行队列

读取 `{folder}/index.md`。

从 `## 执行队列` 表格提取有序文件列表和各自状态。

从 `## 当前状态` 检查：
- 存在 ⏸ 状态 → **恢复模式**：从该文件继续，跳过所有 ✅ 文件
- 全为 ⬜ → **全新启动**：从 tdd.md 开始
- 全为 ✅ → 告知用户已全部完成，退出

### Step 2 — 确认前置依赖

对恢复模式：确认当前文件的所有前置文件均为 ✅。若前置未完成，停止并告知用户需要先完成哪个文件。

### Step 3 — 编排循环

对队列中每个 ⬜（或 ⏸）文件，按顺序执行：

**3a. 更新 index.md 当前状态**

```
## 当前状态

**执行中**: {filename}
**暂停原因**: —
**恢复命令**: `/android-feature-execute {folder}/`
```

同时将该文件的执行队列状态改为 `🔄 执行中`。

**3b. 启动 subagent**

用 Agent tool 启动 subagent，传入以下 prompt（替换 `{folder}` 和 `{file}`）：

```
执行 {folder}/{file} 的所有任务。

读取步骤：
1. 先读 {folder}/index.md 中的"执行队列"、"产出契约"、"已知架构决策"三个章节
2. 再读 {folder}/{file} 全文
3. 若 plan 文件有"必须读的文件"列表，只读这些文件；没有则按最小原则
4. 严格禁止读"禁止读的文件"列表中的文件

执行规则：
- [x] 任务直接跳过，不重复执行
- 每完成一个任务立即在 plan 文件中标记 [x]（实时更新）
- 验收命令必须实际运行，失败则修复，3次后仍失败则停止
- tdd.md 严格遵守 TDD 铁律：测试文件必须先于实现文件创建

遇到 ★ 人工审查 ★：
- 停止执行，输出已完成任务列表
- 在 plan 文件的当前进度处写入说明
- 返回：PAUSED: {人工审查原因}

全部任务完成后：
- 在 plan 文件末尾写入 Handoff 块（日期、产出、测试结果、下一步注意）
- 返回：DONE: {一句话产出摘要}
```

**3c. 处理 subagent 返回**

- 返回 `DONE: {摘要}` →
  - 更新 index.md 执行队列：该行状态 → `✅ 完成`，产出列填入摘要
  - 清空"当前状态"区块的"执行中"和"暂停原因"
  - 继续下一个文件

- 返回 `PAUSED: {原因}` →
  - 更新 index.md：该行状态 → `⏸ 人工审查`
  - 更新"当前状态"：
    ```
    **执行中**: {filename} — 已完成 Phase X
    **暂停原因**: ★ 人工审查 ★ — {原因}
    **恢复命令**: `/android-feature-execute {folder}/`
    ```
  - **停止整个编排**，告知用户审查内容和恢复命令

### Step 4 — 全部完成

所有文件 ✅ 后输出：

```
🎉 全链路执行完成！

{列出每个文件的 ✅ 状态}

下一步：调用 superpowers:finishing-a-development-branch 完成分支
```

---

## 错误处理

| 情况 | 处理 |
|------|------|
| 文件夹不存在 | 报错退出，提示格式：`docs/plans/YYYY-MM-DD-{feature}/` |
| index.md 不含"执行队列"区块 | 报错，提示用 `android-feature-planning` 重新生成 |
| 前置依赖文件未 ✅ | 停止，明确告知需要先完成哪个文件 |
| subagent 3次失败后停止 | 保持当前文件为 🔄 状态，告知用户具体错误 |

---

## 不得做的事

- 不得修改其他功能文件夹的文件
- 不得 git push
- 不得跳过人工审查门
- 不得修改 tdd.md 或 jN.md 里已标 [x] 的任务
