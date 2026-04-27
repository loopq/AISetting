# J{N} Spec — {{title}}（数据基础设施）

**状态**：`[WIP]`
**最后更新**：{{YYYY-MM-DD}}
**依赖参考**：`./data/*.md`、`./index.md` 决策日志

---

## 1. 范围与目标

### 1.1 目标

为整个 {{feature}} 模块建立**数据骨架**与**算法基建**。J{N} 完成后，其他 Journey 的 UI 层可以直接消费本 Journey 产出的 data class、算法接口、存储接口，无需再设计底层结构。

### 1.2 范围（清单）

1. 测试基建依赖加入（项目当前{{是否已}}有 unit test 基建）
2. 核心数据模型（所有 `data class` / `enum` / `sealed class`）
3. 核心算法接口 + 实现 + 单元测试
4. 存储层接口（{{stores-summary}}）
5. 资源文件改造（{{resource-changes}}）
6. {{additional-scope}}

### 1.3 非范围

- 任何 Activity / Fragment / View / Dialog / ViewModel（J2~Jn）
- 动画实现（J2~Jn）
- {{network-or-ad-integrations-deferred-to-other-journeys}}

### 1.4 包名规划

| 包路径 | 职责 |
|---|---|
| `{{data-package-root}}.model` | 所有 data class / enum |
| `{{data-package-root}}.algo` | 算法实现（纯函数） |
| `{{data-package-root}}.store` | 本地存储（MMKV/Preferences 封装） |
| `{{data-package-root}}.provider` | 对外门面（读 assets / 提供数据） |
| `{{data-package-root}}.{{other-subpackage}}` | {{职责}} |

> UI 层（`{{ui-package-root}}.*`）在 J2~Jn 落地，J{N} 不涉及。

---

## 2. 测试基建

### 2.1 依赖加入

**位置**：
- `gradle/libs.versions.toml` 新增版本与库别名
- `app/build.gradle.kts` 的 `dependencies` 块追加 `testImplementation`

**版本清单**（已在 index.md 决策日志记录）：

```toml
[versions]
junit = "4.13.2"
truth = "1.4.4"
coroutinesTest = "1.9.0"
mockk = "1.13.13"

[libraries]
junit = { group = "junit", name = "junit", version.ref = "junit" }
truth = { group = "com.google.truth", name = "truth", version.ref = "truth" }
coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutinesTest" }
mockk = { group = "io.mockk", name = "mockk", version.ref = "mockk" }
```

`app/build.gradle.kts`：

```kotlin
dependencies {
    // ... existing ...
    testImplementation(libs.junit)
    testImplementation(libs.truth)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.mockk)
}
```

### 2.2 测试目录

首次创建：`app/src/test/java/{{data-package-path}}/`

子目录按模块对齐：`algo/`、`store/`、`provider/`。

### 2.3 测试类命名规范

- 命名：`{被测类名}Test.kt`
- 方法命名：`` `when {条件} then {结果}` `` 反引号中文/英文均可，保证可读
- 所有纯算法测试使用 JUnit 4 + Truth 断言
- 涉及协程测试使用 `runTest` + `TestDispatcher`
- 涉及 `System.currentTimeMillis()` / `Random` 的算法必须可注入 `Clock` / `Random` 以保证测试可重复

### 2.4 验收

- `{{test-command}}` 0 失败 0 错误
- 每个算法 case 清单（章节 8）100% 实现
- 测试报告产出在 `app/build/reports/tests/testNekuDebugUnitTest/`

---

## 3. 数据模型

> 本章节所有类使用 Kotlin `data class` / `enum class`。涉及 JSON 反序列化的类加 `@JsonClass(generateAdapter = true)`；字段名与 JSON key 一致时省略 `@Json`。

### 3.1 {{ModelName}} — {{用途简述}}

**用途**：{{谁在用 / 用于做什么}}

```kotlin
// {{data-package-root}}.model.{{ModelName}}
@JsonClass(generateAdapter = true)
data class {{ModelName}}(
    val {{field1}}: {{Type}},       // {{注释}}
    val {{field2}}: {{Type}},
)
```

