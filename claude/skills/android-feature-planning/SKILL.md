---
name: android-feature-planning
description: Given a Feishu PRD URL, generate a two-phase plan structure: TDD infrastructure plan + journey-based integration plan. Designed for Agent-autonomous execution.
---

# Android Feature Planning

将一个飞书 PRD 转化为两阶段可执行计划：
- **Plan 1（TDD）**：纯逻辑引擎层，Agent 完全自治，测试绿 = 完成
- **Plan 2（集成）**：以用户旅程为单位，上下文隔离，防漂移

---

## 调用模式

此 skill 支持两种入口，**必须先判断是哪种模式再执行后续步骤**：

### 模式 A：直接模式（无前置 brainstorming）
用户仅提供 PRD URL，没有已完成的 PRD 讨论。
→ 执行全部 Step 1 ~ 4

### 模式 B：接续模式（已完成 brainstorming）
用户在调用前已通过 `superpowers:brainstorming` 或对话完成了 PRD 讨论。
→ **跳过 Step 1**（PRD 内容已在对话上下文中）
→ **Step 3 仍然执行**，但基于已有的讨论上下文进行，不从零开始

**为什么 Step 3 不能跳过**：`brainstorming` 讨论的是"做什么、UX 边界、技术方案"。Step 3 讨论的是"哪些逻辑可以提取为纯 Kotlin 引擎、用户旅程如何按上下文预算切分"。这是两个不同的问题，brainstorming 的输出不能代替 Step 3 的 TDD 拆分分析。

**判断方法**：当前对话上下文中已有 PRD 的实质性讨论（功能点、边界、约束等），则为模式 B。

---

## 前置条件

用户在调用此 skill 前，应已完成：
1. PRD 文档中所有疑问已解决（无 TBD、无待确认逻辑）
2. 提供飞书文档 URL（`docx` 或 `wiki` 格式均可）
3. 项目 CLAUDE.md 存在（用于读取包名、测试命令等）

---

## 执行步骤

### Step 1 — 读取 PRD（模式 B 跳过，因为 PRD 内容已在对话上下文中）

使用 `mcp__feishu__fetch-doc`，参数 `doc_id` 传文档 ID（从 URL 路径最后一段提取）。

文档过大时分段读取，必须读完全部内容再分析。

### Step 2 — 读取项目配置

读取当前项目 CLAUDE.md，提取：
- 包名（如 `com.stickermobi.avatarmaker`）
- 测试命令（如 `./gradlew testNekuDebugUnitTest`）
- 编译命令（如 `./gradlew assembleNekuDebug`）
- 计划文件目录（如 `docs/plans/`）

同时检查测试基础设施是否已存在（影响 Phase 0 生成，见下文）：
- 检查 `app/build.gradle.kts` 是否含 `testImplementation` 块
- 检查 `gradle/libs.versions.toml` 是否含 `junit4` 或 `junit` 相关版本
- 结果记录为 `HAS_TEST_INFRA = true/false`

### Step 3 — PRD 分析（模式 B 跳过，使用用户提供的摘要）

按以下框架分析，输出到对话中让用户确认：

**3a. 识别纯逻辑组件** → Plan 1 候选
问自己：这个逻辑不依赖 Android 框架能独立测试吗？
- 算法类（评分算法、概率计算、状态机）
- 纯计算（奖励计算、组件匹配）
- 选择器（主题随机、场景筛选）

**3b. 识别用户旅程** → Plan 2 候选
按用户在 App 中的行为路径拆分，每条旅程 = 一个 Activity/Fragment 流程的完整行为

**3c. 识别集成点**（不需要测试，直接列出）
- Preferences 读写
- Analytics 埋点
- Remote Config
- API 调用

**3d. 输出分析摘要**，格式如下：
```
## PRD 分析结果

### 纯逻辑组件（Plan 1）
1. XxxEngine — [一句话描述逻辑]
2. XxxSelector — [一句话描述逻辑]
...

### 用户旅程（Plan 2）
1. 旅程名 — [入口 → 核心动作 → 出口]
2. ...

### 集成点（无测试）
- Preferences: [key列表]
- 埋点: [事件列表]
...
```

**等待用户确认分析结果正确后再进行 Step 4。**

---

### Step 4 — 生成计划文件

确认后，在项目 `docs/plans/` 下创建以功能命名的文件夹，并在其中生成以下文件：

