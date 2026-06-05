# AI Settings

跨机器同步 AI 开发环境配置的仓库。**全量复制模式，零 symlink**。

## 工作模型

```
本机配置 --sync.sh（白名单全量覆盖入仓 + 泄密门禁 + commit/push）--> GitHub
GitHub  --apply.sh（备份现有配置后全量复制出仓）------------------> 其他机器
```

- 仓库固定 clone 到 `~/dev/tools/AISetting`，就是个普通 git 仓库
- 本机配置文件全部是**真实文件**，仓库只是它们的快照，删掉仓库不影响任何工具运行
- 同步范围由 `scripts/manifest.sh` 白名单定义（唯一事实源），sessions / cache / history 等垃圾天然不进仓库

## 目录结构

```
AISetting/
├── claude/                  # ~/.claude 的受管子集
│   ├── settings.json        # Claude Code 核心配置
│   ├── agents/ commands/ hooks/ scripts/ skills/
│   ├── statusline-command.sh
│   └── figma-asset-export-guide.md
├── codex/                   # ~/.codex 的受管子集
│   ├── AGENTS.md            # 全局角色定义（= ~/.claude/CLAUDE.md，单一事实源）
│   ├── config.toml
│   └── rules/
├── zsh/                     # ~/.zshrc + ~/.config/fish
├── config/
│   └── worktree-tools/      # ~/.config/worktree-tools（git worktree 工具链）
├── scripts/
│   ├── manifest.sh          # 同步白名单（唯一事实源）
│   ├── sync.sh              # 本机 → 仓库 → 推送
│   └── apply.sh             # 仓库 → 本机
└── docs/
    ├── secrets-template.env # 敏感信息模板
    └── agents/              # 设计文档
```

## 场景一：本机配置变了，同步上云

```bash
cd ~/dev/tools/AISetting && ./scripts/sync.sh
```

行为：清空仓库受管目录 → 按白名单复制（symlink 解引用）→ **泄密门禁**（grep 常见 token 模式，命中即中止）→ commit → push。`--no-push` 可只 commit 不推。

## 场景二：新机器初始化 / 其他机器拉取更新

```bash
git clone git@github.com:loopq/AISetting.git ~/dev/tools/AISetting
cd ~/dev/tools/AISetting && ./scripts/apply.sh
```

行为：现有配置备份到 `~/.ai-setting-backup-<时间戳>/` → 全量复制出仓（全部真实文件，不建任何 symlink）→ `codex/AGENTS.md` 同时复制为 `~/.claude/CLAUDE.md` → 若无 `~/.config/ai-secrets.env` 则从模板创建。

然后**手动填入真实 token**：

```bash
vim ~/.config/ai-secrets.env   # 参考 docs/secrets-template.env
```

lark-* skills 由 `npx skills` 管理，仓库里是快照副本；想接外部更新就再跑一次 `npx skills update`。

## 铁律

1. **任何 token / 密钥只放 `~/.config/ai-secrets.env`**（chmod 600，永不进仓库）。`.zshrc` 和需要 token 的脚本自行 source 它。
2. 本仓库是**公开仓库**。sync.sh 的泄密门禁是最后防线，不是许可证——写配置时就不要硬编码秘密。
3. 改配置只改本机的真实文件（`~/.claude/...`、`~/.codex/...`），改完跑 `sync.sh`。不要直接改仓库副本，下次 sync 会被覆盖。
