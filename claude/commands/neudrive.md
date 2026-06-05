<!-- neudrive-managed:command -->
---
description: Route `/neudrive <subcommand>` through the installed neuDrive skill and MCP surface.
---

Use the installed `neudrive` skill at `~/.claude/skills/neudrive/SKILL.md`.

Treat the first argument after `/neudrive` as the subcommand.
Supported subcommands: `ls`, `read`, `write`, `search`, `create`, `log`, `import`, `token`, `stats`, `export`, `status`, `help`.
Examples: `/neudrive ls`, `/neudrive read profile/preferences`, `/neudrive import claude`, `/neudrive status`.
Use `/neudrive help` or `/neudrive help import` when the user needs guidance on the command surface.
Use the Git Mirror page in neuDrive when the user wants a repo-backed mirror of the Hub.

1. Read `~/.claude/skills/neudrive/SKILL.md`.
2. Read the matching command document under `~/.claude/skills/neudrive/commands/`.
3. Use neuDrive MCP tools for all Hub reads and writes.
4. Use `~/.claude/skills/neudrive/references/platforms/claude.md` for Claude-specific routing.

If no subcommand is provided, treat it as `help`.
