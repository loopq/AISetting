# 单页 Spec 模板（Android 单位版）

> 用途：每个 Figma 页面还原前，AI 同步产出 `{页面名}.excalidraw` + `{页面名}-spec.md`，spec 文件按本模板填写。
> 字段维度沿用 [Design.MD](https://www.productcool.com/product/design-md) 的 5 个核心维度（色彩 / 排版 / 布局 / 组件样式 / 交互），单位全部翻译为 Android。
>
> **AI 产 spec 前必读**：`docs/figma-mapping/figma-android-ui-mapping.md`（项目素材映射规则，决定字体 / 立体按钮 / 9-patch / 颜色 token 怎么填）
> **不要在 spec.md 里固化 drawable 文件名**——命名归实施阶段（项目命名规则见 `.claude/figma-asset-naming.md`，全局导出 `~/.claude/figma-asset-export-guide.md`）

---

## 模板正文（复制后填充）

````markdown
# {页面名} Spec

- **来源**：{Figma 链接 / 截图路径}
- **目标实现**：{XML / Compose}
- **对应代码位置**：{ui/xxx/XxxActivity.kt + res/layout/xxx.xml}
- **配套 excalidraw**：{页面名}.excalidraw

---

## 1. Colors（色彩）

页面用到的全部色值。`hex` 必填，`token` 选填（已有则写，没有则空）。

| 用途              | hex       | alpha | token（如有）  | 备注            |
| ----------------- | --------- | ----- | ------------- | --------------- |
| Background / 背景 | `#RRGGBB` | 100%  | `R.color.xxx` |                 |
| Surface / 卡片底  | `#RRGGBB` | 100%  |               | elevation 1     |
| Primary / 主色    | `#RRGGBB` | 100%  |               | CTA 按钮        |
| OnPrimary         | `#RRGGBB` | 100%  |               | 主色按钮上的文字 |
| Text / Primary    | `#RRGGBB` | 100%  |               |                 |
| Text / Secondary  | `#RRGGBB` | 60%   |               |                 |
| Divider / 分隔线  | `#RRGGBB` | 12%   |               |                 |
| Semantic / Error  | `#RRGGBB` | 100%  |               |                 |
| Semantic / Success| `#RRGGBB` | 100%  |               |                 |

> alpha 用百分比写；XML 里换算成 8 位 hex 即可（如 60% = `99`）。

---

## 2. Typography（排版）

页面用到的文字样式枚举。

| 用途       | size  | weight        | lineHeight | letterSpacing | fontFamily        | textAppearance（如有） |
| ---------- | ----- | ------------- | ---------- | ------------- | ----------------- | ---------------------- |
| Title / H1 | 24sp  | 700 (bold)    | 32sp       | 0             | sans-serif        |                        |
| Title / H2 | 18sp  | 600 (semibold)| 24sp       | 0             | sans-serif        |                        |
| Body       | 14sp  | 400 (regular) | 20sp       | 0             | sans-serif        |                        |
| Caption    | 12sp  | 400           | 16sp       | 0.4           | sans-serif        |                        |
| Button     | 14sp  | 600           | -          | 0.5           | sans-serif-medium |                        |

> Android 字号用 `sp`，行高用 `lineSpacingExtra`（差值）或 `android:lineHeight`（API 28+）。
> weight 在 XML 里通过 `textStyle="bold"` 或自定义 fontFamily/`@font/xxx` 资源表达。

---

## 3. Layout（布局）

### 3.1 容器层级（伪 ViewTree）

```
ConstraintLayout (root, padding=16dp)
├── Toolbar (height=56dp)
├── ScrollView (vertical)
│   └── LinearLayout (vertical, gap=12dp)
│       ├── HeaderCard (height=120dp)
│       └── RecyclerView (item: ItemAvatar.xml, span=2, itemSpacing=8dp)
└── FloatingActionButton (anchor=bottom_end, margin=16dp)
```

### 3.2 间距 / Padding / Margin

| 位置               | 值     | 备注                       |
| ------------------ | ------ | -------------------------- |
| 页面 padding       | 16dp   | 左右                       |
| 页面 padding-top   | 0dp    | toolbar 已占位              |
| 卡片间垂直间距     | 12dp   |                            |
| 卡片内 padding     | 16dp   |                            |
| 文本组内行间距     | 4dp    |                            |
| 按钮内 horizontal  | 24dp   |                            |
| 按钮内 vertical    | 12dp   |                            |
| RecyclerView item  | 8dp    | item 之间                  |

### 3.3 关键尺寸

| 元素              | width      | height     | 备注                |
| ----------------- | ---------- | ---------- | ------------------- |
| Toolbar           | match      | 56dp       |                     |
| 主 CTA 按钮       | match      | 48dp       | 圆角 24dp（胶囊）   |
| 次按钮            | wrap       | 40dp       |                     |
| Avatar 头像       | 48dp       | 48dp       | 圆形                |
| RecyclerView item | (parent-padding-itemSpacing)/2 | wrap | 2 列网格 |

---

## 4. Component-level Styling（组件样式）

### 4.1 圆角 / Stroke / Elevation

| 组件         | cornerRadius | strokeWidth | strokeColor | elevation | 备注                  |
| ------------ | ------------ | ----------- | ----------- | --------- | --------------------- |
| 卡片         | 12dp         | 0dp         | -           | 2dp       |                       |
| 主 CTA 按钮  | 24dp         | 0dp         | -           | 0dp       | 胶囊形                |
| 次按钮       | 8dp          | 1dp         | `#XXX`      | 0dp       | outlined              |
| 输入框       | 8dp          | 1dp         | `#XXX`      | 0dp       | focused 时换色        |
| Dialog       | 16dp         | 0dp         | -           | 8dp       |                       |

### 4.2 图标 / Drawable

| 用途       | 来源                  | size   | tint        | 备注           |
| ---------- | --------------------- | ------ | ----------- | -------------- |
| 返回按钮   | `@drawable/ic_back`   | 24dp   | `#text_pri` |                |
| 关闭按钮   | `@drawable/ic_close`  | 20dp   | `#text_sec` |                |
| 占位图     | `@drawable/ph_avatar` | 48dp   | -           | placeholder    |

---

## 5. Interactions（交互 / 状态）

### 5.1 状态变化（State List）

| 元素        | default          | pressed                | disabled         | selected         | 备注                |
| ----------- | ---------------- | ---------------------- | ---------------- | ---------------- | ------------------- |
| 主 CTA 按钮 | bg=`#primary`    | bg=`#primary` × 0.85   | bg=`#primary` × 0.4，文字 0.6 | -                | 用 selector       |
| Tab         | text=`#text_sec` | -                      | -                | text=`#primary`，下划线 2dp | indicator height 2dp |
| 输入框      | stroke=`#border` | -                      | stroke=`#disabled` | focused: stroke=`#primary` 2dp |             |

### 5.2 动效 / Transition

| 触发                   | 动画类型             | duration | interpolator   | 备注                   |
| ---------------------- | -------------------- | -------- | -------------- | ---------------------- |
| Activity 进入          | slide_in_right       | 250ms    | fast_out_slow  |                        |
| Dialog 弹出            | scale + fade         | 200ms    | overshoot      |                        |
| 按钮按下               | ripple               | 系统默认 | -              | `?attr/selectableItemBackground` |
| RecyclerView item 点击 | ripple + fade        | 150ms    | -              |                        |

### 5.3 触控反馈 / Hit Area

| 元素           | 视觉尺寸 | 实际可点尺寸 | 备注                |
| -------------- | -------- | ------------ | ------------------- |
| Toolbar 图标   | 24dp     | 48dp         | padding 撑开        |
| 关闭按钮       | 20dp     | 40dp         |                     |

---

## 6. Element List（逐元素清单）

按 ViewTree 顺序，每个可见元素一行，方便 AI 实施时 1:1 对照。

| # | 元素描述           | 类型              | 引用样式 / 内容                         | 备注           |
| - | ------------------ | ----------------- | --------------------------------------- | -------------- |
| 1 | Toolbar 标题       | TextView          | textAppearance=Title/H2，text="头像编辑" |                |
| 2 | 返回按钮           | ImageView         | src=ic_back，tint=text_pri，48dp 触控    |                |
| 3 | 头像预览大图       | ImageView         | 圆角 16dp，size=match × 240dp           | 占位 ph_avatar |
| 4 | 模板列表           | RecyclerView      | item=ItemAvatar，2 列，gap=8dp          | 见 6.1         |
| 5 | 主 CTA "保存"      | MaterialButton    | size=match × 48dp，圆角 24dp，文字 Button | 见 4.1 / 5.1 |
| ... | ...              | ...               | ...                                     | ...            |

### 6.1 子组件：ItemAvatar.xml（如有复用 item）

```
FrameLayout (cornerRadius=12dp, elevation=1dp)
├── ImageView (src=avatar, scaleType=centerCrop)
└── TextView (gravity=bottom_center, padding=8dp, textAppearance=Caption)
```

---

## 7. 待确认 / 缺失信息（Open Questions）

> AI 在产 spec 时，遇到 Figma 上看不清或缺规范的地方，列在这里给人确认。**不要猜**。

- [ ] 主 CTA 按钮的 disabled 颜色 Figma 没标，按"× 0.4 alpha"猜，确认？
- [ ] RecyclerView item 在 fold/平板下是否变 3 列？
- [ ] Toolbar 是否需要随滚动隐藏？
````

---

## 使用方式

1. 拿到 Figma 后，用如下 prompt 触发产出：

   ```
   基于这个 Figma：[链接 / 截图]
   请同时产出两个文件：
   1) docs/figma-specs/{页面名}.excalidraw —— Excalidraw JSON v2 结构骨架
   2) docs/figma-specs/{页面名}-spec.md —— 按 .claude/skills/figma-spec/references/spec-template.md 模板填写

   填写规则：
   - 单位严格按模板（dp/sp）
   - hex 必填，alpha 用百分比
   - token / textAppearance 有则填，没有留空
   - Open Questions 必须列出来，不要替我猜

   后续我会基于这两个文件让你写 Android XML 代码，不再让你回看 Figma。
   ```

2. 人 review excalidraw（结构对不对）+ spec.md（细节对不对）+ Open Questions（人工裁决）

3. review 通过后，扔给 AI：「按 spec.md + excalidraw 实施 XML 布局，不要回看 Figma」

---

## 字段对应关系（与 Design.MD 5 维度）

| Design.MD（web 默认）            | 本模板（Android）         |
| -------------------------------- | ------------------------- |
| Color palettes                   | Section 1 Colors          |
| Typography（font/weight/line）   | Section 2 Typography      |
| Layout constraints（grid/spacing）| Section 3 Layout         |
| Component-level styling          | Section 4 Component Styling |
| Interaction details              | Section 5 Interactions    |
