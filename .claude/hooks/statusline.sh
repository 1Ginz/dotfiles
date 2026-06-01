#!/usr/bin/env bash
set +e

INPUT=$(cat 2>/dev/null || echo "{}")

if ! command -v jq >/dev/null 2>&1; then
  echo ""; exit 0
fi

get()     { echo "$INPUT" | jq -r "$1 // \"\"" 2>/dev/null; }
get_num() { echo "$INPUT" | jq -r "$1 // 0"    2>/dev/null; }

# Model
MODEL=$(get '.model.display_name')
[ -z "$MODEL" ] && MODEL=$(get '.model.id')

# Context window
CTX_USED_PCT=$(get_num '.context_window.used_percentage')
CTX_TOKENS_USED=$(get_num '.context_window.total_input_tokens')
CTX_TOKENS_USED_K=$(awk "BEGIN {printf \"%.0f\", $CTX_TOKENS_USED / 1000}")

# Cost
TOTAL_COST=$(get_num '.cost.total_cost_usd')
COST_FMT=$(awk "BEGIN {printf \"%.3f\", $TOTAL_COST}")

# Rate limits
RL_5H=$(get_num '.rate_limits.five_hour.used_percentage')
RL_5H_RESET=$(get_num '.rate_limits.five_hour.resets_at')

# ANSI colors
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'; CYAN='\033[36m'

# Context color
CTX_INT=$(awk "BEGIN {printf \"%.0f\", $CTX_USED_PCT}")
if [ "${CTX_INT:-0}" -ge 85 ]; then
  CTX_COLOR="$RED"; CTX_ICON="🔴"
elif [ "${CTX_INT:-0}" -ge 70 ]; then
  CTX_COLOR="$YELLOW"; CTX_ICON="🟡"
else
  CTX_COLOR="$GREEN"; CTX_ICON="🟢"
fi

# Cost color
if (( $(awk "BEGIN {print ($TOTAL_COST > 5) ? 1 : 0}") )); then
  COST_COLOR="$RED"
elif (( $(awk "BEGIN {print ($TOTAL_COST > 1) ? 1 : 0}") )); then
  COST_COLOR="$YELLOW"
else
  COST_COLOR="$GREEN"
fi

# Rate limit color
RL_5H_INT=$(awk "BEGIN {printf \"%.0f\", $RL_5H}")
if [ "${RL_5H_INT:-0}" -ge 80 ]; then
  RL_COLOR="$RED"
elif [ "${RL_5H_INT:-0}" -ge 50 ]; then
  RL_COLOR="$YELLOW"
else
  RL_COLOR="$GREEN"
fi

# Reset time for 5h limit (human-readable "in Xm" or "in Xh Ym")
RL_RESET_STR=""
if [ -n "$RL_5H_RESET" ] && [ "$RL_5H_RESET" != "0" ]; then
  NOW=$(date +%s)
  SECS_LEFT=$(( RL_5H_RESET - NOW ))
  if [ "$SECS_LEFT" -gt 0 ]; then
    HRS=$(( SECS_LEFT / 3600 ))
    MINS=$(( (SECS_LEFT % 3600) / 60 ))
    if [ "$HRS" -gt 0 ]; then
      RL_RESET_STR=" ${DIM}↺${HRS}h${MINS}m${RESET}"
    else
      RL_RESET_STR=" ${DIM}↺${MINS}m${RESET}"
    fi
  fi
fi

SEP="${DIM} | ${RESET}"

OUT="${CYAN}${BOLD}${MODEL}${RESET}"

# Context: % used + tokens used
if [ "${CTX_INT:-0}" -gt 0 ]; then
  OUT="${OUT}${SEP}${CTX_ICON} ${CTX_COLOR}${CTX_INT}%${RESET} ${DIM}(${CTX_TOKENS_USED_K}k used)${RESET}"
fi

# Session rate limit: % of 5h quota used + reset time
OUT="${OUT}${SEP}${RL_COLOR}${RL_5H_INT}%${RESET}${RL_RESET_STR} ${DIM}quota${RESET}"

# Total session cost
OUT="${OUT}${SEP}${COST_COLOR}\$${COST_FMT}${RESET}"

printf "%b\n" "$OUT"
