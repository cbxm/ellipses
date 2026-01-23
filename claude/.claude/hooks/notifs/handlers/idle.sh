#!/bin/bash
# Idle notification handler

set -euo pipefail

CWD="${1:-}"

# Read JSON input from stdin
INPUT=$(cat)

# Parse message field
MESSAGE=$(echo "$INPUT" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)

DETAILS="Waiting for input"
if [ -n "$MESSAGE" ]; then
    DETAILS="$MESSAGE"
fi

# Send notification
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../discord-notify.sh" \
    "Input Needed" \
    "$CWD" \
    "$DETAILS"

exit 0
