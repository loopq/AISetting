---
name: android-feature-planning
description: End-to-end Android feature planning — from Feishu PRD URL to execution-ready Spec. Covers Phase A (PRD → Journey framework), Phase B (per-Journey deep spec with Brainstorm Q list), Phase C (parallel Double Check + patches), Phase D (handoff to android-feature-execute). Replaces the old split between android-feature-planning and android-journey-spec. Triggers on Feishu PRD URL, "继续 J{N}" / "开始 J{N} spec" / "这是 Figma"，or "double check {feature}".
---

# Android Feature Planning

将一个飞书 PRD 从头到尾转化为可执行 Spec。四阶段流水线：

- **Phase A**：PRD → Journey 框架（`index.md` + `jN-*.md` 极简骨架）
- **Phase B**：逐 Journey 深度细化（Brainstorm Q 清单 → 决策落盘 → `[WIP]` → `[REVIEW]`）
- **Phase C**：全部 `[REVIEW]` 后并行 Double Check + 集合 patch → `[DONE]`
- **Phase D**：交接 `android-feature-execute`

---

## 触发场景

- 用户提供飞书 PRD URL（`docx` / `wiki`）→ Phase A
- 用户说「继续 J{N}」「开始 J{N} spec」「J{N} 这是 Figma」→ Phase B
- 用户对已冻结 Spec 提出新需求（追 patch）→ Phase B 内的 patch 机制
- 用户说「全部 J 完成了，double check」或所有 Journey 已 `[REVIEW]` → Phase C
- 用户描述 PRD/设计图的重大变更 → 校验对已有 Spec 的影响，必要时追 patch

## 前置条件

- 项目 `CLAUDE.md` 存在（用于读取包名、测试命令、构建命令、plans 目录）
- PRD 文档中所有疑问已解决（无 TBD、无待确认逻辑）
- UI 类 Journey 进入 Phase B 前必须提供 Figma URL **且本地 PNG 路径**（必须能 `Read`，禁止凭 URL 猜设计）

---

## 状态自动推断（Skill 启动必做）

Skill 每次启动先读 `index.md` 判断当前阶段，避免重复讨论：

1. **无 `index.md`** → Phase A（首次规划）
2. **存在 `index.md`**，检查「Journey 总览」表 Spec 列：
   - 全为 `[ ]` → Phase A 未完成或刚完成，进入 Phase B 启动第一个 Journey
   - 存在 `[WIP]` → 续接该 Journey 的 Phase B
   - 存在 `[ ]`，无 `[WIP]` → 启动下一个 `[ ]` 的 Phase B
   - 全为 `[REVIEW]` → Phase C（Double Check）
   - 全为 `[DONE]` → Phase D（交接）
3. 读取「当前进度」段「下一步动作」确认路径，询问用户是否按此继续

---

## Phase A — PRD → 框架

### Step 1. 读 PRD

使用 `mcp__feishu-mcp__fetch-doc`，`doc_id` 从 URL 路径最后一段提取。文档过大分段读取，必须读完全部内容再分析。

**模式 B（已在对话中讨论过 PRD）**：跳过此步，直接进入 Step 2。

### Step 2. 读项目 CLAUDE.md

提取：
- 包名根（如 `com.stickermobi.avatarmaker`）
- 构建命令（如 `./gradlew assembleNekuDebug`）
- 测试命令（如 `./gradlew testNekuDebugUnitTest`）
- 计划目录（如 `docs/plans/`）
- 是否已有测试基建（`HAS_TEST_INFRA = true/false`）

### Step 3. PRD 分解分析（输出到对话等用户确认）

按以下框架分析：

**3a. J1 = 数据基建**：所有纯逻辑组件（算法 / 数据模型 / 存储接口 / 资源改造 / 多语言）
**3b. J2~Jn = 用户旅程**：按用户行为路径拆分，每条旅程 = 一个 Activity/Fragment 流程的完整行为（入口 → 核心动作 → 出口）
**3c. 集成点清单**：Preferences / 埋点 / Remote Config / API 调用（无测试，直接列出）
**3d. 跨 Journey 技术约束建议**：包名根 / DI / 栈结构 / 序列化 / 异步约定