#### 文件列表
```
docs/plans/YYYY-MM-DD-{feature}/
  tdd.md         ← Plan 1：TDD 引擎层
  index.md       ← Plan 2：主索引 + 编排总控
  j{N}-{name}.md ← Plan 2：每条旅程一个文件
```

日期用今天的实际日期，feature 名从 PRD 标题提取，见文知意。文件使用短名，前缀由文件夹层级承担。

---

## 文件模板

### Plan 1 模板（TDD 引擎层）

```markdown
# {feature} — TDD 引擎层

**PRD**: {prd-title} ({doc-id})
**分支**: 从 `{main-branch}` 切出新分支

---

## 执行规则

1. **TDD 铁律**：每个引擎任务，先写测试文件（全部 fail），再写实现，直到绿才标 `[x]`
2. **完成标准**：任务末尾的验收命令输出 `BUILD SUCCESSFUL`
3. **不得跳步**：依赖未完成的不能开始
4. **人工审查门**：标有 `★ 人工审查 ★` 的任务需等待用户确认

---

## Phase 0 — 测试基础设施（按需）

> **生成规则**：
> - 若 Step 2 检测到 `HAS_TEST_INFRA = true`，将 Task 0.1 和 Task 0.2 均标记为 `[x]（已存在，跳过）`，不生成具体内容
> - 若 `HAS_TEST_INFRA = false`，生成完整任务内容

### Task 0.1 — 添加测试依赖
- [ ] （若已存在则标 `[x] 已存在，跳过`）

**执行前自检**：
\`\`\`
检查 build.gradle.kts 是否含 testImplementation(libs.junit4) 或同等依赖
若已存在 → 标记跳过，不做任何修改
若不存在 → 按以下步骤执行
\`\`\`

**修改文件**: `gradle/libs.versions.toml` + `app/build.gradle.kts`

新增 versions:
\`\`\`toml
junit4 = "4.13.2"
coroutinesTest = "1.8.1"
turbine = "1.1.0"
\`\`\`

新增 libraries:
\`\`\`toml
junit4 = { group = "junit", name = "junit", version.ref = "junit4" }
kotlinx-coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutinesTest" }
turbine = { group = "app.cash.turbine", name = "turbine", version.ref = "turbine" }
\`\`\`

新增 testImplementation（build.gradle.kts）:
\`\`\`kotlin
testImplementation(libs.junit4)
testImplementation(libs.kotlinx.coroutines.test)
testImplementation(libs.turbine)
\`\`\`

**验收命令**: `{build-command}`

---

### Task 0.2 — 创建测试目录
- [ ] （若已存在则标 `[x] 已存在，跳过`）

**执行前自检**：检查 `app/src/test/java/{package}/` 是否已存在，若存在则跳过

创建目录: `app/src/test/java/{package}/ui/{feature}/engine/`

**依赖**: Task 0.1
**验收命令**: 目录存在

---

## Phase 1 — 数据模型

### Task 1.1 — 核心数据类
- [ ]

**新建文件**: `data/model/{feature}/`

> [Agent 根据 PRD 分析填写具体数据类列表和字段]

**验收命令**: `{build-command}`

---

## Phase 2 — 引擎层

> 每个任务格式：先写测试 → 确认全部 fail → 写实现 → 验收命令绿

{每个纯逻辑组件一个任务，格式见下方引擎任务模板}

---

## ★ 人工审查 ★
- [ ] 等待用户确认所有引擎层测试通过，算法逻辑符合 PRD

---

## Phase 3 — ViewModel 层

{每个 ViewModel 一个任务}

---

## 产出契约（完成后填写，供 Plan 2 使用）

> 完成 Plan 1 后，Agent 在此填写实际产出的接口签名

| 类 | 方法签名 | 说明 |
|---|---|---|
| {Engine} | {method(params): ReturnType} | {一句话} |
```

---

### 引擎任务模板（Plan 1 内复用）

```markdown
### Task 2.{N} — {EngineClassName}
- [ ]

**PRD 逻辑**:
{从 PRD 中提取的精确业务规则，逐条列出}

**TDD 步骤**:
1. 新建测试文件（先写）: `test/.../engine/{EngineClassName}Test.kt`
2. 写测试用例（此时全部 fail，编译报错是正常的）
3. 新建实现文件: `ui/{feature}/engine/{EngineClassName}.kt`
4. 实现直到测试全绿

**测试用例清单**（必须全部覆盖）:
- `{正常路径用例描述}()`
- `{边界条件用例描述}()`
- `{property test（如涉及随机）：N次随机输入验证不变量}()`

> 注意：类构造函数必须接收 `random: Random = Random.Default` 参数，使测试可传入固定种子

**依赖**: Task {前置}
**验收命令**: `{test-command} --tests "*.{EngineClassName}Test"`
```

