#!/bin/bash
input=$(cat)

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

SMART_ZONE=150000
FIVE_H_WINDOW=18000
SEVEN_D_WINDOW=604800

ctx_color_for_pct() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then echo "$RED"
  elif [ "$pct" -ge 70 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}

rate_limit_color() {
  local used_pct=$1 resets_at=$2 window_seconds=$3
  local now=$(date +%s)
  local time_left=$((resets_at - now))
  local elapsed=$((window_seconds - time_left))

  if [ "$time_left" -le 0 ] || [ "$elapsed" -le 0 ]; then
    echo "$GREEN"; return
  fi

  if [ "$used_pct" -ge 90 ]; then
    echo "$RED"; return
  fi

  local projected=$((used_pct * window_seconds / elapsed))

  if [ "$projected" -gt 150 ]; then echo "$RED"
  elif [ "$projected" -gt 100 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}

MODEL=$(echo "$input" | jq -r '.model.display_name')

CTX_WINDOW_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
CTX_USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
INPUT_TOKENS=$(awk "BEGIN {printf \"%.0f\", $CTX_WINDOW_SIZE * $CTX_USED_PCT / 100}")
CTX_PCT=$((INPUT_TOKENS * 100 / SMART_ZONE))
[ "$CTX_PCT" -gt 100 ] && CTX_PCT=100
CTX_COLOR=$(ctx_color_for_pct "$CTX_PCT")

if [ "$INPUT_TOKENS" -ge 1000000 ]; then
  CTX=$(awk "BEGIN {printf \"%.1fM\", $INPUT_TOKENS/1000000}")
elif [ "$INPUT_TOKENS" -ge 1000 ]; then
  CTX=$(awk "BEGIN {printf \"%.1fk\", $INPUT_TOKENS/1000}")
else
  CTX="${INPUT_TOKENS}"
fi

FIVE_H_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_D_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

format_remaining() {
  local resets_at="$1"
  local now=$(date +%s)
  local diff=$((resets_at - now))
  if [ "$diff" -le 0 ]; then
    echo "now"
  elif [ "$diff" -lt 3600 ]; then
    echo "$((diff / 60))m left"
  elif [ "$diff" -lt 86400 ]; then
    echo "$((diff / 3600))h left"
  else
    echo "$((diff / 86400))d left"
  fi
}

FIVE_H=""
if [ -n "$FIVE_H_PCT" ]; then
  PCT_5H=$(printf '%.0f' "$FIVE_H_PCT")
  LIMIT_COLOR_5H=$(rate_limit_color "$PCT_5H" "$FIVE_H_RESET" "$FIVE_H_WINDOW")
  REMAINING_5H=""
  [ -n "$FIVE_H_RESET" ] && REMAINING_5H=" ${DIM}$(format_remaining "$FIVE_H_RESET")${RESET}"
  FIVE_H=" | ${LIMIT_COLOR_5H}${PCT_5H}%${RESET}${REMAINING_5H}"
fi

SEVEN_D=""
if [ -n "$SEVEN_D_PCT" ]; then
  PCT_7D=$(printf '%.0f' "$SEVEN_D_PCT")
  LIMIT_COLOR_7D=$(rate_limit_color "$PCT_7D" "$SEVEN_D_RESET" "$SEVEN_D_WINDOW")
  REMAINING_7D=""
  [ -n "$SEVEN_D_RESET" ] && REMAINING_7D=" ${DIM}$(format_remaining "$SEVEN_D_RESET")${RESET}"
  SEVEN_D=" | ${LIMIT_COLOR_7D}${PCT_7D}%${RESET}${REMAINING_7D}"
fi

echo -e "${CYAN}${MODEL}${RESET} | ${CTX_COLOR}${CTX}${RESET}${FIVE_H}${SEVEN_D}"