**输出格式**：
```
## PRD 分析结果

### J1 - 数据基建（TDD 轨道）
- 核心数据模型：{{列表}}
- 算法：{{列表}}
- 存储：{{列表}}

### Journey 拆分（J2~J{n}）
1. J2 — {{名称}} — {{入口 → 核心 → 出口}}
2. J3 — ...

### 集成点
- Preferences: {{key 列表}}
- 埋点: {{事件列表}}

### 跨 Journey 约束建议
- 包名根：ui 层 `xxx.ui.{feature}.*` / 数据层 `xxx.data.{feature}.*`
- {{其他约定}}
```

### Step 4. ★ 人工确认门 ★

等待用户确认 Journey 拆分正确、命名合理、依赖关系对齐后才创建文件。不得跳过此门。

### Step 5. 创建文件

在项目 `docs/plans/YYYY-MM-DD-{feature}/` 下创建：

```
docs/plans/YYYY-MM-DD-{feature}/
  index.md                  ← 按 templates/index.md 全量填充
  j1-tdd-infra.md           ← 按 templates/tdd-spec.md 极简骨架（仅 §1 + 状态 [ ]）
  j2-{slug}.md              ← 按 templates/ui-journey-spec.md 极简骨架（仅 §1 + 状态 [ ]）
  j3-{slug}.md              ← 同上
  ...
  patches/.gitkeep          ← 空目录占位
```

**极简骨架的"空"写法**：除 §1（范围/非范围/依赖）之外的章节写 `> 待 Phase B 深化（Figma 到位后）` 或 `> 待 Phase B 深化（PRD 细节 + Q 清单）`。

### Step 6. Phase A 自检

- 对照 `index.md` Journey 总览表，检查每个 jN 文件的依赖引用是否存在
- 检查命名一致性（jN 文件名 vs 总览表 vs 卡片标题）
- 检查包名根与 CLAUDE.md 一致

### Step 7. 写回 `index.md` 当前进度

```
- **当前执行**：Phase A 已完成，等待 Phase B 启动 J1
- **下一步动作**：用户说「开始 J1」或 Agent 自动进入 J1 Phase B（J1 不依赖 Figma）
```

---

## Phase B — 逐 Journey 深度细化

### Step 1. 前置检查（硬阻塞）

- **J1 TDD 类**：PRD 细节足够（数据字段齐全 / 算法规则明确 / 多语言清单完整）
- **J2~Jn UI 类**：Figma URL **必须附带本地 PNG 路径**（`Read` 能打开）；否则打断流程让用户导出

### Step 2. 读上下文（严格控量）

仅读以下文件，禁止全库扫：
- 当前 `jN-*.md` 骨架（通常只有 §1）
- `index.md` 的「决策日志」+「全局技术约束」+「Journey 总览」段
- **所有已 `[REVIEW]` / `[DONE]` 的相邻 Journey**（只读 §3 Intent 契约 + §17 栈接合 + §19 决策摘要）
- 本 Journey 的 Figma PNG（`Read` 图像）
- 本 Journey 若有参考现有实现（如「参考 `AvatarDetailActivity`」），读对应文件

**严禁读**：其他 Journey 的正文 / 其他 Feature 的 Spec / 无关的业务代码

### Step 3. 起草全量 Spec + 立即落盘

按模板填满：
- **J1** → `templates/tdd-spec.md` §1~§9
- **J2~Jn** → `templates/ui-journey-spec.md` §1~§19

状态置 `[WIP]`，**立即** Edit 落盘（不等 Q 回答）。

### Step 4. 列 Q1~Qn 一次性清单

**节奏**：一次性列出所有疑问，**禁止挤牙膏**（一个一个问 = 节奏失控）。