---

### Plan 2 Index 模板（主索引）

```markdown
# {feature} — Plan 2 主索引

---

## 执行队列

| 顺序 | 文件 | 状态 | 产出 | 阻塞于 |
|------|------|------|------|--------|
| 1 | tdd.md | ⬜ 待开始 | 引擎层 + 全部测试通过 | — |
| 2 | j1-{name}.md | ⬜ 待开始 | {一句话描述产出} | tdd |
| 3 | j2-{name}.md | ⬜ 待开始 | {一句话描述产出} | j1 |

状态值：`⬜ 待开始` / `🔄 执行中` / `⏸ 人工审查` / `✅ 完成`

---

## 当前状态

**执行中**: —  
**暂停原因**: —  
**恢复命令**: `/android-feature-execute docs/plans/YYYY-MM-DD-{feature}/`

---

## Plan 1 产出契约（只读，不得修改）

{从 Plan 1 的"产出契约"章节复制}

---

## 已知架构决策（跨 session 防漂移）

> Plan 1 审查时确定的关键决策，Agent 每次启动必须读此列表

- {决策1: 例如 "ThemeSelector 通过 ViewModel 注入，不在 Activity 层直接调用"}
- {决策2}

---

## 旅程进度

| 子计划 | 状态 | 产出 | 阻塞于 |
|-------|------|------|--------|
| j1-{name} | ⬜ 待开始 | {一句话描述产出} | - |
| j2-{name} | ⬜ 待开始 | {一句话描述产出} | j1 |
| ...  | | | |

---

## 集成点清单（无测试，直接实现）

| 类型 | 内容 | 归属旅程 |
|-----|------|---------|
| Preferences Key | {KEY_NAME}: {type} | j{N} |
| 埋点事件 | {EVENT_NAME}: {params} | j{N} |
| RC 字段 | {field}: {type} | j{N} |
```

---

### 旅程子计划模板（Plan 2 每条旅程）

```markdown
# {feature} — 旅程{N}：{旅程名}

**主索引**: [index.md](index.md)

---

## 上下文声明（Agent 必须遵守）

### 必须读的文件（仅这些，不得多读）
- `{file1}` — {原因}
- `{file2}` — {原因}
- 主索引中的"产出契约"和"架构决策"章节

### 禁止读的文件（控制上下文大小）
- `{engine-file}` — 通过 ViewModel 接口访问，不需要了解内部实现
- `{other-journey-files}` — 不在本旅程范围

---

## 旅程描述

**入口**: {用户从哪里来}
**核心动作**: {用户在这个界面做什么}
**出口**: {用户去哪里，或触发什么}

---

## 改动文件

| 文件 | 操作 | 说明 |
|-----|------|------|
| {file} | 新建/修改 | {改动描述} |

---

## 任务步骤

- [ ] {步骤1}
- [ ] {步骤2}
- [ ] ...

---

## 完成标准

`{build-command}` 通过
{如需 UI 确认}: ★ 人工确认 {具体 UI 行为描述}

---

## Handoff（完成后填写）

**产出**: {描述本旅程完成后，下一旅程需要知道的状态}
**已知问题**: {如有，描述}
**下一旅程需注意**: {如有，提示}
```

---

## 关键设计原则（Agent 生成文件时必须遵守）

1. **引擎类必须注入 Random**：凡涉及随机的引擎，构造函数接收 `random: Random = Random.Default`，测试传 `Random(seed = N)`

2. **引擎层零 Android 依赖**：`ui/{feature}/engine/` 内的文件不 import 任何 `android.*`，否则无法在 `src/test/` 下跑 JUnit

3. **Property Test 覆盖随机算法**：凡 PRD 中有概率/随机的逻辑，必须有 ≥500 次随机输入的不变量测试

4. **旅程上下文预算**：每条旅程子计划 + 必读文件的 Token 总量 ≤ 15k，超出则继续拆分旅程

5. **Handoff 块必须在完成时填写**：不得留空，这是下一旅程 Agent 的唯一状态来源

6. **验收命令必须可直接执行**：不得写"参考命令"，必须是可复制粘贴运行的真实命令
