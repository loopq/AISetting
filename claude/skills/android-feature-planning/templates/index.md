# {{feature-title}} — 执行计划

> PRD 主文档: {{prd-url}}
> 其他 PRD / UI 附件: {{optional-links}}
> Figma: {{figma-url-or-待提供}}
> 起始日期: {{YYYY-MM-DD}}

## 新会话恢复指南

新会话冷启动按以下顺序读取，即可无损接续：

1. 读「当前进度」段 → 知道正在讨论哪个 Journey、卡在哪、下一步要做什么
2. 读「决策日志」段 → 知道已有的跨 Journey 共识，避免重复讨论
3. 读「Journey 总览」表 → 知道整体进度
4. 读对应的 `jX-*.md`（含 `[WIP]` 草稿）→ 知道该 Journey 已落地的子共识
5. 按「当前进度」的「下一步动作」继续

## 工作流约定

- **Spec 颗粒度**：必须细到类名、方法签名、字段类型、Moshi/序列化注解；验收标准必须机器可验证（"调用 X(a=1) 返回 Y"），禁止"流畅""体验良好"等模糊描述
- **Spec 状态**：`[ ]` 未开始 / `[WIP]` 讨论中 / `[REVIEW]` 待评审 / `[DONE]` 已冻结
- **执行状态**：`[ ]` 未开始 / `[DOING]` 进行中 / `[DONE]` 验收通过 + 已 commit（唯一真相源 = 「Journey 总览」表的「执行」列）
- **Done 判定**：Spec 验收项全过 + `{{build-command}}` 通过 + 单测（若涉及）0 失败 + git commit 已创建
- **Commit 规范**：message 前缀 `[J{N}]` / patch 前缀 `[J{N}-patch]`；patch 可合进 Journey commit 或独立 commit；每 J 原子可 revert
- **冻结后不允许修改**，变更走 `patches/{journey}-{date}-{topic}.md`，一个 patch 只改一件事
- **执行顺序**：J1 必须先完成；J2 与 J3~Jn 独立；J3~Jn 按编号串行
- **每个 Journey 讨论流程**：主对话深入讨论 → review → 写入 Spec 文件 → 更新本文件状态
- **持久化义务**：每次会话结束前必须更新「当前进度」和「决策日志」；讨论中产生的 JX 子共识立即落到 `jX-{name}.md`（状态置 `[WIP]`），不要等全部 OK 才落地

## 全局技术约束

- 包名根：
  - UI 层：`{{ui-package-root}}`（J2~Jn）
  - 数据层：`{{data-package-root}}`（J1，含 model / algo / store / provider 子包）
- 序列化：Moshi only（禁 Gson）
- 异步：Kotlin Coroutines（禁 RxJava 新代码）
- UI：XML（非明确要求不用 Compose）
- 模块约束：动 {{module-name}} 相关代码前必读 `{{module-claude-md-path}}`

## Journey 总览

| 编号 | 名称 | Spec | 执行 | Spec 文件 | 依赖 |
|---|---|---|---|---|---|
| J1 | 数据基础设施 + 公共资源 | `[ ]` | `[ ]` | j1-tdd-infra.md | - |
| J2 | {{journey-2-name}} | `[ ]` | `[ ]` | j2-{{slug}}.md | J1 |
| J3 | {{journey-3-name}} | `[ ]` | `[ ]` | j3-{{slug}}.md | J1, J2 |
| ... | ... | ... | ... | ... | ... |

---

## Journey 卡片

### J1 - 数据基础设施 + 公共资源

**目标**：建立整个 {{feature}} 模块的数据骨架与算法基建，所有纯逻辑通过单元测试验收。完整 Spec 见 `j1-tdd-infra.md`，此处只列范围摘要。

**范围**（详见 j1-tdd-infra.md 章节 1~9）：
- {{data-models-summary}}
- {{algorithms-summary}}
- {{stores-summary}}
- {{resource-changes-summary}}
- {{i18n-summary}}
- 测试基建依赖加入