**每条 Q 必备**：
- 问题描述（一句话说清歧义）
- **提议默认值**（让用户能快速"同意 / 修改"）
- **落盘章节**（例：`Q3 → §6.2 CAROUSEL_SPINNING 时长`）
- **优先级**：🔴 阻塞（影响架构）/ 🟡 可调整（影响 UI 细节）/ 🟢 可选（未来迭代）

**输出格式**：
```
## 待澄清问题（一次性批量回复即可）

### 🔴 阻塞类

Q1 — {{问题}}
  提议默认值：{{default}}
  落盘章节：§{{section}}

Q2 — ...

### 🟡 可调整类
...

### 🟢 可选类
...
```

### Step 5. 用户回答 → 自动全落（5 个位置）

用户可以任意格式回答（`Q1: yes`, `Q2: 改为 X`, `Q3~Q5: 都按默认`）。Skill 自动落盘到以下 5 个位置，**一次性 Edit**，无需用户二次确认：

1. **Spec §16 Q 汇总表**：每条标「✅ 解决」+ 结论
2. **Spec 对应章节**：按 Q 的「落盘章节」字段 Edit 写入决策（例如 §6.2 改写时长数字）
3. **Spec §19 决策摘要**：追加 D{n} 条目（核心架构决策）
4. **`index.md` 决策日志**：追加跨 Journey 级决策（DI / 埋点约定 / 栈不变式补充等）
5. **`index.md` Journey 总览状态**：`[WIP]` → `[REVIEW]`；「当前进度」更新「下一步动作」

### Step 6. 即时追 patch（如影响已 REVIEW Journey）

Q 决策若影响已 `[REVIEW]` / `[DONE]` 的 Journey，**立即**在 `patches/` 生成：

- 文件名：`patches/j{N}-{YYYY-MM-DD}-{kebab-topic}.md`（N = 被影响的 Journey 编号）
- 按 `templates/patch.md` 起草
- **一个 patch 只改一件事**；改 3 件事 → 3 个 patch
- 同步在 `index.md` Patches 记录表追行
- 同步在被影响 Spec 的「变更记录」表追行（引用 patch 文件）

### Step 7. 产出

告知用户 J{N} 已切 `[REVIEW]`，提示下一个待办（J{N+1} 或等 Figma）。

---

## Phase C — 并行 Double Check + 集合 Patch

### 触发

所有 Journey `[REVIEW]`，或用户显式说「double check」。

### Step 1. 并行 6 维度 subagent

用 `Agent` 工具启动 6 个 `general-purpose` 或 `Explore` subagent，并行跑，每个只返回简明报告（不占主上下文）：

| 维度 | subagent 任务 |
|---|---|
| 1 — Intent 链路完整性 | 追踪所有 BundleConstant key：定义位置 / 生产者 / 消费者 / 中间透传；常见 bug 漏透传、大小写不一致、缺 `@Parcelize` |
| 2 — 栈结构一致性 | 每个 Journey 的 finish 时机 + 栈快照；验证「Host + 0~1 子 Activity」不变式；返回键落点 |
| 3 — 类名/方法签名/常量引用 | 跨 Spec 引用的类名是否一致；Intent key 常量引用是否存在 |
| 4 — 字段真实性 | **盘点实际代码库**（grep 现有 Repository / data class）确认 Spec 引用的字段/方法真实存在 — **最常被忽略且最致命** |
| 5 — 埋点命名统一 | 收集所有埋点事件名，检查 `{Feature}_{Journey}_{Action}` 模式一致；PRD 硬约束事件名原文比对 |
| 6 — BundleConstant 清单完整 | 对照 `index.md` 底部 BundleConstant 清单，每个 key 的类型 / Parcelable 标注 / 链路图正确 |

