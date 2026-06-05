---
name: plan-review-cc
description: Use when the user says "/plan-review-cc" and provides a plan file path that needs critical review and iterative refinement, or when /plan-review is requested but Codex is unavailable (quota exhausted, CLI errors). Same adversarial plan-iteration workflow as plan-review, but the reviewer is a clean-context Claude Code subagent instead of Codex.
---

# Plan Review Skill (Claude Code Subagent Reviewer)

## Purpose

When the user runs `/plan-review-cc {plan-file-path}`, start the "adversarial plan iteration" workflow:
1. I (Claude Code, the orchestrator) dispatch a **clean-context subagent** to perform a critical review of the specified plan.
2. I read the review produced by the subagent and evaluate whether its suggestions are sound.
3. I revise the plan based on valid suggestions and write changes back to the original plan file.
4. If the review status is `NEEDS_REVISION`, I automatically dispatch another review round.
5. Repeat until consensus is reached as `MOSTLY_GOOD` or `APPROVED`.

The mechanism is identical to the `plan-review` skill; the only difference is the reviewer: a fresh Claude Code subagent (Agent tool, `subagent_type: general-purpose`) instead of Codex.

## Usage

```
/plan-review-cc plans/my-feature-plan.md
```

## Clean-Context Guarantee

The whole point of the subagent is an independent reviewer untainted by my context:

- The subagent prompt must contain **only**: the review instruction template below with file paths substituted. Never paste the plan content, my summary of it, my design rationale, or any conversation history into the prompt — the subagent reads all files itself with the Read tool.
- Never "pre-answer" issues in the prompt or hint at what I think is fine.

## Reviewer Continuity Across Rounds

Round 1: spawn a new agent via the Agent tool. Save the agent's ID/name from the result.

Round 2+: continue the **same reviewer agent** via SendMessage so it remembers its own review history (the equivalent of Codex `--session <id>`). If the agent is no longer reachable, spawn a fresh one — the review file's previous rounds provide continuity, and the instruction template already requires tracking prior issues.

## My Workflow (Claude Code)

### Step 0: Ensure Local PRD Available

Before dispatching the reviewer, guarantee that the PRD (if any) is on disk so the subagent can read it without MCP access.

1. Read the plan file
2. Look near the top for one or more lines `**PRD**: [飞书原文](feishu_url) · [本地副本](local_path)` — a plan may reference multiple PRDs; process every PRD line. `local_path` may be a `file:///` absolute URL: strip the `file://` prefix before passing it to Read or to the reviewer.
3. Branches (per PRD line):
   - **Both links present, local file exists** → continue to Step 1
   - **Both links present, local file missing** → use `lark-doc` skill (`lark-cli docs +fetch --api-version v2 --doc-format markdown --doc <feishu_url> --as user`), save `data.document.content` to `local_path` with frontmatter (`title`, `feishu_url`, `doc_id`, `fetched_at` in ISO 8601 UTC), then continue
   - **Only Feishu URL present** (no local副本 link) → fetch via `lark-doc` skill, save to `docs/feishu-prds/{YYYY-MM-DD}-{topic}.md`, then update plan header to add the `· [本地副本](...)` segment, then continue
   - **No PRD reference at all** → continue without PRD; review will be plan-only and the reviewer will note this gap

See the `飞书 PRD 持久化` section in CLAUDE.md / AGENTS.md for naming, frontmatter, and dedup rules.

### Step 1: Determine the Review File

Derive the review file path from the plan file path:
- Rule: replace the last `plans/` directory segment with `reviews/`, **keeping any directory prefix**, and append `-review` to the file name
- `plans/auth-refactor.md` → `reviews/auth-refactor-review.md`
- `docs/plans/2026-06-05-foo.md` → `docs/reviews/2026-06-05-foo-review.md`（本仓惯例即此形态）

If the review file already exists, this is not the first round, so the reviewer must track the resolution status of issues from the previous round.

### Step 2: Dispatch the Reviewer Subagent

**Round 1**: use the Agent tool (`subagent_type: general-purpose`) with exactly the following instruction, substituting `{plan-file-path}` and `{review-file-path}` with absolute paths. Also substitute today's date for `{YYYY-MM-DD}` in the format template — the clean-context subagent has no reliable date source of its own.

