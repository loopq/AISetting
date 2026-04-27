# PK Revamp — 真实参考实例

> 本文件不复制内容，只记录路径与角色。真正的参考例子在项目目录下，避免此处与真例漂移。

## 参考路径

`/Users/loopq/dev/git/zthd/avatar/Avatar-Android/docs/plans/2026-04-20-pk-revamp/`

## 文件角色对照

| 文件 | 角色 | 对应模板 |
|---|---|---|
| `index.md` | 主索引 + 恢复指南 + 决策日志 + Journey 总览 + BundleConstant 链路 | `templates/index.md` |
| `j1-tdd-infra.md` | J1 数据基建 Spec（§1~§9 完整）| `templates/tdd-spec.md` |
| `j2-home-button.md` | J2 PK 主页改造 Spec | `templates/ui-journey-spec.md` |
| `j2a-battle-entry.md` | J2a 对撞转场 Spec（跨 Journey 衔接示例）| `templates/ui-journey-spec.md` |
| `j3-matching-page.md` | J3 匹配页 Spec（§1~§19 完整 + Q1~Q20 全解决）| `templates/ui-journey-spec.md` |
| `j4-editor-flow.md` | J4 编辑器流程改造（跨 Activity 扩展）| `templates/ui-journey-spec.md` |
| `j5-battle-page.md` | J5 比赛/评分页（状态机 + 动画时长细节）| `templates/ui-journey-spec.md` |
| `j6-result-dialog.md` | J6 结算弹窗（Activity + Dialog Theme 示例）| `templates/ui-journey-spec.md` |
| `j7-leaderboard.md` | J7 排行榜整页化 | `templates/ui-journey-spec.md` |
| `patches/j1-2026-04-21-bot-from-rank.md` | Patch：Phase B 发现的即时 patch | `templates/patch.md` |
| `patches/j4-2026-04-22-reference-dialog-field-fix.md` | Patch：Double Check 发现的字段真实性错误（维度 4 典型案例）| `templates/patch.md` |
| `data/templates.md` | 抽离的大表：40 个模板数据 | - |
| `data/i18n-strings.md` | 抽离的大表：10 locale × N 条翻译 | - |

## 学习要点（对应 Skill 阶段）

### Phase A 参考

- Journey 拆分：7 个 Journey（J1 数据 + J2~J7 UI），边界清晰
- 包名分层：`ui.pk.bot.*` + `data.pk.bot.*`（见 `index.md` §全局技术约束）
- 依赖关系：`J2 与 J3~J7 独立；J3~J7 按编号串行`（见 `index.md` §工作流约定）

### Phase B 参考

- Q 清单一次性全量：见 `j3-matching-page.md` §16（Q1~Q20）
- 决策落盘位置映射：见 `j3-matching-page.md` §16 落盘章节列
- 状态流转：`[WIP]` → `[REVIEW]` 见每个 jN 文件头部
- 即时追 patch：`patches/j1-2026-04-21-bot-from-rank.md`（Phase B 讨论 J2a 时发现 J1 影响，立即生成 patch）

### Phase C 参考

- Double Check 发现的 4 处问题见 `index.md` 决策日志「2026-04-22 Double check 发现 4 处问题」
- 字段真实性典型案例：`patches/j4-2026-04-22-reference-dialog-field-fix.md`（`detail.getImageUrl()` 实际应为 `detail.cover`）
- 埋点命名订正：`PKBot_Editor_*` → `PK_Bot_Editor_*`
- 集合 patch vs 独立 patch：PK revamp 选择了多个独立 patch（问题较集中但归属 Journey 不同），新 feature 若问题同属一处建议合并

### Phase D 参考

- 最终状态：`index.md` §当前进度「当前执行：J1 ... 下一步动作：subagent 执行 ...」
- 交接命令：`/android-feature-execute docs/plans/2026-04-20-pk-revamp/`