**subagent prompt 统一格式**：
```
检查 docs/plans/{feature}/ 下所有 jN-*.md 和 patches/*.md 的{维度名}。

产出格式：
| 严重度 🔴🟡🟢 | 问题 | 位置（file:§section）| 影响 | 建议解决 |

只汇报发现的问题，不汇报"一切正常"的部分。限制 500 字内。
```

### Step 2. 汇总报告

主对话收到 6 份报告后，生成 `docs/plans/{feature}/doublecheck-{YYYY-MM-DD}-report.md`（按 `templates/doublecheck-report.md`）。

### Step 3. 集合 Patch 策略

- **🔴 问题** → 打包单一 `patches/doublecheck-{YYYY-MM-DD}-cross-journey-fixes.md`（按 patch 模板，每个 🔴 一节）
- **🟡 问题** → 询问用户「打包修复 or 保留遗留」
- **🟢 问题** → 默认跳过，列在 report 末尾备忘

### Step 4. 追 patch 后订正

- 受影响 Spec 的「变更记录」表追行（引用 patch 文件）
- `index.md` Patches 记录表追行
- `index.md` 决策日志追加本次 Double Check 的跨 Journey 订正

### Step 5. 批量 `[REVIEW]` → `[DONE]`

所有 🔴 修完后，批量切状态：
- 所有 Journey `[REVIEW]` → `[DONE]`
- `index.md` 当前进度 = "Spec 阶段已完成，可调用 `/android-feature-execute docs/plans/{feature}/`"

---

## Phase D — 交接

输出一行提示 + 恢复命令，退出：

```
🎉 Spec 阶段已全部完成！

下一步：
/android-feature-execute docs/plans/{feature}/
```

**不做执行**。执行由下游 `android-feature-execute` 负责。

---

## 全局约定（所有 Spec 默认继承，不必在每个 Spec 里重复写）

只在生成的 `index.md`「全局技术约束」段定义一次。Skill 在 Phase A 创建 index.md 时自动写入以下默认值（可根据项目 CLAUDE.md 覆盖）：

| 维度 | 约定 | 理由 |
|---|---|---|
| DI | `by lazy { Default...() }`，无 Hilt/Koin | Avatar 项目现状；`object` 单例可选 |
| 圆形头像 | `de.hdodenhof.circleimageview.CircleImageView` | 项目现有依赖 |
| 点击防抖 | `View.clickWithTrigger(800L)`（项目扩展）| 参考 `ViewExt.kt:180` |
| WindowInsets | `enableEdgeToEdge()` + `doOnApplyWindowInsets` + `bindNavigationAutoStyle` | 对齐现有 Activity |
| 返回键 | **不实现** `OnBackPressedCallback` | 接受动画被系统返回中断，对齐 `AvatarDetailActivity` |
| 序列化 | Moshi only（禁 Gson 新代码）| 项目全局约束 |
| 异步 | Kotlin Coroutines（禁 RxJava 新代码）| 项目全局约束 |
| UI | XML（非明确要求不用 Compose）| 项目全局约束 |
| 包路径 | UI 层 `ui.{feature}.*`；数据层 `data.{feature}.*` | 分层清晰 |

**占位优先**：视觉物料缺失不阻塞 Spec 冻结；执行阶段统一用纯色 `ShapeDrawable` / Material icon 顶上，上线前批量替换。Spec 的 §13 物料清单必须逐条标注「最终素材 / 占位策略」。

**栈结构不变式**（单 Host + finish chain）：整个 feature 流程中，栈始终保持 `HostActivity + 0~1 子 Activity`。每个 Journey 的 Activity **启动下一步后立即 `finish()` 自己**。Host 一直在栈底存活，返回键直达 Host。

**埋点命名约定**：统一格式 `{Feature}_{Journey}_{Action}`（例：`PK_Bot_Result_Show`）。禁止驼峰混用（`PKBot_Editor_*` ❌ → `PK_Bot_Editor_*` ✅）。PRD 硬约束命名保留原文（例：`PK_Rank_PKagain_Click`）。

---

## 关键设计原则

