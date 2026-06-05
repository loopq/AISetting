#!/usr/bin/env bash
# Source: https://github.com/DurianPancake/claude-code-notification/tree/main/smart-notify-macOS
# 仅在"需要批准/交互"与"任务完成"提醒；终端/IDE 在前台时静默（除非 -Force）
set -uo pipefail

FORCE=0
if [[ "${1:-}" == "-Force" ]]; then FORCE=1; shift; fi

payload="$(cat 2>/dev/null || true)"

IFS=$'\t' read -r hook_event_name message < <(
  printf '%s' "$payload" \
  | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    hook=(d.get("hook_event_name") or "")
    msg=(d.get("message") or d.get("summary") or "")
    hook=str(hook).replace("\t"," ").replace("\n"," ")
    msg=str(msg).replace("\t"," ").replace("\n"," ")
    print(hook + "\t" + msg)
except Exception:
    s=sys.stdin.read().strip()
    s=s.replace("\t"," ").replace("\n"," ")
    print("\t" + s)
'
)

ALERT=0
title="Claude Code"
sound=""

case "$hook_event_name" in
  PermissionRequest|Notification)
    ALERT=1
    title="Claude Code - Permission Required"
    sound="/System/Library/Sounds/Funk.aiff"
    ;;
  Stop)
    ALERT=1
    title="Claude Code - Task Completed"
    sound="/System/Library/Sounds/Bottle.aiff"
    ;;
esac

[[ "$ALERT" -eq 1 ]] || exit 0

FRONT_APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)"
case "$FRONT_APP" in
  "Terminal"|"iTerm2"|"Visual Studio Code"|"Cursor"|"IntelliJ IDEA"|"PyCharm"|"WebStorm")
    if [[ "$FORCE" -eq 0 ]]; then exit 0; fi
    ;;
esac

[[ -z "${message}" ]] && message=" "

afplay "$sound" >/dev/null 2>&1 || printf '\a'

escaped_message="${message//\"/\\\"}"
escaped_title="${title//\"/\\\"}"
osascript -e "display notification \"${escaped_message}\" with title \"${escaped_title}\"" >/dev/null 2>&1 || true

exit 0