**Round 2+**: send the same reviewer agent (SendMessage) a short continuation instead of re-pasting the template — e.g. "Execute review Round {N} (date: {YYYY-MM-DD}): the plan at {plan-file-path} has been revised. Re-read it, re-read {review-file-path}, track every previous issue's resolution status in the Previous Round Tracking table, and append Round {N} in the same format with a fresh Consensus Status." Only fall back to a fresh agent + full template if the reviewer agent is no longer reachable (then it MUST read {review-file-path} in full before producing its round).

```
Read the contents of {plan-file-path} and review it critically as an independent third-party reviewer.

PRD context:
- Look near the top of the plan for a line `**PRD**: [飞书原文](url) · [本地副本](path)`.
- If a local copy path is present, **read it with the Read tool** and use it to validate the plan against the original requirement.
- Cross-check the plan covers all PRD requirements (no missing scope), does not silently expand beyond PRD scope, and that data shapes / API specs / event-tracking fields match between plan and PRD.
- If only a Feishu URL is given (no local copy), note "PRD validation skipped — no local copy" in the Round summary.

Requirements:
- Raise at least 10 concrete and actionable improvement points
- Each issue must include: issue description + exact location/reference in the plan + improvement suggestion
- Use severity levels: Critical > High > Medium > Low > Suggestion
- You may inspect the codebase with Read/Grep/Glob to verify the plan's claims about existing code (file paths, line numbers, API signatures) — flag any mismatch as an issue
- If {review-file-path} already exists, read it first and track the resolution status of previous issues in the new round

Analysis dimensions, choosing the relevant ones based on the plan type:
- PRD alignment: completeness vs PRD requirements, scope creep, spec-level mismatches (when local PRD copy is available)
- Architectural soundness: overdesign vs underdesign, module boundaries, single responsibility
- Technology choices: rationale, alternatives, compatibility with the existing project stack
- Completeness: missing scenarios, overlooked edge cases, dependency and impact scope
- Feasibility: implementation complexity, performance risks, migration and compatibility concerns
- Engineering quality: whether it follows the Code Quality Hard Limits in `CLAUDE.md`
- User experience: interaction flow, error/loading states, i18n when relevant
- Security: authentication, authorization, data validation when relevant

Append the current review round to {review-file-path}, creating the file if it does not exist.
Separate rounds with `---` and append new rounds at the end of the file. Use this format:

---

## Round {N} — {YYYY-MM-DD}

### Overall Assessment
{2-3 sentence overall assessment}
**Rating**: {X}/10

### Previous Round Tracking (R2+ only)
| # | Issue | Status | Notes |
|---|-------|--------|-------|

### Issues
#### Issue 1 ({severity}): {title}
**Location**: {location in the plan}
{issue description}
**Suggestion**: {improvement suggestion}
... (at least 10 issues)

### Positive Aspects
- ...

### Summary
{Top 3 key issues}
**Consensus Status**: NEEDS_REVISION / MOSTLY_GOOD / APPROVED

Key principle: be a critical reviewer, not a yes-man. Every issue must be specific enough that someone knows how to revise the plan.

When done, reply with only: the round number, the rating, the Consensus Status, and the top 3 issue titles.
```

When the review file is created for the first time, add this header at the top (orchestrator's responsibility, not the reviewer's):

```markdown
# Plan Review: {plan title}

**Plan File**: {plan-file-path}
**Reviewer**: Claude Code subagent (clean context)
```

### Step 3: Read the Review and Revise the Plan

After the reviewer finishes, I read the latest review round in the review file:

1. **Evaluate each issue** raised by the reviewer one by one.
2. **Adopt valid suggestions** and revise the plan file.
3. If rejecting an unreasonable suggestion, optionally note the reason briefly in the plan.
4. **Update the original plan file directly** instead of creating a new file.

### Step 4: Decide Whether to Continue Iterating

Use the `Consensus Status` provided by the reviewer:

| Status | My Action |
|--------|---------|
| `NEEDS_REVISION` | Revise the plan, then automatically dispatch another review round and return to Step 2 |
| `MOSTLY_GOOD` | Revise the plan, then tell the user the plan is mostly mature and ask whether another review round is needed |
| `APPROVED` | Tell the user the plan has passed review and is ready for implementation |

### Step 5: Wrap Up

After the iteration is complete, report the following to the user:
- How many review rounds were completed
- Which major areas were improved
- The final plan file path
- The review log file path

## File Convention

- One review file per plan: `reviews/{topic}-review.md`
- `{topic}` is the plan file name without `.md`
- Append all rounds to the same file and separate them with `---`
- Example: `plans/auth-refactor.md` -> `reviews/auth-refactor-review.md`