**数据来源**：{{assets/* 路径 或 运行时生成}}

**不变式**：{{size / sum / range 断言}}

### 3.2 {{ModelName2}} — {{用途简述}}

...

---

## 4. 算法接口 + 实现

> 每个算法独立子节。凡涉及随机性，构造函数必须注入 `random: Random = Random.Default`。

### 4.1 {{AlgoName}}

**接口**：

```kotlin
// {{data-package-root}}.algo.{{AlgoName}}
interface {{AlgoName}} {
    fun {{method}}({{params}}): {{ReturnType}}
}

class Default{{AlgoName}}(
    private val random: Random = Random.Default,
) : {{AlgoName}} {
    override fun {{method}}({{params}}): {{ReturnType}} {
        // 实现骨架或完整代码
    }
}
```

**前置条件**：
- {{precondition-1}}
- {{precondition-2}}

**后置条件**：
- {{postcondition-1}}
- {{postcondition-2}}

**不变式**：
- {{invariant-1}}（如"总分在 [0, 100]"）
- {{invariant-2}}（如"胜方总分 >= 败方总分"）

### 4.2 {{AlgoName2}}

...

---

## 5. 存储接口

> 每个 Store 独立子节。MMKV 键名统一前缀，避免与老代码冲突。

### 5.1 {{StoreName}}

**接口**：

```kotlin
// {{data-package-root}}.store.{{StoreName}}
interface {{StoreName}} {
    fun get(): {{DataType}}
    fun put(value: {{DataType}})
}

class Default{{StoreName}} : {{StoreName}} {
    // MMKV 实现
}
```

**MMKV 键名清单**（统一前缀 `{{feature}}_`）：
- `{{feature}}_{{key1}}` ({{Type}})
- `{{feature}}_{{key2}}` ({{Type}})

**语义**：
- `get()` — 读取；首次调用返回 {{default-value}}
- `put()` — 原子写入（MMKV 保证）

**初始化时机**：{{onCreate / 首次调用}}

### 5.2 {{StoreName2}}

...

---

## 6. 资源改造

### 6.1 {{resource-file}} 新结构

**文件**：`{{assets-path}}/{{filename}}`

**新结构**（对比旧结构）：

```json
{{new-json-structure}}
```

**对应 Moshi 模型**：{{data-package-root}}.model.{{ConfigName}}

### 6.2 {{other-resource-change}}

...

### 6.3 老代码删除清单

| 文件:行号 | 原因 |
|---|---|
| `{{path}}:{{line}}` | {{已被新模型取代}} |

---

## 7. 多语言资源

### 7.1 数据源文件

独立大表：`./data/i18n-strings.md`（Q&A 格式：key | 英文原文 | 翻译要点）

### 7.2 Key 命名规则

前缀：`{{feature}}_`
编号：按功能模块分组（UI 文本 / 弹幕 / 按钮等）

### 7.3 locale 覆盖

`values-{locale}/strings.xml`（{{locale-list}}，共 {{N}} 个）

### 7.4 入库规则 + 特殊字符处理

- `'` → `\'` 或 `\\u0027`
- `"` → `\"`
- `&` → `&amp;`
- 文本含 HTML 标签（如 `<b>`） → 保留原文，XML 内转义外层引号

---

## 8. 测试 case 清单

> 每个算法类独立子节。表格列出所有 case，覆盖：正常路径 / 边界 / 错误 / property test（≥1000 次随机验证不变量）。

### 8.1 {{AlgoName}}Test

| # | case | 输入 | 期望 |
|---|---|---|---|
| {{AlgoName}}-R1 | 正常路径：{{scenario}} | {{input}} | {{expected}} |
| {{AlgoName}}-R2 | 边界：{{scenario}} | {{input}} | {{expected}} |
| {{AlgoName}}-R3 | 错误：{{scenario}} | {{input}} | {{error-type}} |
| {{AlgoName}}-P1 | Property：1000 次随机 → 不变量 {{inv}} 保持 | 随机 | {{inv}} 成立 |

### 8.2 {{StoreName}}Test

...

### 8.3 冒烟测试

| # | case | 步骤 | 期望 |
|---|---|---|---|
| S1 | 模块初始化 | {{steps}} | {{expected}} |

---

## 9. 验收标准

> 数值化，禁止"流畅""体验良好"等模糊描述。

- V1：`{{test-command}}` 0 失败 0 错误
- V2：每个 case 清单 100% 实现（对照章节 8）
- V3：`{{build-command}}` 通过（无编译错误）
- V4：测试报告产出 `app/build/reports/tests/testNekuDebugUnitTest/index.html`，覆盖所有 case

---

## 待澄清问题汇总（Q1~Qn）

| # | 问题 | 提议默认值 | 优先级 | 结论 | 落盘章节 |
|---|---|---|---|---|---|
| Q1 | {{question}} | {{default}} | 🔴 | ⏳ 待定 | §{{section}} |

---

## 变更记录

| 日期 | 变更 |
|---|---|
| {{YYYY-MM-DD}} | 初稿落盘（`[WIP]`） |