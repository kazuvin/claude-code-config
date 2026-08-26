#!/bin/bash
# Claude Code statusLine
#
#   📁 ~/.claude  🌿 main +23 ~5
#   🤖 Opus 5 (1M context) · high · think · 💰$7.33
#   🧠 context ███▎░░░░░░░░░░░░  21%  792k left
#   ⏳ 5-hour  █████▌░░░░░░░░░░  35%  ↻2h28m  08/26 14:20 JST
#   📅 weekly  ▊░░░░░░░░░░░░░░░   5%  ↻4d18h  08/31 06:00 JST
#
# Two header rows plus one row per budget. Every row reads the same way: the bar and
# percent are what has been SPENT, the dim tail is what is LEFT — tokens for the
# context window; for a limit, the countdown and the wall-clock reset time.
#
# Stacked rather than packed onto one line so nothing wraps: a single-line
# layout ran 82 columns and the trailing gauge broke apart on an 80-column
# terminal.
#
# Palette avoids green: the daltonized themes exist for color vision deficiency,
# and green/red plus green/yellow are exactly the pairs that collapse under it.
# Rows are cyan / blue / magenta, escalating to yellow at 70% and red at 90%.
#
# Every emoji here is East-Asian-Wide, so each occupies exactly two columns and
# the label column stays flush. Do not swap in a narrow or ambiguous-width one
# (⏱ U+23F1 is EAW=N, for instance) — it shifts every bar on that row.
#
# Field names follow the documented statusLine stdin schema:
#   https://code.claude.com/docs/en/statusline
#
# `rate_limits` exists only for Claude.ai Pro/Max subscribers, and only after the
# session's first API response — an absent window drops its whole row.
# Targets bash 3.2 (the /bin/bash macOS ships): no mapfile, no assoc arrays.

input=$(cat)

CYAN=$'\033[36m'; BLUE=$'\033[34m'; MAGENTA=$'\033[35m'
YELLOW=$'\033[33m'; RED=$'\033[31m'
DIM=$'\033[2m'; GREY=$'\033[90m'; RESET=$'\033[0m'

WARN_AT=70                    # bar turns yellow here
CRIT_AT=90                    # ...and red here
BAR_LEN=16                    # gauge width in cells; 16 cells x 8 eighths = 128 steps
LABEL_W=7                     # label column, keeps the bars flush
RESET_TZ='Asia/Tokyo'         # timezone the reset clock is rendered in
RESET_FMT='%m/%d %H:%M %Z'    # zero-padded so the column never shifts

# left-aligned partial blocks, indexed by eighths remaining (0 is unused)
PARTIAL=('' '▏' '▎' '▍' '▌' '▋' '▊' '▉')

