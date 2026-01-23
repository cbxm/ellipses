#!/bin/bash
# Notification hook entry point
# Usage: notify-hook.sh <type>
# Types: idle, stop, subagent-stop

set -euo pipefail

HOOK_TYPE="${1:-}"
if [ -z "$HOOK_TYPE" ]; then
    echo "Error: hook type required (idle|stop|subagent-stop)" >&2
    exit 1
fi

# Guard against recursive hook calls
if [ "${CLAUDE_HOOK_CONTEXT:-}" = "1" ]; then
    exit 0
fi
export CLAUDE_HOOK_CONTEXT=1

# --- CHIME (GLOBAL) ---
CHIME_CONFIG="$HOME/.claude/chime-config.json"
if [ -f "$CHIME_CONFIG" ] && grep -q '"enabled"[[:space:]]*:[[:space:]]*true' "$CHIME_CONFIG" 2>/dev/null; then
    SCRIPT_DIR_CHIME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR_CHIME/chime.ps1" -EventType "$HOOK_TYPE" &
fi
# --- END CHIME ---

# Read JSON input from stdin
INPUT=$(cat)

# Extract CWD from input
CWD=$(echo "$INPUT" | grep -o '"cwd":"[^"]*"' | cut -d'"' -f4)

# Check notify state (default OFF - must init first)
if [ -n "$CWD" ]; then
    STATE_FILE="$CWD/.claude/notify-state.json"
    if [ ! -f "$STATE_FILE" ]; then
        exit 0
    fi
    if grep -q '"enabled"[[:space:]]*:[[:space:]]*false' "$STATE_FILE" 2>/dev/null; then
        exit 0
    fi
fi

# Dispatch to handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDLER="$SCRIPT_DIR/handlers/$HOOK_TYPE.sh"

if [ ! -f "$HANDLER" ]; then
    echo "Error: unknown hook type '$HOOK_TYPE'" >&2
    exit 1
fi

# Pass input to handler
echo "$INPUT" | "$HANDLER" "$CWD"

exit 0
