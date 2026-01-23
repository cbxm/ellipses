#!/bin/bash
# Core Discord notification script
# Usage: discord-notify.sh <event_type> <project_dir> <details>

set -euo pipefail

# Load DISCORD_WEBHOOK_URL from global .env
if [ -f "$HOME/.claude/.env" ]; then
    source "$HOME/.claude/.env"
fi

if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
    echo "Error: DISCORD_WEBHOOK_URL not set" >&2
    exit 1
fi

EVENT_TYPE="${1:-Unknown}"
PROJECT_DIR="${2:-Unknown}"
DETAILS="${3:-}"

# Extract just project name
PROJECT_NAME="${PROJECT_DIR##*/}"

# Color codes
case "$EVENT_TYPE" in
    "Task Complete")
        COLOR=3066993  # Green
        ;;
    "Input Needed")
        COLOR=15844367  # Gold
        ;;
    "Subagent Complete")
        COLOR=3447003  # Blue
        ;;
    *)
        COLOR=10070709  # Gray
        ;;
esac

# Clean up details - escape quotes and newlines for JSON
CLEAN_DETAILS=$(echo "$DETAILS" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 200)

# Build simple embed
read -r -d '' JSON_PAYLOAD << EOF || true
{
  "embeds": [{
    "title": "$PROJECT_NAME",
    "description": "**$EVENT_TYPE**",
    "color": $COLOR,
    "fields": [
EOF

# Only add details if non-empty
if [ -n "$CLEAN_DETAILS" ]; then
    JSON_PAYLOAD="$JSON_PAYLOAD
      {
        \"name\": \"Info\",
        \"value\": \"$CLEAN_DETAILS\",
        \"inline\": false
      }"
fi

# Close the JSON
JSON_PAYLOAD="$JSON_PAYLOAD
    ]
  }]
}"

# Send to Discord
HTTP_CODE=$(curl -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD" \
     "$DISCORD_WEBHOOK_URL" \
     --silent --output /dev/null --write-out "%{http_code}")

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    exit 0
else
    echo "Discord webhook failed with HTTP $HTTP_CODE" >&2
    exit 1
fi
