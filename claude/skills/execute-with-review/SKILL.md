---
name: execute-with-review
description: Execute a superpowers plan with automatic Codex review loop at completion. Use when you want the review-loop stop hook to trigger after superpowers task execution.
---

# Execute With Review Loop

## Overview

This skill bridges `superpowers:executing-plans` with `review-loop` — it initializes the review-loop state file so the stop hook fires automatically when Claude finishes the superpowers task.

**Announce at start:** "I'm using the execute-with-review skill to implement this plan with review."

## The Process

### Step 1: Initialize Review Loop State

Run this bash command to activate the stop hook before any work begins:

```bash
set -e \
&& REVIEW_ID="$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 3 2>/dev/null || head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n')" \
&& mkdir -p .claude reviews \
&& if [ -f .claude/review-loop.local.md ]; then echo "Error: A review loop is already active. Use /cancel-review first." && exit 1; fi \
&& command -v codex >/dev/null 2>&1 || { echo "Error: Codex CLI is not installed. Install: npm install -g @openai/codex"; exit 1; } \
&& CODEX_CONFIG="${HOME}/.codex/config.toml" \
&& if [ ! -f "$CODEX_CONFIG" ]; then mkdir -p "${HOME}/.codex" && printf '[features]\nmulti_agent = true\n' > "$CODEX_CONFIG"; \
   elif ! grep -qE '^\s*multi_agent\s*=\s*true' "$CODEX_CONFIG"; then \
     if grep -qE '^\[features\]' "$CODEX_CONFIG"; then \
       if [ "$(uname)" = "Darwin" ]; then sed -i '' '/^\[features\]/a\'$'\n''multi_agent = true' "$CODEX_CONFIG"; \
       else sed -i '/^\[features\]/a multi_agent = true' "$CODEX_CONFIG"; fi; \
     else printf '\n[features]\nmulti_agent = true\n' >> "$CODEX_CONFIG"; fi; \
   fi \
&& cat > .claude/review-loop.local.md << STATE_EOF
---
active: true
phase: task
review_id: ${REVIEW_ID}
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---
Superpowers task execution — review all changes made during this session.
STATE_EOF
&& echo "Review Loop activated (ID: ${REVIEW_ID}). Stop hook will intercept completion."
```

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
2. For each finding, independently decide if you agree
3. **Agree** → implement the fix
4. **Disagree** → briefly note why you are skipping it
5. Focus on critical and high severity items first

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
