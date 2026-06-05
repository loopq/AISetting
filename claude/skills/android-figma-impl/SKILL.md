---
name: android-figma-impl
description: 按 android-figma-spec 产出的 spec.md + excalidraw 实施 Android 代码（colors / drawable / strings / layout / Kotlin），跑 ./gradlew assembleNekuDebug 等项目编译命令验证。触发：用户说"按 spec 实施"、"按 spec 跑实施"、"实施 {name}"，或给两个文件路径调本 skill。范围：仅 Android 实施代码，不再回看 Figma、不调 mcp__figma__*、不改 spec 内容。
---

# Spec → Android 实施

> 依赖：本 skill 共享 `android-figma-spec` skill 的 references（`ui-mapping-rules.md` / `asset-naming.md`），需配对安装。

## 何时触发

- 用户说："按 spec 实施"、"按 spec 跑实施"、"实施 {name}"
- 用户给 `<project>/docs/figma-specs/*-spec.md` 路径并要求落地代码
- 用户调用本 skill 并提供两个文件路径（spec.md + excalidraw）

## 入参（必填两个文件路径）

- `<spec.md>` — `<project>/docs/figma-specs/{name}-spec.md`，作 source of truth
- `<excalidraw>` — `<project>/docs/figma-specs/{name}.excalidraw`，验证层级用

入参缺失或文件不存在 → 立即停止，要求用户补全。

## 不在本 skill 范围内（不要跨界）

| 阶段 | 归属 | 说明 |
|---|---|---|
| spec / excalidraw 撰写 | `android-figma-spec` skill | 本 skill 把 spec 当 source of truth，不动 |
| 回看 Figma 拉数据 | `android-figma-spec` skill | **禁止**调 `mcp__figma__*` / 打开 Figma URL |
| Figma 端操作（多层合并 / 截图 / 给父 Group node_id） | 用户手工 | 实施需要时 → 列 OQ 停手等用户处理 |
| 业务逻辑 / 数据层 / 网络层 | 业务 PRD | 实施只做 UI 还原 + UI callback 占位 |

## 执行流程

### Step 0：入参校验

1. 检查两个文件存在：`test -f <spec.md>` 和 `test -f <excalidraw>`
2. 任一缺失 / 路径错 → **停止**
3. spec.md §7 Open Questions 章节如有未决项 → **停止**，要求先收口

### Step 1：读必读文档（按顺序）

1. `<spec.md>` — 5 维度 + Element List + 实施 checklist
2. `<excalidraw>` — 验证层级骨架是否与 spec 一致
3. **user-scope 通用规则**：`~/.claude/skills/android-figma-spec/references/ui-mapping-rules.md`
   - §1 字体决策树 / §2 StrokeButton 视觉签名 / §3 9-patch 高度匹配 + 描边×2 + 文字描边色
   - §4 颜色铁律 + 日夜模式 + alpha 速查
   - §6 MCP 输出 → 项目组件识别
   - **§7 资源×3 → xxhdpi 铁律**
4. **user-scope 命名通用**：`~/.claude/skills/android-figma-spec/references/asset-naming.md`
5. **项目专属 mapping**：`<project>/docs/figma-mapping/figma-android-ui-mapping.md`
   - 项目实际字体清单（具体 `@font/xxx` 文件名）
   - 项目实际 9-patch SKU
   - 项目实际 `stroke_color_xxx` token 表
   - 项目内部 widget 类全名
6. **项目命名约定**：`<project>/docs/figma-mapping/figma-asset-naming.md`
7. **项目铁律**：`<project>/.claude/CLAUDE.md`（Moshi / 禁 `!!` / 不格式化 / 不写注释 / 单 density 等）

> **两份 mapping 合起来 = 完整 mapping**。user-scope 规定换算口径，项目侧罗列项目实际清单。

### Step 2：按 spec 实施 checklist 全做

逐步执行 spec.md 末尾的实施 checklist。**遇到需要 Figma 端操作的步骤**（如「在 Figma 内合并多层组件为单图」）→ 列 OQ 停手等用户处理，不要自己跳过 / 用占位资源蒙混。

资源导出步骤：跑 `~/.claude/scripts/figma-export.sh <project>/docs/figma-specs/{name}.assets.json`。脚本已内置 pngquant + cwebp lossless 两步管线，导出即接近最优体积，**无需事后再过 compress_images.sh**。

### Step 3：编译验证

跑项目编译命令（参考 `<project>/.claude/CLAUDE.md` 的 Build Commands 章节，常见 `./gradlew assembleDebug` / `./gradlew assembleNekuDebug` 等）：

