# Figma 资源命名通用规则（Android 项目）

> 用途：跨项目通用的 Figma 导出资源（bitmap / icon）命名格式约定。
> 项目专属内容（具体模块名清单、案例、命名 v2 改造历史等）见对应项目的 `<project>/docs/figma-mapping/figma-asset-naming.md`。
>
> 本文件由 `android-figma-spec` 与 `android-figma-impl` 两 skill 共享。

---

## 1. 通用命名格式

```
bg_{模块}_{位置}[_{修饰}].{ext}     背景类（装饰图、底图、整页插图等大尺寸视觉资源）
ic_{模块}_{位置}_{用处}.{ext}        图标 / 中等插图（含小至 24dp 图标、大至 285dp 中心插画）
```

### 字段约定

| 字段 | 含义 | 示例 |
|---|---|---|
| `模块` | 业务模块缩写（snake_case，2 词以内最佳） | `home_promo`、`avatar_editor`、`pk_match` |
| `位置` | 在页面中的位置 / 角色 | `top`、`bottom`、`center`、`header`、`item` |
| `用处`（仅 ic_）| 图标用途 / 行为 | `back`、`close`、`like`、`illustration` |
| `修饰`（仅 bg_，可选）| 进一步描述 | `gradient`、`pattern` |

具体模块名清单见**项目侧** `<project>/docs/figma-mapping/figma-asset-naming.md`。

---

## 2. 何时用 bg vs ic

- **bg**：作为背景 / 大尺寸装饰底图，常见占据容器全宽或全屏
- **ic**：所有"前景"图（小图标 + 中心插图都算）

---

## 3. 例外（不在本规则范围）

- **9-patch**：沿用项目既有命名 `bg_primary_button_{颜色}_{高度}.9.png`（见 ui-mapping-rules.md §3）
- **状态列表 / shape drawable XML 资源**：业务侧自定义，不强制走 bg_/ic_ 规则
- **Vector Drawable**（icon 矢量图）：项目惯例可能不同，按项目自定

---

## 4. 命名时机

- **spec 阶段**：**不固化**最终 drawable 名（spec.md 只列 figma node ID + size + type + 用途）
- **实施阶段**：按本规则补名，落入 `assets.json`，跑 `figma-export.sh` 时落盘到 `drawable-xxhdpi/`

> 原因：spec 阶段命名不稳，等实施时见到资源全貌再决定模块名 / 位置 / 用处更准确。
