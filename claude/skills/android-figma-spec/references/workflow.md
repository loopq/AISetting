# Figma 还原工作流复现（sampeng 方案）

> 来源：V2EX 帖子 [#1209036](https://v2ex.com/t/1209036) 中用户 sampeng 在 #42 / #93 / #94 楼的发言。
> 目标：先 1:1 复现 sampeng 的工作流，跑通最小 MVP 后再谈优化。

## sampeng 原话引用

- **#42**：「做 h5 活动开发，页面很复杂，设计稿层级很麻烦。我现在也是对话模式，figma mcp 设计稿还原一比一很差……」
- **#93**：「都不用 skill，只要说给我还原到这个就可以了。我为了好看，网上随便找的一个会描述颜色和规范的。基本可以 100% 还原」
- **#94**：「因为，在画这个的时候间距，颜色，元素的细节就在另一个文档里也同步描述了一遍。调起来飞快。」

## 工作流字面复现（4 步，无 skill）

**Step 1**：拿到 Figma 设计稿（sampeng 用 Figma MCP，但承认「还原一比一很差」——所以 Figma 只是源头，不直接用于实施）。

**Step 2**：让 AI **同时**产出两个东西：
- 一份 **excalidraw**（JSON 格式的简化结构图）
- 一份 **「描述颜色和规范」的文档**（间距、颜色、元素细节）

**Step 3**：人 review 这两个产物（看图 + 看规范文档）。

**Step 4**：AI 根据这两个产物实施代码（不再回看原 Figma）。

> sampeng 强调「都不用 skill」——最小 MVP 就是 prompt + 两份产物，不装任何 Claude Code skill。

## 「网上随便找的一个会描述颜色和规范的」候选

按 sampeng 描述（「网上随便找」+「描述颜色和规范」+ drop-in 即可），最匹配的候选：

### 首选：Design.MD（getdesign.md）
[Design.MD - Drop-in design systems your AI coding agent can read](https://www.productcool.com/product/design-md)

特征完美吻合 sampeng 描述：
- markdown 文件，drop-in 给 AI coding agent
- 字面就是「描述颜色和规范」：color palettes（primary/secondary/semantic）、typography（font families/weights/line heights）、layout constraints（grids/spacing scales）、component-level styling（border-radii/shadows）、interaction details（hover/transitions）
- 不是 skill，就是一份文档——符合 sampeng「都不用 skill」
- 公开发布在网站上的模板集——符合「网上随便找的」

### 备选 1：Bundl AI 的 UI Component Designer Prompt
[Bundl AI Prompt Template](https://www.bundl.ai/prompt/3950d0667b7a-ui-component-designer)

纯 prompt 模板，包含 spacing/sizing/colors/typography 规范、所有组件状态（default/hover/active/disabled/error）、交互动效、可访问性。

### 备选 2：GenDesigns 的 Design Tokens 框架
[GenDesigns AI UI Framework](https://gendesigns.ai/blog/ai-prompts-for-ui-design-complete-framework)

给一份 design tokens（Primary、Background、Surface、Text、Font、Radius、8px spacing grid），让 AI 每次生成都遵守。

## excalidraw 部分（sampeng 未明说细节）

sampeng 说「都不用 skill」，所以 excalidraw 那一份**直接由 prompt 让 AI 输出 JSON**即可。需要时参考：

- [Excalidraw JSON Schema 官方文档](https://docs.excalidraw.com/docs/codebase/json-schema)
- 极简起步：扔给 AI 一句「按 Excalidraw JSON v2 schema 输出元素，elements 数组里每个对象包含 type / x / y / width / height / strokeColor / backgroundColor / 文本绑定关系」

## 最小 MVP（现在就能跑）

1. 找一个真实页面做样本（Figma 链接 + 项目里对应要还原的位置）
2. 一段 prompt：

   ```
   基于这个 Figma 设计稿：[链接 / 截图]
   请同时产出两个文件：
   1) {页面名}.excalidraw — Excalidraw JSON v2 格式的结构骨架
   2) {页面名}-spec.md — 颜色 / 间距 / 字号 / 字重 / 元素状态 / 交互细节的规范文档
   后续我会基于这两个文件让你写 Android XML 代码，不再让你回看 Figma。
   ```

3. 把 Design.MD 模板拼到 prompt 末尾，作为「规范文档应该长什么样」的参照
4. 跑一遍，看产物质量
5. **不动**——直接拿这两个产物让 AI 写 Android 代码，看还原度

> 跑通后再谈优化（例如让 AI 在 spec 文档里映射到项目 `colors_v2.xml` token）。

## 参考链接

- [V2EX 原帖](https://v2ex.com/t/1209036)
- [Design.MD 模板](https://www.productcool.com/product/design-md)
- [Bundl AI UI Component Designer Prompt](https://www.bundl.ai/prompt/3950d0667b7a-ui-component-designer)
- [GenDesigns AI UI Prompt Framework](https://gendesigns.ai/blog/ai-prompts-for-ui-design-complete-framework)
- [Excalidraw JSON Schema 官方文档](https://docs.excalidraw.com/docs/codebase/json-schema)
- [coleam00/excalidraw-diagram-skill](https://github.com/coleam00/excalidraw-diagram-skill)（备用，sampeng 说不用 skill，但项目结构可参考）
