# J{N} Spec — {{title}}（{{MainClassName}}）

**状态**：`[WIP]`
**最后更新**：{{YYYY-MM-DD}}
**依赖**：
- J1 完成（{{interfaces-from-j1}}）
- {{patch-dependency-if-any}}
- {{other-journey-dependency}}

**设计稿**：
- Figma: {{figma-url}}
- 本地 PNG: {{local-png-path}}

**参考现有实现**（可选）：`{{path}}:{{line-number}}`

---

## 1. 范围与目标

### 1.1 目标

{{1~2 句话概括本 Journey 的职责，明确"用户从哪里来 / 在这里做什么 / 去哪里"}}

### 1.2 范围

- {{scope-item-1}}
- {{scope-item-2}}
- {{scope-item-3}}

### 1.3 非范围

- **{{excluded-item-1}}**（在 J{X}）
- **{{excluded-item-2}}**（延后项 D{X}）

### 1.4 实现态度

**占位优先**：视觉物料（{{assets-list}}）允许用纯色 + Material icon 占位，上线前替换。算法与状态逻辑必须按 Spec 实现，不占位。

---

## 2. 前置依赖（一眼清单）

| 来源 | 使用内容 |
|---|---|
| J1 `{{ClassName}}` | {{用途}} |
| J1 patch | {{字段/方法}} |
| J{X} — Intent key | `BundleConstant.{{KEY_NAME}}` |
| 现有 `{{ExistingClass}}` | {{method or field}} |

---

## 3. Intent 契约

### 3.1 入场（J{X} → J{N}）

```kotlin
Intent(context, {{MainClassName}}::class.java).apply {
    putExtra(BundleConstant.{{KEY_NAME}}, {{value}})  // {{Type}} : Parcelable
}
```

**J{N} 接收（必须）**：
```kotlin
private val {{field}}: {{Type}} by lazy {
    intent.getParcelableExtra<{{Type}}>(BundleConstant.{{KEY_NAME}})
        ?: error("{{MainClassName}} requires {{KEY_NAME}} extra")
}
```

Intent 缺失 → 直接崩溃。此 Activity 仅能从 J{X} 流程进入。

### 3.2 出场（J{N} → J{X+1}）

```kotlin
private fun enterNext() {
    val intent = Intent(this, {{NextActivity}}::class.java).apply {
        putExtra(BundleConstant.{{KEY_NAME_2}}, {{value}})
        // 透传必要字段
    }
    startActivity(intent)
    finish()  // 启动下一步后立即 finish（栈不变式）
}
```

### 3.3 栈约定

```
进入本 Journey 前:     [PKActivity]
本 Journey 运行中:     [PKActivity, {{MainClassName}}]
启动下一步后:         [PKActivity, {{NextActivity}}]  // 本 Activity finish
```

**不变式**：Host（{{HostActivity}}）一直在栈底；每个 Journey Activity 启动下一步后立即 `finish()` 自己；返回键落点始终是 Host。

---

## 4. Activity 类骨架 + 状态机

### 4.1 文件位置

- Activity：`{{ui-package-root}}.{{subpackage}}.{{MainClassName}}`
- Layout：`res/layout/activity_{{snake}}.xml`

### 4.2 类骨架

```kotlin
class {{MainClassName}} : AppCompatActivity() {
    private val binding: Activity{{CamelName}}Binding by viewBinding()

    // DI: by lazy（无 Hilt / Koin）
    private val {{dep1}}: {{Dep1Type}} by lazy { Default{{Dep1Type}}() }
    private val {{dep2}}: {{Dep2Type}} by lazy { {{Dep2Type}}Singleton }

    // Intent 参数
    private val {{field}}: {{Type}} by lazy {
        intent.getParcelableExtra<{{Type}}>(BundleConstant.{{KEY_NAME}})
            ?: error("{{MainClassName}} requires {{KEY_NAME}}")
    }

    // 状态机
    private var state: State = State.{{INIT_STATE}}

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContentView(binding.root)
        binding.root.doOnApplyWindowInsets { _, insets, _ -> /* ... */ }
        bindNavigationAutoStyle()

        // 初始化 + 进入初始状态
        transitionTo(State.{{INIT_STATE}})
    }

    override fun onDestroy() {
        super.onDestroy()
        // 清理动画 / 协程
    }

    private fun transitionTo(next: State) { /* ... */ }

    companion object {
        fun start(context: Context, {{params}}) {
            val intent = Intent(context, {{MainClassName}}::class.java).apply {
                putExtra(BundleConstant.{{KEY_NAME}}, {{value}})
            }
            context.startActivity(intent)
        }
    }
}
```

