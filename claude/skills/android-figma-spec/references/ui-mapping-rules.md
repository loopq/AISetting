# Figma → Android 通用映射规则

> 用途：跨项目通用的 Figma → Android 视觉换算规则，适用于任意 Android 项目（无关具体字体清单 / 9-patch SKU / token 表）。
> 项目专属内容（项目实际字体清单、9-patch 列表、颜色 token 名）见对应项目的 `<project>/docs/figma-mapping/figma-android-ui-mapping.md`。**两份合起来 = 完整 mapping**。
>
> 本文件由 `android-figma-spec` 与 `android-figma-impl` 两 skill 共享。

---

## 1. 字体映射通用规则

### 1.1 Figma weight → 字体文件决策树

```
Figma weight 标注？
├── 400 / Regular     → poppinslatin_regular（或项目 Regular 字重文件）
├── 500 / Medium      → poppinslatin_medium
├── 600 / SemiBold    → poppinslatin_semibold
├── 700 / Bold        → poppinslatin_bold
├── 800 / ExtraBold   → poppinslatin_extrabold
├── 200 / 300（更细） → light / extralight
└── 900 / Black / 装饰性超粗显示字 → 项目专用 hero 字体（rounded_next_black 等）
```

具体字体文件名以**项目侧 mapping** §1 为准。本文件只规定决策口径。

### 1.2 字体铁律

- ❌ **禁止 `android:textStyle="bold"`** —— 系统加粗算法不可控
- ❌ **禁止引用 family 文件**（如 `@font/poppinslatin`）—— 项目惯例直接引具体 weight 文件
- ✅ Figma 标注的 weight → 对应字体文件

### 1.3 中文 fallback

中文不用 Poppins（拉丁字体，中文会 fallback 到系统）。**不指定 fontFamily**，让系统用默认中文字体。

---

## 2. 立体按钮（StrokeButton）识别

### 2.1 视觉签名 → 立即识别为 StrokeButton

Figma 上看到**任何一个特征**就要怀疑是 StrokeButton；满足 2 个以上 = 确认：

- ✅ 色块按钮 + **明显深色描边**（stroke ≥ 4dp）
- ✅ 文字有 **白色描边 / 双层文字效果**（贴纸感）
- ✅ 按钮底部有 **inset shadow** 或 **更深色的薄条**（"立体凸起底"效果）
- ✅ 圆角较大（≥ 12dp）+ 鲜艳饱和色（绿 / 黄 / 紫 / 红）
- ✅ 风格"游戏化 / casual"，不像 Material Design 默认按钮

### 2.2 反例（用 MaterialButton / 普通 Button）

- 扁平色块、无描边、无立体凸起
- 字体不带描边
- 中性色（灰 / 白 / 黑）+ 小圆角

### 2.3 StrokeButton 实施模板

XML 引用：

```xml
<com.stickermobi.avatarmaker.ui.view.widget.StrokeButton
    android:layout_width="270dp"
    android:layout_height="48dp"
    app:sb_background="@drawable/bg_primary_button_green_48"
    app:sb_text="Add to Home Screen"
    app:sb_text_color="@color/white"
    app:sb_text_size="15sp"
    app:sb_stroke_color="@color/text_stroke_color"
    app:sb_stroke_width="2dp"
    app:sb_font_family="@font/poppinslatin_bold" />
```

> 上例的具体 widget 类全名（`com.stickermobi.avatarmaker.ui.view.widget.StrokeButton`）来自 Avatar 项目；其他项目按自己的 widget 全名替换。**视觉签名识别 + 属性结构是通用的**。

**关键属性**（StrokeButton 通用 styleable）：

| 属性                        | 含义                            | 备注                          |
| --------------------------- | ------------------------------- | ----------------------------- |
| `sb_background`             | 9-patch 背景（立体感来源）      | 从项目 9-patch 清单选          |
| `sb_text` / `sb_text_color` | 文字 / 颜色                     |                               |
| `sb_text_size`              | 字号（默认 16sp）               |                               |
| `sb_stroke_color`           | **文字描边颜色**（不是按钮描边）| 立体按钮文字常带白描          |
| `sb_stroke_width`           | 文字描边宽度                    | 通常 1.5–3dp（按 §3.3 ×2 换算） |
| `sb_font_family`            | 字体                            | 按 §1 weight 决策树            |