# ── one jq pass, one field per line (empty lines are preserved by `read`) ────
{
  read -r MODEL_NAME
  read -r EFFORT
  read -r THINKING
  read -r FAST
  read -r CUR_DIR
  read -r CTX_PCT
  read -r CTX_SIZE
  read -r CTX_IN_TOK
  read -r H5_PCT
  read -r H5_RESET
  read -r D7_PCT
  read -r D7_RESET
  read -r COST
  read -r SESSION_ID
} < <(printf '%s' "$input" | jq -r '
  def opt: if . == null then "" else (floor|tostring) end;
  [ (.model.display_name // "")
  , (.effort.level // "")
  , ((.thinking.enabled // false) | tostring)
  , ((.fast_mode // false) | tostring)
  , (.workspace.current_dir // .cwd // "")
  , ((.context_window.used_percentage // 0) | floor | tostring)
  , ((.context_window.context_window_size // 0) | tostring)
  , ((.context_window.total_input_tokens // 0) | tostring)
  , (.rate_limits.five_hour.used_percentage  | opt)
  , (.rate_limits.five_hour.resets_at        | opt)
  , (.rate_limits.seven_day.used_percentage  | opt)
  , (.rate_limits.seven_day.resets_at        | opt)
  , ((.cost.total_cost_usd // 0) | if . >= 0.01 then (. * 100 | round / 100 | tostring) else "" end)
  , (.session_id // "")
  ] | .[]' 2>/dev/null)

# ── helpers ─────────────────────────────────────────────────────────────────

# 800476 -> 800k ; 1500000 -> 1.5M
fmt_tokens() {
  local t=${1:-0}
  if   [ "$t" -ge 1000000 ]; then printf '%d.%dM' $((t / 1000000)) $(((t % 1000000) / 100000))
  elif [ "$t" -ge 1000 ];    then printf '%dk' $((t / 1000))
  else                            printf '%d' "$t"
  fi
}

# seconds -> 4d18h / 2h28m / 12m / <1m
fmt_dur() {
  local s=${1:-0} d h m
  [ "$s" -le 0 ] && { printf 'now'; return; }
  d=$((s / 86400)); h=$(((s % 86400) / 3600)); m=$(((s % 3600) / 60))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
  else                      printf '<1m'
  fi
}

# epoch -> "↻2h28m  08/26 14:20 JST", empty when the field is absent.
# BSD `date -r` first (this is macOS); GNU `date -d @` is the Linux fallback.
# Both report failure on stderr only, so the || chain cannot corrupt the value.
reset_at() {
  local e=$1 when
  [ -z "$e" ] && return
  when=$(TZ=$RESET_TZ date -r "$e" "+$RESET_FMT" 2>/dev/null \
      || TZ=$RESET_TZ date -d "@$e" "+$RESET_FMT" 2>/dev/null)
  # countdown padded to 6 so the wall-clock column lines up across rows
  printf '↻%-6s %s' "$(fmt_dur $((e - $(date +%s))))" "$when"
}

# row <emoji> <label> <base-color> <used-pct> <tail>
# The bar keeps its row's identity color until it crosses a threshold, so the
# rows stay tellable apart while a warning still overrides everything.
# The emoji sits outside the padded label: printf pads by characters, not by
# display columns, so a double-width glyph inside the field would skew it.
row() {
  local emoji=$1 label=$2 color=$3 pct=${4:-0} tail=$5
  local eighths full rem fill='' track='' i

  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -ge "$WARN_AT" ] && color=$YELLOW
  [ "$pct" -ge "$CRIT_AT" ] && color=$RED

  # 1/8-cell resolution, so the bar creeps instead of stepping a whole block
  eighths=$((pct * BAR_LEN * 8 / 100))
  full=$((eighths / 8)); rem=$((eighths % 8))
  for ((i = 0; i < full; i++)); do fill+='█'; done
  if [ "$full" -lt "$BAR_LEN" ] && [ "$rem" -gt 0 ]; then
    fill+="${PARTIAL[$rem]}"
    full=$((full + 1))
  fi
  for ((i = full; i < BAR_LEN; i++)); do track+='░'; done

  # %3d keeps the percent column from jittering between 5%, 35% and 100%
  printf '%s %s%-*s%s %s%s%s%s%s %s%3d%%%s' \
    "$emoji" \
    "$DIM" "$LABEL_W" "$label" "$RESET" \
    "$color" "$fill" "$GREY" "$track" "$RESET" \
    "$color" "$pct" "$RESET"
  [ -n "$tail" ] && printf '  %s%s%s' "$DIM" "$tail" "$RESET"
  printf '\n'
}

# ── git, cached per session for 5s (status calls are slow in big repos) ─────
CACHE_FILE="${TMPDIR:-/tmp}/claude-statusline-git-${SESSION_ID:-nosession}"

cache_is_stale() {
  [ ! -f "$CACHE_FILE" ] && return 0
  # Linux form first: on Linux the macOS form prints to stdout before failing,
  # and that output would be captured and break the arithmetic.
  local mtime
  mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null \
       || stat -f %m "$CACHE_FILE" 2>/dev/null \
       || echo 0)
  [ $(($(date +%s) - mtime)) -gt 5 ]
}

if cache_is_stale; then
  G="git -C ${CUR_DIR:-.}"
  if $G rev-parse --git-dir >/dev/null 2>&1; then
    b=$($G branch --show-current 2>/dev/null)
    # detached HEAD has no branch name — fall back to the short sha
    [ -z "$b" ] && b=$($G rev-parse --short HEAD 2>/dev/null)
    s=$($G diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    m=$($G diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    printf '%s|%s|%s\n' "$b" "$s" "$m" > "$CACHE_FILE"
  else
    printf '||\n' > "$CACHE_FILE"
  fi
fi
IFS='|' read -r BRANCH STAGED MODIFIED < "$CACHE_FILE"

# ── header rows: where you are, then what you are running ──────────────────
# Split across two rows rather than one: with the emoji and a real project path
# a single header ran 84+ columns and wrapped — the same failure the gauges were
# stacked to avoid.
HOME_TILDE="~"

# deep trees collapse to their last two components so this row stays bounded
fmt_path() {
  local p=${1/#$HOME/$HOME_TILDE} base parent
  if [ ${#p} -gt 28 ]; then
    base=${p##*/}; parent=${p%/*}; parent=${parent##*/}
    p="…/${parent}/${base}"
  fi
  printf '%s' "$p"
}

WHERE=""
[ -n "$CUR_DIR" ] && WHERE="📁 ${CYAN}$(fmt_path "$CUR_DIR")${RESET}"

if [ -n "$BRANCH" ]; then
  [ -n "$WHERE" ] && WHERE="$WHERE  "
  WHERE="${WHERE}🌿 ${BLUE}${BRANCH}${RESET}"
  # staged vs unstaged, told apart without green
  [ "${STAGED:-0}" -gt 0 ]   && WHERE="$WHERE ${CYAN}+${STAGED}${RESET}"
  [ "${MODIFIED:-0}" -gt 0 ] && WHERE="$WHERE ${YELLOW}~${MODIFIED}${RESET}"
fi
[ -n "$WHERE" ] && printf '%s\n' "$WHERE"

WHAT=""
if [ -n "$MODEL_NAME" ]; then
  WHAT="🤖 ${MAGENTA}${MODEL_NAME}${RESET}"
  [ -n "$EFFORT" ]       && WHAT="$WHAT ${DIM}· ${EFFORT}${RESET}"
  [ "$THINKING" = true ] && WHAT="$WHAT ${DIM}· think${RESET}"
  [ "$FAST" = true ]     && WHAT="$WHAT ${DIM}· ⚡fast${RESET}"
fi

# COST is pre-filtered in jq: empty below $0.01. Client-side estimate, not a bill.
if [ -n "$COST" ]; then
  [ -n "$WHAT" ] && WHAT="$WHAT ${DIM}·${RESET} "
  WHAT="${WHAT}${DIM}💰\$$(printf '%.2f' "$COST")${RESET}"
fi
[ -n "$WHAT" ] && printf '%s\n' "$WHAT"

# ── one row per budget ──────────────────────────────────────────────────────
ctx_left=''
if [ "${CTX_SIZE:-0}" -gt 0 ]; then
  left=$((CTX_SIZE - ${CTX_IN_TOK:-0}))
  [ "$left" -lt 0 ] && left=0
  ctx_left="$(fmt_tokens "$left") left"
fi
row '🧠' 'context' "$CYAN" "${CTX_PCT:-0}" "$ctx_left"

[ -n "$H5_PCT" ] && row '⏳' '5-hour' "$BLUE"    "$H5_PCT" "$(reset_at "$H5_RESET")"
[ -n "$D7_PCT" ] && row '📅' 'weekly' "$MAGENTA" "$D7_PCT" "$(reset_at "$D7_RESET")"

# Must be the last statement, and must be unconditional. Claude Code discards
# the whole status line when the command exits non-zero, and every row above is
# a `[ -n ... ] && row ...` guard — so a missing window would otherwise leave a
# false test as the script's exit status and blank the status line entirely.
# That is exactly what happens in a fresh session, where `rate_limits` does not
# arrive until the first API response.
exit 0