### 4.3 状态 enum

```kotlin
private enum class State {
    {{STATE_1}},     // {{描述}}
    {{STATE_2}},     // {{描述}}
    {{STATE_3}},     // {{描述}}
    {{STATE_FINISHED}},
}
```

### 4.4 状态转移表

| from | trigger | to | 动作 |
|---|---|---|---|
| {{STATE_1}} | onCreate 完成 | {{STATE_2}} | {{动作}} |
| {{STATE_2}} | {{事件}} | {{STATE_3}} | {{动作}} |
| {{STATE_3}} | 用户点击 {{按钮}} | {{STATE_FINISHED}} | startActivity + finish |

### 4.5 返回键行为

- **系统返回键**：{{不拦截 / 拦截并做 X}}
- **返回按钮（UI）**：{{点击 → 执行什么}}

对齐全局约定：不实现 `OnBackPressedCallback`，系统返回键直接走默认行为（finish）。

---

## 5. Layout 结构

### 5.1 主 layout 骨架

**文件**：`res/layout/activity_{{snake}}.xml`

```
ConstraintLayout (@+id/root)
├── {{TopView}} (@+id/{{top_id}})       // {{用途}}
├── {{CenterView}} (@+id/{{center_id}}) // {{用途}}
└── {{BottomView}} (@+id/{{bottom_id}}) // {{用途}}
```

id 清单：
- `@+id/root` — 根布局
- `@+id/{{id_1}}` — {{用途}}
- `@+id/{{id_2}}` — {{用途}}

### 5.2 include 子 layout（如需）

- `include_{{name}}.xml` — {{用途}}
  - ViewBinding 字段路径：`binding.{{field}}.{{subfield}}`

### 5.3 WindowInsets 处理

引用全局约定（index.md §全局技术约束）：`enableEdgeToEdge()` + `doOnApplyWindowInsets` + `bindNavigationAutoStyle`

### 5.4 dimen / color 资源清单

**新增 dimen**：
- `@dimen/{{name}}` = {{value}}dp — {{用途}}

**新增 color**：
- `@color/{{name}}` = #{{hex}} — {{用途}}

---

## 6. 各阶段详细设计（按状态机子阶段）

### 6.1 {{STATE_1}} — {{状态名}}

**触发条件**：{{when}}
**动作**：{{what}}
**时长**：{{N}}ms（{{Interpolator}}）
**UI 变化**：
- {{view}} → {{visibility / animation / text change}}

### 6.2 {{STATE_2}} — {{状态名}}

...

---

## 7. 自定义组件设计

### 7.1 {{ComponentName}}

**文件位置**：`{{ui-package-root}}.{{subpackage}}.view.{{ComponentName}}`
**继承**：{{BaseView}}
**构造签名**：

```kotlin
class {{ComponentName}}(
    context: Context,
    attrs: AttributeSet? = null,
) : {{BaseView}}(context, attrs) {
    // ...
}
```

**公开 API**：
- `fun {{method1}}({{params}}): {{ReturnType}}` — {{用途}}
- `fun {{method2}}(): Unit` — {{用途}}

**实现要点**：
- {{point-1}}
- {{point-2}}

### 7.2 {{ComponentName2}}

...

---

## 8. 数据流 + 算法调用（如需）

### 8.1 onCreate 阶段一次性预计算

```kotlin
private val outcome: {{OutcomeType}} by lazy { precomputeOutcome() }

private fun precomputeOutcome(): {{OutcomeType}} {
    val step1 = {{AlgoFromJ1}}.{{method}}({{params}})
    val step2 = {{AlgoFromJ1_2}}.{{method}}(step1)
    return {{Outcome}}(step1, step2)
}
```

**算法调用链**：
```
{{InputData}}
  → {{Algo1}}.{{method}}()
  → {{Algo2}}.{{method}}()
  → {{OutcomeType}}
```

---

## 9. 字符串资源

### 9.1 复用现有 key

- `@string/{{existing_key}}` — {{原文}}

### 9.2 新增 key

| key | 英文原文 | 用途 |
|---|---|---|
| `{{feature}}_{{key1}}` | {{text}} | {{用途}} |
| `{{feature}}_{{key2}}` | {{text}} | {{用途}} |