---

## 3. 9-patch 与描边规则

### 3.1 9-patch 命名格式（通用约定）

```
bg_{业务前缀}_button_{颜色}_{宽}_{高}.9.png
   |             |        |       |
   primary       green    可省    32 | 48 | 56 | 60
   achievement   yellow
   story         purple
   rate          red
                 gray
                 light_yellow
                 (业务专用色 ...)
```

具体 SKU 清单见**项目侧 mapping** §3.2。

### 3.2 高度匹配决策树（**精确匹配优先**）

```
Figma 按钮高度
├── 32dp 同色族存在 _32  → 用 _32 精确匹配（不要降级到 _48）
├── 34dp（achievement）  → 用 _34
├── 48dp 同色族存在 _48  → 用 _48 精确匹配
├── 60dp 同色族存在 _60  → 用 _60 精确匹配
├── 同色族无精确匹配，需拉伸：
│   ├── Figma > 项目可用最大高度 → 用最接近的较小值**拉伸**（9-patch 设计就是为了拉伸）
│   └── Figma < 项目可用最小高度 → 不要缩！9-patch 缩会压坏圆角，列入 OQ
└── 同色族完全不存在
    → 列入 Open Questions
```

**铁律**：9-patch 只能往大拉，**不能缩**。缩会压坏圆角和描边。

### 3.3 描边宽度 ×2 换算（Figma → Android dp）

**铁律**：项目设计稿在 Figma 上标注的描边宽度（无论按钮 border 还是文字 stroke）**统一按 ×2 换算**。

| Figma 标注 | Android 实施 |
|---|---|
| `0.5px` | `1dp` |
| `1px`   | `2dp` |
| `1.5px` | `3dp` |
| `2px`   | `4dp` |
| `3px`   | `6dp` |

**为什么**：项目设计稿出自 0.5x（或类 0.5x）画布约定，Figma 上描边数值是「半宽」标注；按 ×2 才是 Android 实际看上去等粗的视觉效果。

**适用范围**：
- ✅ `StrokeButton` 文字描边宽度（`sb_stroke_width`）
- ✅ `StrokeTextView` 描边宽度
- ✅ 自定义 shape drawable 的 `<stroke android:width>`
- ❌ 9-patch 烘焙的视觉描边（资源里已经是最终视觉，无需换算）

### 3.4 文字描边色（sb_stroke_color）选取口径

立体按钮文字几乎都带白描边或深色描边。Figma 上肉眼对比文字边缘：

- 文字外圈一圈白 → `#FFFFFF`
- 文字外圈一圈深色（与按钮主色同族深色）→ 用项目侧 `stroke_color_xxx` token（具体表见**项目侧 mapping** §4.5）
- 看不清 / Figma 没标 → 写进 Open Questions

---

## 4. 颜色映射通用规则

### 4.1 铁律

- ❌ **禁止 hard-code hex** —— 所有颜色必须以 `@color/xxx` 形式引用
- ✅ 优先匹配项目已有 token（项目颜色文件清单见**项目侧 mapping** §4.2）
- ✅ 找不到精确匹配 → **直接新增 color**，不要 hard-code 凑合
- ✅ alpha 通过 8 位 hex 表达（见 §4.3）

### 4.2 日夜模式注意

新增 color token 时必须考虑：

- **是固定色**（按钮主色、品牌色、装饰色）→ 只加到 `values/`
- **是会随主题变的色**（背景、文字、分割线、卡片底）→ 同时加 `values/` 与 `values-night/`
- **不确定** → 列入 Open Questions

判断口径：Figma 是否有夜间模式稿？没有 → 默认按"固定色"处理，但写进 OQ 提醒确认。

