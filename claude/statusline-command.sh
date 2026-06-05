#!/usr/bin/env bash
# Claude Code statusLine — 2-line format
# Line 1: [Model (context size)] | dir | ● session_duration
# Line 2: Context bar% | Usage pct% (resets in Xh Ym) | Weekly bar% (resets in Xd Yh)

input=$(cat)

# ---------------------------------------------------------------------------
# Raw data from JSON
# ---------------------------------------------------------------------------
cwd=$(echo "$input"           | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input"         | jq -r '.model.display_name // empty')
model_id=$(echo "$input"      | jq -r '.model.id // empty')
ctx_size=$(echo "$input"      | jq -r '.context_window.context_window_size // empty')
used_pct=$(echo "$input"      | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

five_pct=$(echo "$input"        | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input"     | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input"       | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_resets=$(echo "$input"    | jq -r '.rate_limits.seven_day.resets_at // empty')

# ---------------------------------------------------------------------------
# Directory: basename only
# ---------------------------------------------------------------------------
if [ -n "$cwd" ]; then
    dir=$(basename "$cwd")
else
    dir=$(basename "$(pwd)")
fi

# ---------------------------------------------------------------------------
# Model display name — strip "Claude " prefix for compactness, keep rest
# e.g. "Claude 3.5 Sonnet" -> "Sonnet 3.5", "Claude Opus 4" -> "Opus 4"
# We keep the display_name as-is but strip leading "Claude "
# ---------------------------------------------------------------------------
if [ -n "$model" ]; then
    short_model="${model#Claude }"
else
    short_model="Unknown"
fi

# ---------------------------------------------------------------------------
# Context window size — convert to human-readable (K / M)
# ---------------------------------------------------------------------------
ctx_label=""
if [ -n "$ctx_size" ] && [ "$ctx_size" != "null" ]; then
    if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
        m=$(( ctx_size / 1000000 ))
        ctx_label="${m}M context"
    elif [ "$ctx_size" -ge 1000 ] 2>/dev/null; then
        k=$(( ctx_size / 1000 ))
        ctx_label="${k}K context"
    else
        ctx_label="${ctx_size} context"
    fi
fi

# ---------------------------------------------------------------------------
# Session duration — derive from transcript_path mtime vs now (best effort)
# If unavailable, fall back to omitting the duration field.
# ---------------------------------------------------------------------------
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
session_duration=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    now=$(date +%s)
    if stat -f "%m" "$transcript" >/dev/null 2>&1; then
        # macOS stat
        mtime=$(stat -f "%B" "$transcript" 2>/dev/null || stat -f "%m" "$transcript" 2>/dev/null)
    else
        mtime=$(stat -c "%W" "$transcript" 2>/dev/null)
        [ "$mtime" = "0" ] || [ -z "$mtime" ] && mtime=$(stat -c "%Y" "$transcript" 2>/dev/null)
    fi
    if [ -n "$mtime" ] && [ "$mtime" -gt 0 ] 2>/dev/null; then
        elapsed=$(( now - mtime ))
        [ "$elapsed" -lt 0 ] && elapsed=0
        hours=$(( elapsed / 3600 ))
        minutes=$(( (elapsed % 3600) / 60 ))
        session_duration="${hours}h ${minutes}m"
    fi
fi

# ---------------------------------------------------------------------------
# Progress bar helper: make_bar <filled_count> <total=10> using ■ and ░
# ---------------------------------------------------------------------------
make_bar() {
    local filled=$1
    local total=${2:-10}
    local bar=""
    local i
    for (( i=0; i<total; i++ )); do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}■"
        else
            bar="${bar}░"
        fi
    done
    printf "%s" "$bar"
}

# ---------------------------------------------------------------------------
# Time-until helper: seconds -> "Xd Yh" or "Xh Ym"
# ---------------------------------------------------------------------------
time_until() {
    local resets_at=$1
    local now
    now=$(date +%s)
    local diff=$(( resets_at - now ))
    [ "$diff" -lt 0 ] && diff=0
    local days=$(( diff / 86400 ))
    local hours=$(( (diff % 86400) / 3600 ))
    local mins=$(( (diff % 3600) / 60 ))
    if [ "$days" -gt 0 ]; then
        printf "%dd %dh" "$days" "$hours"
    else
        printf "%dh %dm" "$hours" "$mins"
    fi
}

# ---------------------------------------------------------------------------
# ANSI colors
# ---------------------------------------------------------------------------
RESET='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[0;37m'

# ---------------------------------------------------------------------------
# LINE 1: [Model (ctx)] | dir | ● Xh Ym
# ---------------------------------------------------------------------------
line1=""

# Model + context bracket
bracket_content="${short_model}"
[ -n "$ctx_label" ] && bracket_content="${bracket_content} (${ctx_label})"
line1="${line1}${BOLD}[${bracket_content}]${RESET}"

# Separator + dir
line1="${line1} ${DIM}|${RESET} ${MAGENTA}${dir}${RESET}"

# Dot + session duration
line1="${line1} ${DIM}|${RESET} ${GREEN}●${RESET}"
if [ -n "$session_duration" ]; then
    line1="${line1} ${WHITE}${session_duration}${RESET}"
fi

# ---------------------------------------------------------------------------
# LINE 2: Context bar | Usage pct (resets in Xh Ym) | Weekly bar (resets in Xd Yh)
# ---------------------------------------------------------------------------
line2=""

# --- Context segment ---
ctx_seg=""
if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    filled=$(( used_int / 10 ))
    [ "$filled" -gt 10 ] && filled=10
    bar=$(make_bar "$filled" 10)
    ctx_seg="${CYAN}Context${RESET} ${DIM}${bar}${RESET} ${used_int}%"
fi

# --- 5-hour Usage segment ---
usage_seg=""
if [ -n "$five_pct" ]; then
    five_int=$(printf "%.0f" "$five_pct")
    usage_seg="${YELLOW}Usage${RESET}    ${five_int}%"
    if [ -n "$five_resets" ] && [ "$five_resets" != "null" ]; then
        time_str=$(time_until "$five_resets")
        usage_seg="${usage_seg} (resets in ${time_str})"
    fi
fi

# --- 7-day Weekly segment ---
weekly_seg=""
if [ -n "$seven_pct" ]; then
    seven_int=$(printf "%.0f" "$seven_pct")
    filled=$(( seven_int / 10 ))
    [ "$filled" -gt 10 ] && filled=10
    bar=$(make_bar "$filled" 10)
    weekly_seg="${BLUE}Weekly${RESET} ${DIM}${bar}${RESET} ${seven_int}%"
    if [ -n "$seven_resets" ] && [ "$seven_resets" != "null" ]; then
        time_str=$(time_until "$seven_resets")
        weekly_seg="${weekly_seg} (resets in ${time_str})"
    fi
fi

# Assemble line2 with separators (only include segments that have data)
sep=" ${DIM}|${RESET} "
first=1
for seg in "$ctx_seg" "$usage_seg" "$weekly_seg"; do
    [ -z "$seg" ] && continue
    if [ "$first" -eq 1 ]; then
        line2="${seg}"
        first=0
    else
        line2="${line2}${sep}${seg}"
    fi
done

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
printf "%b\n" "$line1"
[ -n "$line2" ] && printf "%b\n" "$line2"
