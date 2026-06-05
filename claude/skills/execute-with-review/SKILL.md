---
name: execute-with-review
description: Execute a superpowers plan with automatic Codex review loop at completion. Use when you want the review-loop stop hook to trigger after superpowers task execution.
---

# Execute With Review Loop

## Overview

This skill bridges `superpowers:executing-plans` with `review-loop` — it initializes the review-loop state file so the stop hook fires automatically when Claude finishes the superpowers task.

**Announce at start:** "I'm using the execute-with-review skill to implement this plan with review."

## The Process

### Step 0: Ensure Local PRD Available

Before activating the review loop, make sure any PRD referenced by the plan is persisted locally so Codex can read it during review without needing MCP access.

1. Read the plan file you are about to execute
2. Look near the top for `**PRD**: [飞书原文](feishu_url) · [本地副本](local_path)`
3. Branches:
   - **Both links present, local file exists** → continue to Step 1
   - **Both links present, local file missing** → use `lark-doc` skill (`lark-cli docs +fetch --api-version v2 --doc-format markdown --doc <feishu_url> --as user`), save `data.document.content` to `local_path` with frontmatter (`title`, `feishu_url`, `doc_id`, `fetched_at` in ISO 8601 UTC), then continue
   - **Only Feishu URL present** (no 本地副本 link) → fetch via `lark-doc` skill, save to `docs/feishu-prds/{YYYY-MM-DD}-{topic}.md`, update plan header to add the `· [本地副本](...)` segment, then continue
   - **No PRD reference at all** → continue without PRD; the post-execution Codex review will be code-only

This guarantees that when you address review findings in Step 5, the local PRD is present for cross-checking. See `飞书 PRD 持久化` in CLAUDE.md / AGENTS.md for naming and frontmatter rules.

### Step 1: Initialize Review Loop State

Run this bash command to activate the stop hook before any work begins:

```bash
bash <<'INIT_SH'
set -e

REVIEW_ID="$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 3 2>/dev/null || head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n')"
mkdir -p .claude reviews

if [ -f .claude/review-loop.local.md ]; then
  echo "Error: A review loop is already active. Use /cancel-review first." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: Codex CLI is not installed. Install: npm install -g @openai/codex" >&2
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

# Record HEAD at session start — diff agent will scope review to commits made AFTER this SHA,
# so it cannot drag in unrelated upstream commits already merged before the session began.
STARTED_SHA="$(git rev-parse HEAD 2>/dev/null || echo "")"

# Detect base branch the current work will merge into (secondary fallback when started_sha unusable).
# Override with BASE_BRANCH=<name> when the project's main branch is not main/master/origin/HEAD
# (e.g. this repo uses 1.1.08 — see git status "Main branch" line).
BASE_BRANCH="${BASE_BRANCH:-}"
if [ -z "$BASE_BRANCH" ]; then
  if git symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1; then
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
  elif git rev-parse --verify origin/main >/dev/null 2>&1; then
    BASE_BRANCH=main
  elif git rev-parse --verify origin/master >/dev/null 2>&1; then
    BASE_BRANCH=master
  fi
fi

# Default holistic=false: this skill is for focused implementation, not project-wide audit.
# Set HOLISTIC=true to additionally run the Agent 2 holistic review.
HOLISTIC="${HOLISTIC:-false}"

cat > .claude/review-loop.local.md <<STATE_EOF
---
active: true
phase: task
review_id: ${REVIEW_ID}
started_at: ${STARTED_AT}
started_sha: ${STARTED_SHA}
base_branch: ${BASE_BRANCH}
holistic: ${HOLISTIC}
---
Superpowers task execution — review all changes made during this session.
STATE_EOF

echo "Review Loop activated (ID: ${REVIEW_ID}, started_sha=${STARTED_SHA:0:8}, base_branch=${BASE_BRANCH:-<none>}, holistic=${HOLISTIC}). Stop hook will intercept completion."
INIT_SH
```

**Optional env vars** to override defaults (set before running the init block):
- `BASE_BRANCH=<branch>` — when the project's main branch is not `main`/`master`/`origin/HEAD`. Check the git status header for `Main branch (you will usually use this for PRs)` and use that name. Example: `BASE_BRANCH=1.1.08 bash <<'INIT_SH' ... INIT_SH`. Without this, Codex's diff agent may scan upstream commits unrelated to this session.
- `HOLISTIC=true` — additionally run the project-wide structural review (Agent 2). Default is off because this skill is meant for focused, narrow implementations where Holistic findings are noise.

If the command succeeds, proceed. If it fails (e.g., Codex not installed), stop and fix the prerequisite.

### Step 2: Execute the Plan

Use `superpowers:executing-plans` to load and execute the plan. Follow that skill's full process:
- Load and review the plan critically
- Execute all tasks
- Run all verifications
- Do NOT invoke `superpowers:finishing-a-development-branch` yet — the review loop must run first

### Step 3: Stop — Let the Hook Take Over

When all plan tasks are complete and verified, **stop**. Do not attempt to exit or wrap up manually.

The `review-loop` stop hook will automatically:
1. Detect `phase: task` in `.claude/review-loop.local.md`
2. Prepare the Codex multi-agent runner script
3. Block Claude's exit with instructions to run the review
4. Prompt Claude to execute `bash .claude/review-loop-run-codex.sh`

### Step 4: Run the Codex Review

When the stop hook blocks exit and instructs you to run the Codex script, execute it with a long timeout (reviews can take several minutes):

```bash
bash .claude/review-loop-run-codex.sh
```

Wait for all Codex agents to complete. The review will be written to `reviews/review-<id>.md`.

### Step 5: Address Review Findings

1. Read the review file
2. **If the plan referenced a local PRD copy**, read it with the Read tool and cross-check the implementation against the original requirement:
   - Did the implementation cover all PRD requirements (no missing scope)?
   - Did it silently expand beyond PRD scope?
   - Do data shapes / API specs / event-tracking fields match between code and PRD?
   - Note any PRD-vs-code mismatch as an additional finding to address before proceeding
3. For each finding (from Codex and your own PRD check), independently decide if you agree
4. **Agree** → implement the fix
5. **Disagree** → briefly note why you are skipping it
6. Focus on critical and high severity items first

### Step 6: Complete Development

After addressing the review, the stop hook will allow exit. Now invoke:
- `superpowers:finishing-a-development-branch` to finalize the work

## Rules

- Do NOT skip Step 1 — without the state file, the stop hook won't fire
- Do NOT call `finishing-a-development-branch` before the Codex review completes
- If a review loop is already active (`review-loop.local.md` exists), run `/cancel-review` first
- Stop and ask if Codex fails or the review file is not produced

## Prerequisites

- `codex` CLI installed: `npm install -g @openai/codex`
- `jq` installed: `brew install jq`
- OpenAI API key set in environment
- `review-loop@hamel-review` plugin installed and enabled
