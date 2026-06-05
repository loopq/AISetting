# Figma 资源导出指南（全局）

> 配套脚本：`~/.claude/scripts/figma-export.sh`
> 适用：任何使用 `app/src/main/res/` 目录约定的 Android 项目。
> **项目特定的资源命名规则、模块名约定、压缩管线改造 TODO** 不在本文档——见各项目本地的 `.claude/figma-asset-naming.md`。

---

## 一次性设置：Figma Personal Access Token

### Step 1：生成 Token

1. 浏览器打开 [https://www.figma.com/settings](https://www.figma.com/settings)
2. 顶部 Tab 切到 **「Security」** → 滚到 **「Personal access tokens」** 区域
3. 点 **「Generate new token」**
4. **Token name**：填 `claude-code-asset-export`（任意便于识别的名字）
5. **Expiration**：建议 90 天（到期后重新生成）；本地使用也可选 `No expiration`
6. **Scopes（权限勾选清单）**——只勾这一个，**其他全部不勾**：

   | Scope                    | 是否勾选 | 说明                                                       |
   | ------------------------ | -------- | ---------------------------------------------------------- |
   | **File content**         | ✅ Read   | 调用 `/v1/images` 渲染导出 API 必需（仅需 Read）           |
   | Current user             | ❌        | 不需要                                                     |
   | Library content          | ❌        | 不需要（除非用 Team Library 的 component）                 |
   | Library analytics        | ❌        | 不需要                                                     |
   | Comments                 | ❌        | 不需要                                                     |
   | Webhooks                 | ❌        | 不需要                                                     |
   | Dev resources            | ❌        | 不需要                                                     |
   | Code Connect             | ❌        | 不需要                                                     |
   | Variables                | ❌        | 不需要                                                     |
   | Projects (Read content)  | ❌        | 不需要                                                     |

7. 点 **「Generate token」**
8. **立即复制 token**（界面只显示一次，关掉就再也看不到，以 `figd_` 开头）

### Step 2：保存 Token

**方式 A（推荐）**：写入 shell rc 文件，全局可用

```bash
# zsh
echo 'export FIGMA_TOKEN="figd_粘贴你的token"' >> ~/.zshrc
source ~/.zshrc

# bash
echo 'export FIGMA_TOKEN="figd_粘贴你的token"' >> ~/.bashrc
source ~/.bashrc
```

**方式 B**：项目本地 `.env`（确保已被 `.gitignore`）

```bash
echo 'FIGMA_TOKEN=figd_粘贴你的token' > .env
# 使用前：source .env && export FIGMA_TOKEN
```

### Step 3：验证

```bash
# 1) 确认 token 已加载到 shell
echo "${FIGMA_TOKEN:0:8}..."   # 应输出 figd_xxx...

# 2) 直接打 /v1/images 接口验证（这是脚本真正用的接口）
#    把 :FILE_KEY 和 :NODE_ID 替换为你任意一个 Figma 文件的值
curl -i -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/images/:FILE_KEY?ids=:NODE_ID&format=png&scale=1"
```

期望响应：

- 第一行 `HTTP/2 200`
- body 形如 `{"err":null,"images":{":NODE_ID":"https://s3-..."}}`

> ⚠️ 不要用 `/v1/me` 验证 —— 那个接口需要 `Current user: Read` scope，本工作流不需要。
> 只勾 `File content: Read` 是正确的最小权限，但意味着 `/v1/me` 会 403，不代表 token 不可用。

---

## 工具依赖

```bash
brew install jq pngquant webp
```

| 工具  | 用途                     |
| ----- | ------------------------ |
| `jq`  | 解析 assets.json         |
| `pngquant` | PNG 减色（lossy 预压缩，65-80 quality）|
| `cwebp` (来自 `webp` 包) | PNG → WebP 无损转换（lossless / -m 6 / -mt）|
| `curl` | 下载（mac 自带）        |

> 管线流程：Figma `/v1/images?format=png` 下载 → `pngquant --quality=65-80` 减色 → `cwebp -lossless -m 6 -mt` 转 WebP → 落 `drawable-xxhdpi/`。导出即接近最优体积，无需事后再过 `compress_images.sh`。
> pngquant 处理失败时（典型：复杂渐变图减色损伤）自动回退到「跳过 pngquant、原 PNG → cwebp -lossless」，仅 WARN 不阻塞。

---

## 用法

### 1. 在项目内产 spec 时同步产出 `{spec}.assets.json`

约定：每个 `{页面名}-spec.md` 旁边放一个同名的 `{页面名}.assets.json`。

### 2. 跑导出（在项目根目录执行）

```bash
~/.claude/scripts/figma-export.sh docs/figma-specs/{页面名}.assets.json
```

脚本自动：
- 用 `git rev-parse --show-toplevel` 找当前 git 项目根
- 落资源到 `<项目根>/app/src/main/res/{dest}/`

输出示例：

```
[figma-export] file_key:    XXXXXXXX
[figma-export] assets:      2
[figma-export] [1/2] some_image (node=11012:14447, type=bitmap, scale=3)
[figma-export]   downloaded: 245678 bytes
[figma-export]   saved: <project>/app/src/main/res/drawable-xxhdpi/some_image.webp (45123 bytes)
[figma-export] ===== Summary =====
[figma-export] OK:    2
[figma-export] FAIL:  0
[figma-export] SKIP:  0
```

---

## `assets.json` Schema

```json
{
  "file_key": "XXXXXXXX",                  // Figma 文件 key (URL 路径段)
  "assets": [
    {
      "name":    "some_image",             // 不带后缀；命名应符合项目本地 figma-asset-naming.md 规则
      "node_id": "11012:14447",            // Figma node ID（: 形式或 - 形式皆可）
      "type":    "bitmap",                 // bitmap | vector (vector 未支持)
      "ext":     "webp",                   // 目标扩展名
      "scale":   3,                        // 1 = mdpi, 2 = xhdpi, 3 = xxhdpi
      "dest":    "drawable-xxhdpi"         // 目标 res 子目录
      // "quality": 85                     // 已废弃；管线现在走 pngquant + cwebp lossless，quality 字段被忽略并打 WARN
    }
  ]
}
```

### 字段约定

| 字段 | 取值 | 说明 |
|---|---|---|
| `name` | snake_case | 不带扩展名，最终文件 = `name.ext`；**命名规则按项目本地 `.claude/figma-asset-naming.md`** |
| `type` | `bitmap` / `vector` | bitmap 走 PNG → WebP；vector v1 未支持 |
| `ext` | `webp` / `png` / `xml` | bitmap 推荐 `webp` |
| `scale` | `1` / `2` / `3` / `4` | 与 `dest` 密度对应（3 → xxhdpi） |
| `dest` | `drawable` / `drawable-xxhdpi` 等 | scale 3 必须落 xxhdpi |
| `quality` | （已废弃） | 旧版字段；管线已切到 pngquant + cwebp lossless，写了会被忽略并打 WARN，可从 assets.json 中移除 |

### 密度对应表

| scale | dest                | 像素密度 |
| ----- | ------------------- | -------- |
| 1     | `drawable-mdpi`     | 1x       |
| 2     | `drawable-xhdpi`    | 2x       |
| 3     | `drawable-xxhdpi`   | 3x ⭐ 推荐 |
| 4     | `drawable-xxxhdpi`  | 4x       |

> **默认走 `scale=3 + drawable-xxhdpi`**，对绝大多数现代 Android 设备是最佳取舍（清晰度 vs 体积）。

---

## icon 尺寸防御（v1 暂未支持，规则先约定）

vector 支持上线后：

- spec 里每个 icon **必须标注 display 尺寸**（如 `display: 24dp`）
- 导出脚本自动把 SVG 转 Vector Drawable，`android:width/height` 设为 `display` 值
- 这样 Figma 上 icon 画 16dp 还是 100dp 都不影响最终一致性

---

## 故障排查

| 错误                                  | 原因 / 解决                                               |
| ------------------------------------- | --------------------------------------------------------- |
| `FIGMA_TOKEN env var required`        | Token 未导出。`echo $FIGMA_TOKEN` 验证                     |
| `Figma API HTTP 403`                  | Token 权限不足。重新生成，确保勾选 `File content: Read`    |
| `Figma API HTTP 404`                  | `file_key` 错误，或你账号无权访问该文件                    |
| `Figma API: Invalid parameter`        | `node_id` 格式错误。用 `11012:14447` 或 `11012-14447`     |
| `cwebp not installed`                 | `brew install webp`                                       |
| `pngquant not installed`              | `brew install pngquant`                                   |
| `no download URL for node X`          | 该 node 无可视化内容（可能是 group/frame 而非 image），调整 node_id |
| `not in a git repo`                   | 脚本必须在 git 项目内运行（用 `git rev-parse` 定位 res/）  |
| 下载文件特别小（<1KB）                | 通常是 Figma 返回了空白或错误占位图，检查 node 是否为 image |
| 导出 webp 体积仍偏大（再压缩还能省 ≥1KB）| 看脚本日志是否打 `WARN: pngquant skipped` —— 是则说明该图减色失败回退到原 PNG，体积偏大属已知降级；极复杂渐变 / 照片类图本就不一定适合无损 webp |

---

## 项目特定规则不在本文档

以下属于**每个项目自己定**，不在全局 guide 范围：

- 资源命名规则（如 `bg_{模块}_{位置}` / `ic_{模块}_{位置}_{用处}`）
- 模块名约定
- 9-patch 命名沿用
- 后处理管线进一步本地化（pngquant 参数微调、cwebp 选项替换等）

→ 项目侧通常放 `.claude/figma-asset-naming.md`（或类似），由项目自己维护。

---

## v1 局限 / 后续改进

- ❌ 不支持 vector（SVG → Vector Drawable）—— 后续加 `svg2vectordrawable`
- ❌ 不支持批量去重（同一 node 多次出现会重复请求）
- ❌ 不支持失败重试
- ❌ 不支持差量更新（每次全量覆盖）
- ✅ 后处理管线已升级为 pngquant + cwebp lossless 两步无损（不再是 lossy `cwebp -q`）