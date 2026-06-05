---
name: android-figma-spec
description: 把 Figma 链接转成 Android 还原用的单页 spec.md + .excalidraw 结构图。触发：用户贴 figma.com URL 并要求 Android 还原 / 出 spec / sampeng 方法 / 产视觉规范。范围：仅产 spec 文档，不导出资源、不写 XML 实施代码。资源导出（全局）见 ~/.claude/figma-asset-export-guide.md；通用映射规则见 references/ui-mapping-rules.md；项目专属清单见 <project>/docs/figma-mapping/。
---

# Figma → Android Spec 生成

## 何时触发

- 用户贴 Figma URL（`figma.com/design/...?node-id=...`）+ 要求 Android 还原 / 出 spec
- 用户说："生成 spec"、"按这个 figma 出 spec"、"用 sampeng 方法"、"出视觉规范"
- 用户说："重新跑这个 spec"（重生成）

## 不在本 skill 范围内（不要跨界）

| 阶段 | 归属 | 说明 |
|---|---|---|
| 资源导出（图片/icon → `res/drawable-*/`）| 实施阶段（全局）| 跑 `~/.claude/scripts/figma-export.sh`，详见 `~/.claude/figma-asset-export-guide.md` |
| 资源命名规则（`bg_/ic_` 格式）| 实施阶段 | 通用见 `references/asset-naming.md`，项目专属（模块名 / 案例）见 `<project>/docs/figma-mapping/figma-asset-naming.md` |
| PNG 压缩 / WebP 转换管线 | 实施阶段（脚本内置）| `figma-export.sh` 已自带 pngquant + cwebp lossless 两步管线，导出即接近最优体积，无需事后再压 |
| XML 布局 + Fragment / Activity 代码 | 实施阶段 | spec + OQ 都 OK 后由 `android-figma-impl` skill 执行 |

**原则**：spec.md 描述"需要什么资源"（用途、来源 figma node、size、type），但**不固化具体 drawable 文件名**。文件名由实施阶段按命名规则确定。

## 执行流程（Step 0 + 5 步）

### Step 0：输入校验（dev link 强校验，**前置门**）

**铁律**：用户提供的所有 Figma 链接**必须**含 `m=dev` 参数（Dev Mode link）。

校验逻辑：

1. 收到链接后立刻 grep `m=dev`
2. 任一链接缺失 → **立即停止**，输出：
   > 该链接不是 Dev Mode link（缺 `m=dev`）。请在 Figma 内进 Dev Mode → 右键目标 frame → "Copy link to selection" 重新提供。**不允许**用普通 Share / Copy link。
3. 校验未通过时，**不进任何 MCP 调用、不读 mapping、不动文件**

**为什么强要求**：Dev Mode link 触发 MCP 的 Dev Mode 上下文，能拿到设计 token / 资源 URL 全集；普通 link 资源信息缺失，导致 spec 不完整或要二次拉取浪费配额。

### Step 1：先读映射规则（必读，两层）

按顺序读：

1. **user-scope 通用规则**：`references/ui-mapping-rules.md`
   - §1 字体 weight → 文件决策树
   - §2 StrokeButton 视觉签名
   - §3 9-patch 高度匹配 / 描边×2 / 文字描边色
   - §4 颜色铁律 + 日夜模式 + alpha 速查
   - §6 MCP 输出 → 项目组件识别
   - §7 资源×3 → xxhdpi 铁律

2. **项目专属清单**：`<project>/docs/figma-mapping/figma-android-ui-mapping.md`
   - 项目实际字体清单（确定具体 `@font/xxx` 文件名）
   - 项目实际 9-patch SKU 列表（确定具体 `bg_primary_button_*_*` 名）
   - 项目实际颜色 token（`stroke_color_xxx` 表 + 颜色文件清单）
   - 项目内部 widget 全名（StrokeButton 类全路径）

3. **项目命名约定**：`<project>/docs/figma-mapping/figma-asset-naming.md`
   - 项目模块名清单（如 `home_promo` / `avatar_editor`）
   - 案例参考

> **两份合起来 = 完整 mapping**。user-scope 只规定换算口径，项目侧只罗列项目实际清单，互不重复。

### Step 2：拉 Figma 设计上下文

用 Figma MCP：
- `mcp__figma__get_design_context`（必需，含截图 + node 树）
- 必要时 `mcp__figma__get_screenshot`（独立截图）

URL 解析：`figma.com/design/:fileKey/...?node-id=A-B` → fileKey = `:fileKey`、nodeId = `A:B`

### Step 3：产出两份文件

落盘位置：`<project>/docs/figma-specs/`

| 文件 | 内容 |
|---|---|
| `{页面名}-spec.md` | 按 `references/spec-template.md` 5 维度模板填写 |
| `{页面名}.excalidraw` | Excalidraw JSON v2，结构骨架（rectangle + text + 简单标注），让人秒看层级是否对 |