### 4.3 alpha 速查

| 百分比 | 8 位 hex 前缀 |
|---|---|
| 100% | `#FF` |
| 87%  | `#DE` |
| 60%  | `#99` |
| 54%  | `#8A` |
| 40%  | `#66` |
| 38%  | `#61` |
| 30%  | `#4D` |
| 20%  | `#33` |
| 12%  | `#1F` |
| 8%   | `#14` |

---

## 5. StrokeTextView

不只 StrokeButton 用，独立的 StrokeTextView 也常出现。视觉签名：

- 文字外圈 1–3dp 描边（白 / 深色）
- 文字本身是高饱和色
- 多见于装饰文字、徽章、标签

实施：用项目的 `StrokeTextView` widget + 直接设 `sb_stroke_color` / `sb_stroke_width`。

---

## 6. MCP 输出 → 项目组件识别

**用途**：Figma MCP `get_design_context` 返回 React + Tailwind arbitrary value 模式（`bg-[#a7cc40]` 而非 `bg-blue-500`）的代码片段，**数值 1:1 保留**。本节给一张签名速查表，看到 MCP 输出能秒识别对应的项目组件 / 资源。

**单向映射**：MCP CSS 签名 → 项目组件，反向不成立。

| MCP CSS 签名 | 对应项目组件 / 资源 | 说明 |
|---|---|---|
| `border-N + bg-[鲜艳色] + shadow-[inset_0px_-Npx_0px_0px_深色]` + 双层 div 嵌套 | StrokeButton + 9-patch（按 §2.1 视觉签名识别） | MCP 把 9-patch 反向工程成 CSS 多层 div，要识别穿透 |
| `font-['Poppins_Latin:Bold']` | `@font/poppinslatin_bold`（按 §1 决策树类推） |  |
| `font-['Poppins_Latin:ExtraBold']` | `@font/poppinslatin_extrabold` |  |
| `font-['Poppins:ExtraBold']` 等去掉 `_Latin` | 同上（family 别名） | MCP 偶尔输出无 `_Latin` 后缀 |
| `rounded-tl-[Npx] rounded-tr-[Npx]` | inline shape drawable + topLeft/topRight 单独设置 | 不要用 MaterialCardView 全角 |
| `rounded-[Npx]` | shape drawable `<corners android:radius="Ndp">` |  |
| `text-[#color]` / `bg-[#color]` | grep 项目 colors*.xml → `@color/xxx`，未命中按 §4.2 新增 | 严禁 hardcode hex |
| `border-N` / `stroke-[Npx]` | 按 §3.3「Figma 数值 ×2 = Android dp」换算 |  |

### 6.1 反向工程识别注意

MCP 把 9-patch 的视觉效果（圆角 + 描边 + 立体凸起）反向工程成 CSS 多层 div + inset shadow。看到这种结构**不要**真的实现成多层 View，应该：

1. 第一时间触发 §2.1 视觉签名识别 → 是 StrokeButton
2. 按 §3 选具体 9-patch 资源
3. 用 StrokeButton + 9-patch 单层实现，不复刻多层 div

### 6.2 MCP 资源 URL 处理

MCP 输出会带形如 `https://www.figma.com/api/mcp/asset/<uuid>` 的 7 天过期 URL。**spec.md 不存 URL**，spec 阶段只记 figma node ID + size + 用途；URL 入仓由实施阶段处理（见 `~/.claude/figma-asset-export-guide.md`）。

---

## 7. 资源导出尺寸换算（铁律）

**前提**：本规则适用画布是 **1x 比例**的 Figma 项目（如 iPhone 13 mockup 375×812 / iPad mockup 等都是 1x）。Android 端需要 **3x（xxhdpi）** 资源。

### 7.1 铁律

```
spec.md 标的尺寸（1x dp）  ×3  →  导出 px  →  drawable-xxhdpi/
```