**非范围**：
- 任何 ViewModel / Activity / Fragment / View / 弹窗（属于 J2~Jn）
- {{other-excluded-items}}

**验收**：
1. `{{test-command}}` 0 失败 0 错误
2. J1 Spec 内列出的每个算法的测试 case 清单 100% 实现
3. 测试报告（`app/build/reports/tests/`）覆盖清单中所有 case

---

### J2 - {{journey-2-name}}

**目标**：{{one-sentence-goal}}

**范围**：
- {{scope-item-1}}
- {{scope-item-2}}

**非范围**：{{out-of-scope}}

**前置**：{{prerequisite}}

---

{{其他 Journey 卡片依此格式填充}}

---

## 决策日志（跨 Journey 共识）

> 所有跨 Journey 的产品/技术决策一行一条，避免在新会话重复讨论。

| 日期 | 决策 | 上下文 |
|---|---|---|
| {{YYYY-MM-DD}} | 工作流：Phase A 拆 Journey 框架 → Phase B 逐个深度讨论 Spec → Phase C Double Check → Phase D 交接执行 | 整体方法论 |
| {{YYYY-MM-DD}} | Spec 颗粒度细到类名/方法签名/字段类型/Moshi 注解；验收必须可机器验证 | Spec 标准 |
| {{YYYY-MM-DD}} | Spec 冻结后变更走 `patches/{journey}-{date}-{topic}.md`，一个 patch 改一件事 | 变更管理 |
| {{YYYY-MM-DD}} | **DI 全局约定**：项目无 Hilt / Koin，所有 J1~Jn Activity 依赖用 `by lazy { Default...() }` 手动获取 | 跨 Journey |
| {{YYYY-MM-DD}} | **UI 风格对齐**：(1) 圆形头像统一用 `CircleImageView`；(2) 点击防抖统一用 `View.clickWithTrigger(800ms)`；(3) WindowInsets 统一用 `enableEdgeToEdge()` + `doOnApplyWindowInsets`；(4) 返回键不实现 `OnBackPressedCallback` | 跨 Journey |

## 延后项追踪

> 本段记录因范围/前置条件不足而延后的功能，避免遗忘。启动时从这里收尾。

| 编号 | 项目 | 延后原因 | 关联 Journey | 启动前置 |
|---|---|---|---|---|
| D1 | {{deferred-item}} | {{reason}} | {{journey-refs}} | {{prerequisite}} |

## 当前进度（恢复入口）

> 真相源 = 「Journey 总览」表的「执行」列。本段只写指针与动作。

- **当前执行**：{{current-journey-or-phase}}
- **下一步动作**：{{next-action-description}}
- **执行顺序**（串行）：{{execution-order}}
- **阻塞**：
  - {{blocker-1}}
  - {{blocker-2}}
- **执行阶段已完成 commit**：
  - （空，待 J1 commit 后按逆序回填：`<short-sha> [J{N}] <简述>`）

### Spec 阶段已完成（冻结，不再追加）

- [ ] 拆出 {{n}} 个 Journey 框架并写入 index.md
- [ ] J1 Spec 初稿落盘
- [ ] J1 Q 清单全解决 → `[REVIEW]`
- [ ] ...
- [ ] Double check {{n}} 个 Journey + 所有 patches

## Patches 记录

| 文件 | 影响 Journey | 日期 | 说明 |
|---|---|---|---|
| （空，Phase B / Phase C 追写） | | | |

## BundleConstant 新增常量清单（执行阶段单次落）

为避免散落到多个 Spec，本节集中列出：

```kotlin
// constant/BundleConstant.kt 新增
// 待 Phase B 深化后填充
```

传递链路：

```
J2a (生成) KEY_XXX
  ↓
J3 (透传) BUNDLE_JSON + KEY_XXX
  ↓
... 
```