1. **禁止挤牙膏 Brainstorm**：一次列全所有 Q，让用户一次回答。问完一个再问下一个 = 节奏失控。
2. **决策立即落盘**：用户回答 `Q1: yes, Q2: no, ...` → 立即 Edit 写入 Spec，不等"全部回答完再动手"。
3. **Figma 必须本地 PNG**：只给 URL 不给 PNG → 打断流程让用户导出。禁止凭 URL 猜设计。
4. **验收必须机器可验证**：`V3: intent.getParcelableExtra<X>(KEY) != null` ✅；`V3: 用户体验流畅` ❌
5. **占位物料用 Material icon 顶**：`bg_pk_bot_heart.webp` 缺 → `Material favorite + tint pink`；上线前批量替换。不要因为缺图阻塞 Spec。
6. **Spec 冻结后变更走 patch**：禁止"顺手改改"冻结 Spec 的正文。一个 patch 一件事。
7. **Property test 必须覆盖随机算法**：凡涉及 `Random` 的引擎，测试至少 1000 次随机输入验证不变量（总分在范围、胜负一致等）。
8. **栈结构不变式神圣不可动摇**：任何 Journey 启动下一步后必须 finish；新 Journey 加入时必须先画栈图确认不违反。
9. **Cross-Journey 约定集中在 index.md**：DI / UI 风格 / 埋点规则写在 `index.md` 全局约束段，单个 Journey Spec 只引用，不重复。
10. **Double Check 不要省**：所有 Journey REVIEW 后强制 double check。用 subagent 并行跑，不占主上下文。每个 🔴 问题立即追 patch 修。

---

## 反模式（**禁止**）

- ❌ 一个一个问用户 Q（挤牙膏）
- ❌ Spec 冻结后直接改正文（破坏 patch 机制）
- ❌ 验收标准写"流畅""体验良好"等模糊描述
- ❌ 不盘点现有代码就引用 API（如 `detail.getImageUrl()` 这类字段错误）
- ❌ Cross-Journey 约定各 Spec 重复抄一遍（源真实性应在 index.md）
- ❌ 因为缺图中断流程（应该用占位往下走）
- ❌ 改动没 Double Check 就进入执行阶段
- ❌ Phase A 就把 UI Journey 填到可执行级别（Figma 未到位时的详细设计 = 凭空虚构）
- ❌ 字段未经 grep 验证就写进 Spec（维度 4 字段真实性最致命）

---

## 模板索引

所有模板在 `templates/` 子目录。Skill 生成文件时按需 `Read` 对应模板，替换占位符后 `Write` 到项目目录：

| 模板 | 用途 | 生成位置 |
|---|---|---|
| `templates/index.md` | 主索引（恢复指南 / 总览 / 决策日志 / Patches 记录 / BundleConstant 清单）| `docs/plans/{feature}/index.md` |
| `templates/tdd-spec.md` | J1 数据基建 Spec（§1~§9）| `docs/plans/{feature}/j1-tdd-infra.md` |
| `templates/ui-journey-spec.md` | UI Journey Spec（§1~§19）| `docs/plans/{feature}/j{N}-{slug}.md` |
| `templates/patch.md` | Patch 文件 | `docs/plans/{feature}/patches/j{N}-{date}-{topic}.md` |
| `templates/doublecheck-report.md` | Phase C 报告 | `docs/plans/{feature}/doublecheck-{date}-report.md` |

## 参考实例

`references/pk-revamp-structure.md` — 指向 `docs/plans/2026-04-20-pk-revamp/` 真实产出，列每个文件的角色对照和各阶段学习要点。Skill 起草新 Spec 时建议先 Read 此指针文件，再按需 Read PK revamp 对应文件作为写法参考。

---

## 下游 Skill

Phase D 完成后交接给：

```
/android-feature-execute docs/plans/{feature}/
```

`android-feature-execute` 依赖 `index.md` 的「Journey 总览」表和「当前进度」段自动编排执行，无需本 Skill 再介入。