# {{feature}} Spec 一致性检查报告

**检查日期**：{{YYYY-MM-DD}}
**检查范围**：所有 `[REVIEW]` 状态的 Journey + 所有 patches
**维度数**：6（并行 subagent 产出）

---

## 问题清单

| 严重度 | # | 问题 | 位置 | 影响 | 解决 |
|---|---|---|---|---|---|
| 🔴 | 1 | {{problem}} | `j{N}-*.md:§{X}` | {{impact}} | 追 patch `{{patch-file}}` |
| 🔴 | 2 | {{problem}} | `j{N}-*.md:§{X}` | {{impact}} | 追 patch `{{patch-file}}` |
| 🟡 | 3 | {{problem}} | `j{N}-*.md:§{X}` | {{impact}} | 文档订正 / 打包入集合 patch |
| 🟢 | 4 | {{problem}} | `j{N}-*.md:§{X}` | {{impact}} | 可选 / 保留遗留 |

---

## 必须处理的项（所有 🔴）

每个 🔴 问题独立描述 + 追 patch 链接：

### 问题 1 — {{title}}

**位置**：`j{N}-*.md` §{X}
**现状**：{{描述}}
**影响**：{{如 Intent 接收方崩溃 / 字段不存在}}
**解决**：追 patch `patches/doublecheck-{{date}}-cross-journey-fixes.md` 改动 {{A/B/C}}

### 问题 2 — {{title}}

...

---

## 维度 1 — Intent 链路完整性

| key | 定义位置 | 生产者 | 消费者 | 中间透传 | 状态 |
|---|---|---|---|---|---|
| `{{KEY_NAME}}` | J{X} §3 | J{X} | J{Y} | J{Z}（透传）| ✅ / 🔴 缺失 |

**发现的问题**：
- {{问题 1 描述}}
- {{问题 2 描述}}

---

## 维度 2 — 栈结构一致性

| Journey | 启动下一步后是否 finish | 返回键落点 | 栈快照 | 状态 |
|---|---|---|---|---|
| J{N} | ✅ / ❌ | Host / J{X} | `[Host, J{N}]` | ✅ / 🔴 |

**发现的问题**：
- {{问题描述}}

---

## 维度 3 — 类名 / 方法签名 / 常量引用

对照每个 Spec 内引用的类名 / 方法签名 / 常量，确认与被引用 Journey Spec 一致：

- ✅ J{X} §2 引用 `{{ClassName}}` — 与 J{Y} §4.2 一致
- 🔴 J{X} §5 引用 `{{WrongClass}}` — J{Y} 实际类名为 `{{ActualClass}}`

---

## 维度 4 — 字段真实性（**常被忽略**）

盘点实际代码库，确认 Spec 里引用的 API 真的存在：

| Spec 引用 | 实际代码 | 状态 |
|---|---|---|
| `detail.getImageUrl()` | `TemplateDetail` 实际字段是 `cover` | 🔴 字段名错误 |
| `Repository.submitPK` | 存在 `PKRepository.submitPK()` | ✅ |

**发现的问题**：
- {{问题描述}}

---

## 维度 5 — 埋点命名统一

全部事件收集：

| 事件名 | 所在 Spec | 命名规范 `{Feature}_{Journey}_{Action}` | 状态 |
|---|---|---|---|
| `PK_Bot_Editor_Show` | J4 §10 | ✅ | ✅ |
| `PKBot_Editor_Click` | J4 §10 | ❌（驼峰混用）| 🔴 改 `PK_Bot_Editor_Click` |

---

## 维度 6 — BundleConstant 清单完整

对照 `index.md` 底部 BundleConstant 清单，每个 key：
- 类型（String / Int / Parcelable / Bundle JSON）
- Parcelable 标注（`@Parcelize` 是否存在）
- 链路图（定义 → 生产 → 消费）

**发现的问题**：
- {{问题描述}}

---

## 集合 Patch 建议

所有 🔴 问题打包到单一 patch：

**文件**：`patches/doublecheck-{{YYYY-MM-DD}}-cross-journey-fixes.md`
**结构**：每个 🔴 一节（改动 A / B / C...）

所有 🟡 问题根据用户选择：
- 打包到同一集合 patch（默认）
- 或保留遗留，在对应 Journey 的「已知遗留」表追行

所有 🟢 问题：
- 默认跳过
- 在本报告的「可选改进」段列出，供后续迭代参考

---

## 可选改进（🟢 遗留）

- {{改进建议 1}}
- {{改进建议 2}}

---

## 执行后状态切换

集合 patch 执行完毕后：

- 所有 `[REVIEW]` → `[DONE]`
- `index.md` 当前进度 = "Spec 阶段已完成，可调用 `/android-feature-execute docs/plans/{{feature}}/`"
- `index.md` 决策日志追加本次 Double Check 的跨 Journey 订正行
- `index.md` Patches 记录表追行