---
name: execute-with-review-new
description: Execute a superpowers plan with an automatic Codex review at completion, enforced by a bundled stop hook. Same flow as execute-with-review, but the review runs through codex-plugin-cc instead of the review-loop@hamel-review plugin.
---

# Execute With Review (codex-plugin-cc edition)

## Overview

This skill bridges `superpowers:executing-plans` with a Codex review gate: Step 1 writes a state file; a Stop hook (script bundled in this skill, registered once in `~/.claude/settings.json`) blocks session exit while the gate is active and injects the review instructions.

**Announce at start:** "I'm using the execute-with-review-new skill to implement this plan with review."

## Codex Runtime

All Codex calls go through the codex-plugin-cc companion script:

```bash
COMPANION=$(find ~/.claude/plugins/cache/openai-codex -name codex-companion.mjs 2>/dev/null | sort -V | tail -1)
```

## The Process

### Step 0: Ensure Local PRD Available

Before activating the review gate, make sure any PRD referenced by the plan is persisted locally so the post-review cross-check can read it.

1. Read the plan file you are about to execute
2. Look near the top for `**PRD**: [飞书原文](feishu_url) · [本地副本](local_path)`
3. Branches:
   - **Both links present, local file exists** → continue to Step 1
   - **Both links present, local file missing** → use `lark-doc` skill (`lark-cli docs +fetch --api-version v2 --doc-format markdown --doc <feishu_url> --as user`), save `data.document.content` to `local_path` with frontmatter (`title`, `feishu_url`, `doc_id`, `fetched_at` in ISO 8601 UTC), then continue
   - **Only Feishu URL present** (no 本地副本 link) → fetch via `lark-doc` skill, save to `docs/feishu-prds/{YYYY-MM-DD}-{topic}.md`, update plan header to add the `· [本地副本](...)` segment, then continue
   - **No PRD reference at all** → continue without PRD; the post-execution review will be code-only

See `飞书 PRD 持久化` in CLAUDE.md / AGENTS.md for naming and frontmatter rules.

### Step 1: Initialize the Review Gate

Run this bash command to activate the gate before any work begins:

```bash
bash <<'INIT_SH'
set -e

COMPANION=$(find "$HOME/.claude/plugins/cache/openai-codex" -name codex-companion.mjs 2>/dev/null | sort -V | tail -1)
if [ -z "$COMPANION" ]; then
  echo "Error: codex-plugin-cc is not installed. Run: claude plugin marketplace add openai/codex-plugin-cc && claude plugin install codex@openai-codex" >&2
  exit 1
fi

if ! grep -q "execute-with-review-new/scripts/stop-hook.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
  echo "Error: stop hook not registered. Add to hooks.Stop in ~/.claude/settings.json:" >&2
  echo '  {"hooks": [{"type": "command", "command": "bash ~/.claude/skills/execute-with-review-new/scripts/stop-hook.sh", "timeout": 30}]}' >&2
  exit 1
fi

if [ -f .claude/codex-review-loop.local.md ]; then
  echo "Error: a codex review gate is already active. Delete .claude/codex-review-loop.local.md to cancel it first." >&2
  exit 1
fi

if [ -f .claude/review-loop.local.md ]; then
  echo "Error: a legacy review loop (hamel) is active. Run /cancel-review first." >&2
  exit 1
fi

mkdir -p .claude reviews

REVIEW_ID="$(date +%Y%m%d-%H%M%S)-$RANDOM"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Record HEAD at session start — the review is scoped to commits made AFTER this SHA
# via `review --base <sha>` (merge-base), so it cannot drag in unrelated upstream work.
STARTED_SHA="$(git rev-parse HEAD 2>/dev/null || echo "")"

# Default holistic=false: this skill is for focused implementation, not project-wide audit.
# Set HOLISTIC=true to additionally run an adversarial (design-challenge) review pass.
HOLISTIC="${HOLISTIC:-false}"

cat > .claude/codex-review-loop.local.md <<STATE_EOF
---
active: true
phase: task
review_id: ${REVIEW_ID}
started_at: ${STARTED_AT}
started_sha: ${STARTED_SHA}
holistic: ${HOLISTIC}
attempts: 0
---
Superpowers task execution — review all changes made during this session.
STATE_EOF

echo "Codex review gate activated (ID: ${REVIEW_ID}, started_sha=${STARTED_SHA:0:8}, holistic=${HOLISTIC}). Stop hook will intercept completion."
INIT_SH
```

