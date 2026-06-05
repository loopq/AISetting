---
name: parallel-execute-with-review
description: Use when executing a multi-phase plan where one or more foundation phases must complete sequentially before independent phases can run in parallel, with automatic Codex review of the full diff at completion.
---

# Parallel Execute With Review

## Overview

Extends `execute-with-review` with DAG-style phase execution:

- `[foundation]` phases run **sequentially first** (blocking gate)
- All remaining phases **dispatch in parallel** as subagents after foundation completes
- Any phase failure **aborts everything**
- One Codex review covers the **entire diff** at the end

**Announce at start:** "I'm using the parallel-execute-with-review skill to implement this plan."

## Plan File Format

Mark foundation phases with `[foundation]` in the heading:

```markdown
## Phase 0: Setup & Core Interfaces [foundation]
Shared code other phases depend on. Must complete first.
...

## Phase 1: Feature Module A
Independent — runs in parallel with Phase 2.
...

## Phase 2: Feature Module B
Independent — runs in parallel with Phase 1.
...
```

**Rules:**

- Any phase tagged `[foundation]` blocks all parallel phases
- Multiple `[foundation]` phases execute in document order, one by one
- Phases without the tag all dispatch simultaneously after foundations complete
- If a parallel phase secretly depends on another parallel phase → promote it to `[foundation]`

---

## The Process

### Step 0: Ensure Local PRD Available

Before activating the review loop, make sure any PRD referenced by the plan is persisted locally so Codex can read it during the final full-diff review without needing MCP access.

1. Read the plan file you are about to execute
2. Look near the top for `**PRD**: [飞书原文](feishu_url) · [本地副本](local_path)`
3. Branches:
   - **Both links present, local file exists** → continue to Step 1
   - **Both links present, local file missing** → use `lark-doc` skill (`lark-cli docs +fetch --api-version v2 --doc-format markdown --doc <feishu_url> --as user`), save `data.document.content` to `local_path` with frontmatter (`title`, `feishu_url`, `doc_id`, `fetched_at` in ISO 8601 UTC), then continue
   - **Only Feishu URL present** (no 本地副本 link) → fetch via `lark-doc` skill, save to `docs/feishu-prds/{YYYY-MM-DD}-{topic}.md`, update plan header to add the `· [本地副本](...)` segment, then continue
   - **No PRD reference at all** → continue without PRD; the post-execution review will be code-only

See `飞书 PRD 持久化` in CLAUDE.md / AGENTS.md for naming and frontmatter rules.

### Step 1: Initialize Review Loop State

Run before any work begins:

```bash
bash <<'INIT_SH'
set -e

REVIEW_ID="$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 3 2>/dev/null || head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n')"
mkdir -p .claude reviews

if [ -f .claude/review-loop.local.md ]; then
  echo "Error: review loop already active. Run /cancel-review first." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: Codex not installed. Run: npm install -g @openai/codex" >&2
  exit 1
fi

CODEX_CONFIG="${HOME}/.codex/config.toml"
if [ ! -f "$CODEX_CONFIG" ]; then
  mkdir -p "${HOME}/.codex"
  printf '[features]\nmulti_agent = true\n' > "$CODEX_CONFIG"
elif ! grep -qE '^\s*multi_agent\s*=\s*true' "$CODEX_CONFIG"; then
  if grep -qE '^\[features\]' "$CODEX_CONFIG"; then
    if [ "$(uname)" = "Darwin" ]; then
      sed -i '' '/^\[features\]/a\'$'\n''multi_agent = true' "$CODEX_CONFIG"
    else
      sed -i '/^\[features\]/a multi_agent = true' "$CODEX_CONFIG"
    fi
  else
    printf '\n[features]\nmulti_agent = true\n' >> "$CODEX_CONFIG"
  fi
fi

STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cat > .claude/review-loop.local.md <<STATE_EOF
---
active: true
phase: task
review_id: ${REVIEW_ID}
started_at: ${STARTED_AT}
---
Parallel multi-phase execution — review all changes made during this session.
STATE_EOF

echo "Review Loop activated (ID: ${REVIEW_ID})."
INIT_SH
```