**10 locale 翻译入库**：见 `./data/i18n-strings.md`

### 9.3 非 i18n 硬编码

- {{硬编码文本}} — 理由：{{为什么不做 i18n}}

---

## 10. 埋点

| 事件名 | 触发时机 | 参数 |
|---|---|---|
| `{{Feature}}_{{Journey}}_{{Action}}_Show` | 页面展示 | `portal` = {{value}} |
| `{{Feature}}_{{Journey}}_{{Action}}_Click` | 按钮点击 | - |

命名约定：`{Feature}_{Journey}_{Action}`（见 index.md 决策日志 / 全局约定）

---

## 11. 资源清单（新增文件）

| 文件路径 | 说明 |
|---|---|
| `res/layout/activity_{{snake}}.xml` | 主 layout |
| `res/drawable/{{drawable_name}}.xml` | {{用途}} |
| `res/anim/{{anim_name}}.xml` | {{用途}} |

---

## 12. AndroidManifest + DI

### 12.1 Activity 注册

```xml
<activity
    android:name="{{ui-package-root}}.{{subpackage}}.{{MainClassName}}"
    android:theme="@style/{{theme}}"
    android:screenOrientation="portrait"
    android:exported="false" />
```

### 12.2 DI 方式

`by lazy { Default{{Dep}}() }` 手动获取（对齐全局约定，无 Hilt/Koin）

---

## 13. 物料清单（后续补齐，不阻塞）

| 文件 | 用途 | 占位策略 |
|---|---|---|
| `{{asset-file}}.webp` | {{用途}} | {{Material icon + tint / 纯色 ShapeDrawable}} |

---

## 14. 验收标准

> V1~Vn 列表，每条必须**机器可验证**。禁止"流畅""体验良好"等模糊描述。

- V1：`{{build-command}}` 通过
- V2：启动 Activity 后 `state` 变量 == `State.{{INIT_STATE}}`
- V3：Intent 含 `{{KEY_NAME}}` Parcelable 字段非 null
- V4：点击 {{按钮}} 后，`startActivity({{NextActivity}})` 被调用，且当前 Activity `isFinishing == true`
- V5：★ 人工确认 ★ {{具体 UI 行为描述，如"轮播动画在 4000ms 内停止并显示 Start 按钮"}}

---

## 15. 开发步骤

| # | 动作 | 验证 |
|---|---|---|
| 1 | 新建 Activity + layout 骨架 | 编译通过 |
| 2 | 实现状态机转移 | 手工点按测试 |
| 3 | 实现 {{Component}} | 组件单测（如涉及）|
| 4 | 接入 J1 算法 | 端到端 demo 通过 |
| 5 | 埋点接入 | 日志打出 |

---

## 16. 待澄清问题（Q1~Qn）

| # | 问题 | 提议默认值 | 优先级 | 结论 | 落盘章节 |
|---|---|---|---|---|---|
| Q1 | {{question}} | {{default}} | 🔴 | ⏳ 待定 | §{{section}} |
| Q2 | {{question}} | {{default}} | 🟡 | ⏳ 待定 | §{{section}} |

---

## 17. 栈接合

```
进入前:    [Host, ..., J{X}]
J{N} 启动: [Host, ..., J{N}]   // J{X} finish
J{N} 出场: [Host, ..., J{X+1}] // J{N} finish
返回键:    → Host（直达栈底）
```

**不变式**：整个 feature 流程中，栈始终保持 `Host + 0~1 子 Activity`。

---

## 18. 已知遗留 / 待协调

| # | 事项 | 状态 |
|---|---|---|
| L1 | {{事项}} | ⏳ 待定 / ✅ 已追 patch / 🟢 不阻塞 |

---

## 19. 决策摘要

> 核心架构决策锚点，便于后续 review。

| # | 决策 | 依据 |
|---|---|---|
| D1 | {{decision}} | Q{X} 结论 / Figma / PRD |
| D2 | {{decision}} | {{依据}} |

---

## 变更记录

| 日期 | 变更 |
|---|---|
| {{YYYY-MM-DD}} | 初稿落盘（`[WIP]`） |
| {{YYYY-MM-DD}} | Q1~Qn 全解决 → `[REVIEW]` |
| {{YYYY-MM-DD}} | Double check 订正（引用 `patches/doublecheck-*.md`） |