**Optional env var** (set before the init block): `HOLISTIC=true` — additionally run the project-wide design-challenge pass (`adversarial-review`) in Step 4. Default off because this skill is meant for focused, narrow implementations.

Note: unlike the legacy skill, no `BASE_BRANCH` is needed — the review scope is anchored directly to `started_sha`. There is also no `~/.codex/config.toml` editing and no jq/openssl dependency.

If the command succeeds, proceed. If it fails, stop and fix the prerequisite.

### Step 2: Execute the Plan

Use `superpowers:executing-plans` to load and execute the plan. Follow that skill's full process:
- Load and review the plan critically
- Execute all tasks
- Run all verifications
- Do NOT invoke `superpowers:finishing-a-development-branch` yet — the review gate must run first

### Step 3: Stop — Let the Hook Take Over

When all plan tasks are complete and verified, ensure all session work is **committed** (executing-plans commits per task), then **stop**. Do not attempt to exit or wrap up manually.

The stop hook reads `.claude/codex-review-loop.local.md`, sees `phase: task`, blocks the exit, and injects the exact review commands (with the recorded `started_sha` and `review_id`).

### Step 4: Run the Codex Review

Follow the hook's injected instructions. They amount to (run with Bash `timeout: 600000` — reviews take several minutes):

```bash
node "$COMPANION" review --base <started_sha> --wait
# holistic: true in the state file? Additionally:
node "$COMPANION" adversarial-review --base <started_sha> --wait
```

- If no commits exist after `started_sha` (work left uncommitted), use `--scope working-tree` instead of `--base`.
- Save the full review stdout **verbatim** to `reviews/review-<review_id>.md` with the Write tool.
- If the Bash call times out, do NOT re-run: recover with `node "$COMPANION" status` then `node "$COMPANION" result <job-id>`.

### Step 5: Address Review Findings

1. Read the review output
2. **If the plan referenced a local PRD copy**, read it with the Read tool and cross-check the implementation against the original requirement:
   - Did the implementation cover all PRD requirements (no missing scope)?
   - Did it silently expand beyond PRD scope?
   - Do data shapes / API specs / event-tracking fields match between code and PRD?
   - Note any PRD-vs-code mismatch as an additional finding to address before proceeding
3. For each finding (from Codex and your own PRD check), independently decide if you agree
4. **Agree** → implement the fix
5. **Disagree** → briefly note why you are skipping it
6. Focus on critical and high severity items first

### Step 6: Close the Gate and Complete

1. Delete `.claude/codex-review-loop.local.md` — the stop hook will now allow exit
2. Invoke `superpowers:finishing-a-development-branch` to finalize the work

## Cancel

Delete `.claude/codex-review-loop.local.md` at any time to cancel the gate. As a safety valve, the hook also self-disarms after blocking 3 times without completion (it logs this to stderr and leaves the state file in place).

## Rules

- Do NOT skip Step 1 — without the state file, the stop hook won't fire
- Do NOT call `finishing-a-development-branch` before the Codex review completes
- If a gate is already active (`.claude/codex-review-loop.local.md` exists), cancel it first
- Stop and ask the user if Codex fails; delete the state file to release the gate before stopping

## Prerequisites

- codex-plugin-cc plugin installed and authenticated (`/codex:setup` to verify)
- Stop hook registered once in `~/.claude/settings.json` → `hooks.Stop`:
  `bash ~/.claude/skills/execute-with-review-new/scripts/stop-hook.sh`
- Node.js 18.18+
