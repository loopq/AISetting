#!/usr/bin/env bash
# Stop hook for execute-with-review-new.
# Blocks session exit while a codex review gate (.claude/codex-review-loop.local.md)
# is active in phase "task", injecting instructions to run the codex-plugin-cc review.
# Allow = exit 0 with no output. Block = print {"decision":"block","reason":...} JSON.
# Escape hatches: delete the state file, or the hook self-disarms after 3 blocks.

set -u

INPUT="$(cat)"

# Resolve project dir from hook input ("cwd"), fallback to $PWD.
CWD=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("cwd") or "")
except Exception:
    print("")
' 2>/dev/null)
[ -n "$CWD" ] || CWD="$PWD"

STATE_FILE="$CWD/.claude/codex-review-loop.local.md"
[ -f "$STATE_FILE" ] || exit 0

grep -qE '^active:[[:space:]]*true' "$STATE_FILE" || exit 0
grep -qE '^phase:[[:space:]]*task' "$STATE_FILE" || exit 0

# Self-disarm after 3 blocks so a broken codex setup can never trap the session.
ATTEMPTS=$(grep -E '^attempts:' "$STATE_FILE" | head -1 | tr -dc '0-9')
ATTEMPTS=${ATTEMPTS:-0}
if [ "${ATTEMPTS:-0}" -ge 3 ]; then
  echo "codex-review-gate: blocked 3 times without completion, allowing exit. State file left at ${STATE_FILE}" >&2
  exit 0
fi
sed -i '' -E "s/^attempts:[[:space:]]*[0-9]+/attempts: $((ATTEMPTS + 1))/" "$STATE_FILE" 2>/dev/null || true

field() { grep -E "^$1:" "$STATE_FILE" | head -1 | sed -E "s/^$1:[[:space:]]*//"; }
REVIEW_ID=$(field review_id)
STARTED_SHA=$(field started_sha)
HOLISTIC=$(field holistic)

COMPANION=$(find "$HOME/.claude/plugins/cache/openai-codex" -name codex-companion.mjs 2>/dev/null | sort -V | tail -1)
if [ -z "$COMPANION" ]; then
  echo "codex-review-gate: codex-plugin-cc not found, allowing exit. Install it and re-run the review manually." >&2
  exit 0
fi

HOLISTIC_LINE=""
if [ "$HOLISTIC" = "true" ]; then
  HOLISTIC_LINE="1b. Holistic pass — also run: node \"${COMPANION}\" adversarial-review --base ${STARTED_SHA} --wait"
fi

REASON="Codex review gate is active (review_id: ${REVIEW_ID}). Do NOT stop yet — complete the review loop now:
1. Ensure all session work is committed, then run with Bash timeout 600000:
   node \"${COMPANION}\" review --base ${STARTED_SHA} --wait
   (If no commits exist after ${STARTED_SHA}, run with --scope working-tree instead of --base.)
${HOLISTIC_LINE}
2. Save the full review stdout verbatim to reviews/review-${REVIEW_ID}.md
3. Address the findings: fix the issues you agree with (critical/high first), briefly note any you skip and why.
4. Delete ${STATE_FILE} to close the gate, then finish.
If the Bash call times out, do NOT re-run: recover with node \"${COMPANION}\" status and result <job-id>.
If codex itself fails, delete ${STATE_FILE} to cancel the gate and tell the user why."

REASON="$REASON" python3 -c 'import json, os; print(json.dumps({"decision": "block", "reason": os.environ["REASON"]}))'
exit 0