If this fails (missing Codex, active loop), fix the prerequisite before continuing.

### Step 2: Parse Plan → Build Phase Map

Read the plan file and categorize:

| Category   | Criteria                        | Execution                           |
| ---------- | ------------------------------- | ----------------------------------- |
| Foundation | heading contains `[foundation]` | Sequential, in document order       |
| Parallel   | all other phase headings        | Simultaneous batch after foundation |

Before dispatching, scan all phases for **file ownership** — list which files each phase will touch. This prevents parallel agents from conflicting on the same file.

### Step 3: Execute Foundation Phases (Sequential Gate)

For each `[foundation]` phase, in document order:

1. Dispatch as a subagent using the **Agent Prompt Template** below
2. **Wait for completion** before starting the next foundation phase
3. On failure → run `/cancel-review`, report to user, **STOP**

Do NOT proceed to Step 4 until all foundation phases succeed.

### Step 4: Dispatch Parallel Phases (Single Batch)

Send **all** parallel-phase Agent calls **in one message** so they run concurrently.

Each agent prompt must include (see template below):

- Its specific phase scope
- Summary of what foundation phases produced (files created, APIs exposed)
- File ownership map (which files other parallel phases own — do not touch)

**Wait for ALL agents to complete.**

If **any** agent reports failure or blocker:

1. Cancel the review loop: run `/cancel-review`
2. Report all failures to the user
3. **STOP** — do not proceed to review

### Step 5: Stop — Let the Hook Take Over

All phases succeeded. **Stop here.** Do not wrap up or invoke `finishing-a-development-branch`.

The `review-loop` stop hook will intercept exit, set up the Codex runner, and instruct you to execute it.

### Step 6: Run Codex Review

When the hook fires:

```bash
bash .claude/review-loop-run-codex.sh
```

Wait for Codex to finish. Review file: `reviews/review-<id>.md`.
This covers the **full git diff** — all phases combined.

### Step 7: Address Review Findings

1. Read the review file
2. **If the plan referenced a local PRD copy**, read it with the Read tool and cross-check the combined implementation against the original requirement:
   - Did the implementation cover all PRD requirements across all phases (no missing scope)?
   - Did any phase silently expand beyond PRD scope?
   - Do data shapes / API specs / event-tracking fields match between code and PRD?
   - Note any PRD-vs-code mismatch as an additional finding to address
3. For each finding (from Codex and your own PRD check): agree → fix it; disagree → note why you skip it
4. Critical/high severity first

### Step 8: Complete Development

```
superpowers:finishing-a-development-branch
```

---

## Agent Prompt Template

Use this for **every** subagent dispatch (both foundation and parallel):

```
You are implementing [Phase N: Name] from the plan at [path/to/plan.md].

**Your scope**: Phase N only. Do NOT implement other phases.

**Foundation output** (already completed — do not redo):
[List files created/modified, interfaces/APIs exposed by foundation phases]

**File ownership — do NOT touch these files** (owned by other parallel phases):
[List files other phases will modify]

**Your tasks**:
[Exact task list copied from the phase section in the plan]

**When done**:
- Success: "Phase N complete — [brief summary of files changed]"
- Blocked: "Phase N FAILED: [exact reason]"

Constraints:
- Do NOT commit
- Do NOT run finishing-a-development-branch
- Do NOT modify files outside your scope
```

---

## Rules

- **Never skip Step 1** — no state file = no stop hook = no review
- **Never start parallel phases** until all foundation phases succeed
- **Never proceed to review** after any phase failure — cancel and report
- **Never call `finishing-a-development-branch`** before Codex review completes
- If parallel phases need the same file → restructure them as foundation phases

## Prerequisites

- `codex` CLI: `npm install -g @openai/codex`
- `jq`: `brew install jq`
- OpenAI API key in environment
- `review-loop@hamel-review` plugin installed and enabled