页面命名建议：`{业务模块}-{页面类型}`，如 `add-to-home-screen-bottom-sheet`、`avatar-editor-toolbar`。

### Step 4：填写规则

填 spec.md 各章节时严格按以下规则：

- **§1 Colors**：每个 hex 必做 token 匹配。命中 → `@color/xxx`；未命中 → 标"需新增 token，建议名 `xxx`" + 列入 OQ（决策是否加 night 变体）。**禁止 hard-code hex 留在 spec 里**
- **§2 Typography**：weight 精确映射到具体字体文件（不要写 `textStyle="bold"`，不要引用 family）
- **§4 Component Styling**：按钮先做视觉签名匹配 → 是 `StrokeButton` 还是 `MaterialButton`；选具体 9-patch 资源（精确高度优先）；文字描边色优先 stroke token
- **§4.x 资源复用前置检查**：拿到 MCP 输出后，对每个 asset：
  1. grep `<project>/app/src/main/res/drawable*/` 找同语义 / 同尺寸候选
  2. 命中 → spec 里写「**建议复用** `R.drawable.xxx`，待人确认」+ 列入 OQ
  3. 未命中 → 进下一项「待导出清单」
  > 注意：项目目前**无 Code Connect**，不要等 MCP 输出 `R.drawable.xxx` 引用
- **§4.x 图标 / Drawable 待导出清单**：列 figma node ID + 用途 + size + type。**不写最终 drawable 文件名**（命名归实施阶段）。**严禁**保存 MCP 返回的 `https://www.figma.com/api/mcp/asset/...` URL（7 天过期）
- **§7 Open Questions**：单位 / 颜色 / 高度 / 状态 / 夜间模式 不确定 → 一律列出，不要替用户猜

### Step 5：自检 + 交付

提交前对照 `references/spec-template.md` 的字段做检查：

- ✅ 所有 hex 都有 `@color/xxx` 引用或 OQ
- ✅ 所有字体精确到具体 `.otf/.ttf` 文件
- ✅ 立体按钮 vs 普通按钮已识别
- ✅ 9-patch 高度选取按精确匹配优先
- ✅ Open Questions ≥ 0 条，覆盖所有不确定项

输出给用户：
- 两份文件的相对路径
- Open Questions 关键 3 条（影响实施的）的简短列表

## 必读 references

- `references/workflow.md` —— sampeng 方案背景 + 4 步法
- `references/spec-template.md` —— 单页 spec 模板（5 维度字段定义）
- `references/ui-mapping-rules.md` —— **通用** Figma → Android 映射换算规则（项目无关）
- `references/asset-naming.md` —— **通用** drawable 命名格式（项目无关）
- `<project>/docs/figma-mapping/figma-android-ui-mapping.md` —— **项目专属**清单（字体 / 9-patch / token）
- `<project>/docs/figma-mapping/figma-asset-naming.md` —— **项目专属**模块名 / 案例

## MCP URL 7 天纪律

MCP 返回的资源 URL（形如 `https://www.figma.com/api/mcp/asset/<uuid>`）**7 天后失效**。

- ❌ **严禁**直接保存 URL 到 `spec.md` —— 7 天后 spec 失效信息
- ✅ 要保存请**立刻下载入仓**（走资源导出管线）
- ✅ spec.md 里只写 **figma node ID + size + 用途 + type**

## MCP 配额耗尽处理

MCP 配额：Pro / Dev seat 200 calls/day。

耗尽时：

- ❌ **不**自动 retry（429 期间 retry 在 REST 体系下会重置 cooldown，最坏 4.6 天惩罚）
- ❌ **不** fallback 到 REST API
- ✅ **直接报错停手**，告知用户：
  > Figma MCP 配额耗尽（200/day）。请换账号 / 等次日 / 联系 team owner 调整 seat。本次 spec 无法继续。

## 常见反模式（避免）

- ❌ 把 layer-list 自定义 drawable 写进 spec —— 项目已有 9-patch，应直接用 StrokeButton + 9-patch
- ❌ 在 spec 里写死 drawable 文件名 —— 命名是实施阶段的事
- ❌ 看不清就猜 —— 一律 Open Questions
- ❌ 用 `textStyle="bold"` —— 系统加粗算法不可控，必须引具体字体文件
- ❌ 用 hex hard-code 颜色 —— 必须 token 化或新增 token

## 与实施阶段的衔接

spec.md 的 §4.x 图标 / Drawable 清单提供 figma node ID + 用途 + size + type；实施阶段（`android-figma-impl` skill）会：

1. 读项目命名规则（`<project>/docs/figma-mapping/figma-asset-naming.md`），按规则补 drawable 名
2. 落 `<project>/docs/figma-specs/{页面名}.assets.json`
3. 跑 `~/.claude/scripts/figma-export.sh <project>/docs/figma-specs/{页面名}.assets.json`
4. 资源到位后再写 XML 实施代码