- 编译失败 → 分析日志、修代码、再编、循环到通过
- **不**跳过验证、**不**自欺欺人改完不编

### Step 4：汇报

汇报内容（精简）：
- 改动文件清单（新增 / 修改 / 删除）
- 关键决策 3 条以内（新增了什么 token、用了哪个 9-patch、富文本怎么渲染等）
- 实施期间发现的 OQ（如有）

**不 commit**，等用户 review。

## 编码约束（高频坑提醒）

### ❌ 禁止

- hex hard-code（hex 必须 `@color/xxx`）
- `textStyle="bold"`（系统加粗不可控，必须引具体字体文件）
- `!!`（用 `?` / `lateinit`）
- 回 Figma（不调 `mcp__figma__*`）
- `git commit` / `git push`（用户专属）
- 把 layer-list 自定义 drawable 实现立体按钮（项目已有 9-patch + StrokeButton）
- 1x 资源直接放 `drawable/`（必须 ×3 → `drawable-xxhdpi/`，9-patch 例外）

### ✅ 必须

- 颜色：先 grep `colors*.xml`（项目所有颜色文件），命中用 `@color/xxx`；未命中按 spec 指定 token 名新增到 `colors_v2.xml`（或项目主颜色文件）
- 字体：按 ui-mapping-rules.md §1 决策树 + 项目字体清单映射到具体 `@font/xxx`
- 描边宽度：按 ui-mapping-rules.md §3.3 ×2 换算
- 立体按钮：视觉签名命中 → StrokeButton + 9-patch（精确高度优先，56dp 用 48dp 拉伸）
- 资源导出：`figma-export.sh` 默认 scale=3 → 落 `drawable-xxhdpi/`
- drawable 命名：按 `asset-naming.md` 通用 + 项目模块名清单
- ViewPager2 多页面：用 `enum class XxxPage` 数据驱动同一 item layout
- 富文本：HTML inline `<font>` / `<b>` → 用 `HtmlCompat.fromHtml(text, FROM_HTML_MODE_LEGACY)`
- Activity 跳转：按项目 `CLAUDE.md` 的 Activity 跳转规约（如 `companion object start(...)`）

### 静默处理

- spec.md 已有的字段（color hex、size dp、字体 weight）— 直接照抄，不二次推断
- spec.md 没有但 mapping 已规则化的（字体 weight → 文件、9-patch 选取、描边×2）— 按 mapping 推导，无需 OQ
- spec.md 没有 + mapping 也没规则的 — 列 OQ

## 必读 references

- `~/.claude/skills/android-figma-spec/references/ui-mapping-rules.md` — **通用** Figma → Android 映射换算
- `~/.claude/skills/android-figma-spec/references/asset-naming.md` — **通用** drawable 命名格式
- `<project>/docs/figma-mapping/figma-android-ui-mapping.md` — **项目专属** 字体 / 9-patch / token 清单
- `<project>/docs/figma-mapping/figma-asset-naming.md` — **项目专属** 模块名 / 案例
- `<project>/.claude/CLAUDE.md` — **项目铁律** + 模块约束索引
- `~/.claude/figma-asset-export-guide.md` — figma-export.sh 全局导出脚本

## 常见反模式（避免）

- ❌ 把 spec.md 没列的视觉细节自己脑补 —— 列 OQ
- ❌ 跳过编译验证 —— 必须编过
- ❌ 把 9-patch 用 layer-list 重新画 —— 项目已有就用项目的
- ❌ 给 indicator dot / 富文本 emphasis 自己挑颜色 —— spec 已写就照抄
- ❌ 看 spec.md 没明确说「BottomSheet 还是 Activity」就猜 —— 看 spec 头的「形态」字段
- ❌ 导出资源后再跑 compress_images.sh —— 脚本已内置压缩管线，不要双压

## 与 spec 阶段的衔接

- 实施过程中发现 spec 描述与 mapping 规则矛盾 → 优先 mapping（mapping 是项目铁律）+ 列 OQ 让用户裁决
- 实施过程中发现 spec 漏标关键字段（如 size 单位 / 状态色） → 停手列 OQ，**不**自己猜
- 实施完成后若 spec 有应当回填的信息（如新增的 color token） → 主动回填 spec.md 对应章节，并在汇报里说明

## 触发样例

```
按 docs/figma-specs/add-to-home-screen-guide-spec.md 和 .excalidraw 实施 Android 代码
```

或：

```
实施 add-to-home-screen-guide
```
