#!/usr/bin/env zsh

# Check if hours argument is provided and is a valid number
if [[ -z "$1" ]] || ! [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Usage: $0 <hours>"
  echo "Example: $0 2.5"
  exit 1
fi

HOURS="$1"
DURATION_SEC=$(awk "BEGIN {printf \"%.0f\", $HOURS * 3600}")
CLEANED_UP=0
CAFFEINATE_PID=""

# Colors (ANSI)
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# Native brightness helper (16 notches total; 0.05s delay ensures macOS registers each press)
set_brightness_notches() {
  local notches=$1
  osascript -e "
    tell application \"System Events\"
      repeat 16 times
        key code 145
        delay 0.05
      end repeat
      repeat $notches times
        key code 144
        delay 0.05
      end repeat
    end tell
  " >/dev/null 2>&1
}

# --- 1. Save Current Volume State ---
PREV_VOL=$(osascript -e "output volume of (get volume settings)")
PREV_MUTE=$(osascript -e "output muted of (get volume settings)")

# --- 2. Define Restore Function ---
cleanup() {
  if [[ "$CLEANED_UP" -eq 1 ]]; then return; fi
  CLEANED_UP=1

  # Restore cursor visibility
  tput cnorm 2>/dev/null

  # Stop caffeinate if still running
  if [[ -n "$CAFFEINATE_PID" ]]; then
    kill "$CAFFEINATE_PID" 2>/dev/null
  fi

  echo "\n\n${YELLOW}↺ Restoring previous system state...${RESET}"

  # Restore exact volume & mute state
  osascript -e "set volume output volume $PREV_VOL"
  if [[ "$PREV_MUTE" == "true" ]]; then
    osascript -e "set volume with output muted"
  else
    osascript -e "set volume without output muted"
  fi

  # Restore brightness to preset 50% (8 of 16 notches)
  set_brightness_notches 14

  echo "${GREEN}✓ Restored (Volume: ${PREV_VOL}%, Brightness: 40%).${RESET}\n"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

# --- 3. Apply Focus Settings ---
osascript -e "set volume output volume 5"
set_brightness_notches 2   # ~10% (2 of 16 notches)

# --- 4. Start Caffeinate in Background ---
caffeinate -dimsu -t "$DURATION_SEC" &
CAFFEINATE_PID=$!

# --- 5. Render Dashboard & Live Countdown ---
END_TIME=$(date -v+${DURATION_SEC}S +"%I:%M %p")
tput civis 2>/dev/null

clear
echo ""
echo "${CYAN}╭──────────────────────────────────────────╮${RESET}"
echo "${CYAN}│${RESET}  ${BOLD}MAC FOCUS MODE${RESET}                 ${GREEN}● ACTIVE${RESET} ${CYAN}│${RESET}"
echo "${CYAN}├──────────────────────────────────────────┤${RESET}"
printf "${CYAN}│${RESET}  ${DIM}Session ends:${RESET}  %-24s ${CYAN}│${RESET}\n" "$END_TIME"
printf "${CYAN}│${RESET}  ${DIM}Brightness:${RESET}    %-24s ${CYAN}│${RESET}\n" "10% (50% on exit)"
printf "${CYAN}│${RESET}  ${DIM}Volume:${RESET}        %-24s ${CYAN}│${RESET}\n" "5% (${PREV_VOL}% on exit)"
printf "${CYAN}│${RESET}  ${DIM}Ext. Display:${RESET}  %-24s ${CYAN}│${RESET}\n" "Manual"
echo "${CYAN}╰──────────────────────────────────────────╯${RESET}"
echo ""
echo "  ${DIM}Press Ctrl+C anytime to exit and restore.${RESET}"
echo ""

REMAINING=$DURATION_SEC
BAR_WIDTH=28

while [[ $REMAINING -gt 0 ]]; do
  H=$((REMAINING / 3600))
  M=$(((REMAINING % 3600) / 60))
  S=$((REMAINING % 60))

  ELAPSED=$((DURATION_SEC - REMAINING))
  FILLED=$((ELAPSED * BAR_WIDTH / DURATION_SEC))
  EMPTY=$((BAR_WIDTH - FILLED))

  BAR_FILL=$(printf "%${FILLED}s" | tr ' ' '#')
  BAR_EMPTY=$(printf "%${EMPTY}s" | tr ' ' '-')

  printf "\r  ${CYAN}[%s%s]${RESET}  ${BOLD}%02d:%02d:%02d${RESET} left " "$BAR_FILL" "$BAR_EMPTY" "$H" "$M" "$S"

  sleep 1
  ((REMAINING--))
done

printf "\r  ${GREEN}[%s]${RESET}  ${BOLD}00:00:00${RESET} done! \n" "$(printf "%${BAR_WIDTH}s" | tr ' ' '#')"