| spec.md 1x dp | 导出 3x px | 落盘目录 |
|---|---|---|
| 24 × 24 | 72 × 72 | `app/src/main/res/drawable-xxhdpi/` |
| 40 × 8  | 120 × 24 | `drawable-xxhdpi/` |
| 130 × 130 | 390 × 390 | `drawable-xxhdpi/` |
| 284 × 284 | 852 × 852 | `drawable-xxhdpi/` |
| 375 × 244 | 1125 × 732 | `drawable-xxhdpi/` |
| 375 × 812（全屏）| 1125 × 2436 | `drawable-xxhdpi/` |

### 7.2 不要做的事

- ❌ **不要导出 1x** 直接放 `drawable/`（无 density 限定）—— 在 xhdpi/xxhdpi/xxxhdpi 设备上会被拉伸糊掉
- ❌ **不要导出 2x** 放 `drawable-xhdpi/` —— 项目惯例只用 xxhdpi 单一 density
- ❌ **不要导出 4x** 放 `drawable-xxxhdpi/` —— 同上，单 density 即可
- ❌ 不要在 spec.md 标 px / 3x dp；spec 永远是 1x dp 标注，换算在导出阶段做

### 7.3 例外：9-patch

9-patch 资源（`*.9.png`）**不分 density**，统一放 `drawable/` 根目录或项目惯例位置。9-patch 靠 patch 标记拉伸而非按 dpi 缩放。**不适用** §7.1 的 ×3 规则。

### 7.4 工具支持

- `~/.claude/scripts/figma-export.sh` 默认 `scale=3`，自动落 `drawable-xxhdpi/`，内置 pngquant + cwebp lossless 两步压缩管线（导出即接近最优体积）
- assets.json 里只标 1x dp size，脚本读取后自动 ×3 调用 Figma `/v1/images?scale=3`

---

## 8. Open Questions 兜底策略

本文件 + 项目侧 mapping 没覆盖到的视觉模式 / 颜色不匹配 / 高度超界 → **不要替用户猜**。

写到 spec 的 §7 Open Questions，命名规则：`Q{N}（{类目}）：{问题}`。例如：

- `Q5（按钮 9-patch）`：Figma 颜色 #XXX 不在项目 9-patch 清单内，是否新增 / 用相近色？
- `Q6（按钮高度缩小）`：Figma 28dp，项目最低 32，9-patch 不可缩，是否改 Figma 稿 / 新增更小资源？
- `Q7（颜色日夜）`：新增的 `xxx_bg` token 是否需要 night 变体？Figma 没出夜间稿。

---

## 9. AI 产 spec 时的必读流程

每次产 `{页面名}-spec.md` 时按顺序：

1. **先读本文件**（user-scope 通用规则）
2. **再读项目侧 mapping**（`<project>/docs/figma-mapping/figma-android-ui-mapping.md`）拿项目专属清单
3. **再读项目侧命名约定**（`<project>/docs/figma-mapping/figma-asset-naming.md`）确定模块名
4. 在 spec 的 §1 Colors：
   - 每个 hex 必做 token 匹配（grep `<project>/app/src/main/res/values/colors*.xml` 全部）
   - 命中已有 token → `@color/xxx`
   - 未命中 → 标"需新增 token，建议名 `xxx`" + 列入 OQ
   - **任何 hard-code hex 都视为不合格 spec**
5. 在 spec 的 §2 Typography：按 §1 决策树精确映射到具体 `@font/{weight}` 文件
6. 在 spec 的 §4 Component Styling：
   - 每个按钮做 §2.1 视觉签名识别 → 是 StrokeButton 还是 MaterialButton
   - 9-patch 选取按 §3.2 决策树（精确高度优先）
   - 文字描边色按项目侧 `stroke_color_xxx` 表
7. 在 spec 的 §6 Element List：按钮统一标注组件类型

---

## 10. 单位规则

- 长度 / 间距 / 圆角 / 描边宽度 → `dp`
- 字号 → `sp`
- **允许等值替代**：行高 12sp 与 12dp 等价时可写其中一种
- **禁止 hard-code hex**：见 §4.1 铁律
