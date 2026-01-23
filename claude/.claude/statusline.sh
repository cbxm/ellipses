#!/bin/bash

# Read input JSON from stdin
input=$(cat)

# Extract values
dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
usage=$(echo "$input" | jq '.context_window.current_usage')

# Calculate context percentage and build dynamic loading bar
if [ "$usage" != "null" ]; then
  current=$(echo "$input" | jq '.context_window.current_usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  size=$(echo "$input" | jq '.context_window.context_window_size')
  pct=$((current * 100 / size))

  # Build dynamic loading bar (20 segments)
  segments=20
  filled=$((pct * segments / 100))

  # Thresholds: 0-40% = green, 40-65% = yellow, 65-100% = red
  green_max=8    # 40% of 20
  yellow_max=13  # 65% of 20

  # Calculate filled segments per color zone
  green_filled=$((filled <= green_max ? filled : green_max))
  yellow_filled=$((filled > green_max ? (filled <= yellow_max ? filled - green_max : yellow_max - green_max) : 0))
  red_filled=$((filled > yellow_max ? filled - yellow_max : 0))
  empty=$((segments - filled))

  # Build bar
  bar="["
  for ((i=0; i<green_filled; i++)); do
    bar="${bar}\e[32m█\e[0m"
  done
  for ((i=0; i<yellow_filled; i++)); do
    bar="${bar}\e[33m█\e[0m"
  done
  for ((i=0; i<red_filled; i++)); do
    bar="${bar}\e[31m█\e[0m"
  done
  for ((i=0; i<empty; i++)); do
    bar="${bar}\e[90m░\e[0m"
  done
  bar="${bar}]"

  ctx_info=$(printf ' %b \e[37m%d%%\e[0m' "$bar" "$pct")
else
  ctx_info=""
fi

# Get git branch (skip locks for performance)
branch=$(cd "$dir" 2>/dev/null && git --no-optional-locks branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  git_info=$(printf ' 🌿 \e[35m%s\e[0m' "$branch")
else
  git_info=""
fi

# Build and print status line
printf '📁 \e[36m%s\e[0m%s 💭 \e[34m%s\e[0m%s' \
  "$(basename "$dir")" \
  "$git_info" \
  "$model" \
  "$ctx_info"
