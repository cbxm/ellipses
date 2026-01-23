#!/bin/bash
# Subagent stop notification handler

set -euo pipefail

CWD="${1:-}"

# Read JSON input from stdin
INPUT=$(cat)

# Parse fields
TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path":"[^"]*"' | cut -d'"' -f4)

SUMMARY="Subagent complete"

# Try to generate summary from transcript
if [ -f "$TRANSCRIPT_PATH" ]; then
    RECENT=$(tail -n 10 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")

    if [ -n "$RECENT" ]; then
        # Load API key
        if [ -f "$HOME/.claude/.env" ]; then
            source "$HOME/.claude/.env"
        fi

        if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
            ESCAPED=$(echo "$RECENT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ' | head -c 2000)

            RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
                -H "Content-Type: application/json" \
                -H "x-api-key: $ANTHROPIC_API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                -d "{
                    \"model\": \"claude-haiku-4-5-20251001\",
                    \"max_tokens\": 500,
                    \"messages\": [{
                        \"role\": \"user\",
                        \"content\": \"Summarize what was accomplished in 1 short sentence. Be specific. Output only the summary.\\n\\n$ESCAPED\"
                    }]
                }" 2>/dev/null || echo "")

            if [ -n "$RESPONSE" ]; then
                SUMMARY=$(echo "$RESPONSE" | grep -o '"text":"[^"]*"' | head -1 | cut -d'"' -f4)
            fi
        fi

        if [ -z "$SUMMARY" ]; then
            SUMMARY="Subagent complete"
        fi
    fi
fi

# Send notification
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../discord-notify.sh" \
    "Subagent Complete" \
    "$CWD" \
    "$SUMMARY"

exit 0
