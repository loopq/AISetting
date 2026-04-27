# J{N} Patch · {{YYYY-MM-DD}} · {{一句话主题}}

> 状态：`[WIP]` → `[DONE]`（执行完切 `[DONE]`）
> 影响 Journey：J{N}（主）+ 消费方 J{X} / J{Y}
> 触发原因：{{为什么需要这个 patch — 事实 + 问题 + 解决决策}}
> 决策依据：{{brainstorm 会话 Q{X} 选 A / Double check 维度 {N} 发现 / 产品补需求}}

---

## 背景事实（可选，复杂 patch 必需）

盘点现有代码 / Spec 冲突点，给出精确文件路径 + 行号：

- `{{path}}:{{line}}` — {{现状描述}}
- `{{path}}:{{line}}` — {{冲突点}}

---

## 改动 A — {{具体一项}}

**文件**：`{{data-or-ui-package-root}}.{{subpackage}}.{{ClassName}}`

```kotlin
// 原
{{old-code}}

// 新
{{new-code}}
```

**迁移影响**：{{对老代码 / 其他 Spec 的影响}}

**Moshi / Parcelize 注解**：{{如涉及序列化变更，说明}}

---

## 改动 B — {{具体一项}}

...

---

## 改动 C — {{具体一项}}

...

---

## 文档同步

列出需要同步更新的 Spec 文件 + 章节（patch 执行时一并改）：

| 文件 | 章节 | 变更 |
|---|---|---|
| `j{N}-*.md` | §3.2 / §4.2 | 字段名同步 |
| `j{X}-*.md` | §2 前置依赖 | 引用更新 |
| `index.md` | 决策日志 | 追加本 patch 行 |
| `index.md` | Patches 记录 | 追行 |

---

## 验收

> V1~Vn，机器可验证。

- V1：`{{build-command}}` 通过
- V2：`{{test-command}} --tests "*.{{TestClass}}"` 0 失败
- V3：`{{具体机器可验证的断言}}`

---

## 非范围

显式排除，避免 patch 范围膨胀：

- {{out-of-scope-item-1}}
- {{out-of-scope-item-2}}

---

## 变更记录

| 日期 | 变更 |
|---|---|
| {{YYYY-MM-DD}} | Patch 初稿（`[WIP]`） |
| {{YYYY-MM-DD}} | 执行完成（`[DONE]`）|