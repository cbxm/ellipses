#!/usr/bin/env bash
# Read-only ai7 D1 query for the support skill: one SELECT statement, JSON out.
#   d1-select.sh "select id, name from agent where org_id = '...'"
set -euo pipefail
sql="${1:?usage: d1-select.sh \"<select ...>\"}"
trimmed="$(printf '%s' "$sql" | sed -E 's/^[[:space:]]+//; s/;[[:space:]]*$//')"
if ! printf '%s' "$trimmed" | grep -qiE '^(select|with)[[:space:]]' || printf '%s' "$trimmed" | grep -q ';' \
   || printf '%s' "$trimmed" | grep -qiE '\b(insert|update|delete|drop|alter|create|replace|pragma|attach)\b'; then
  echo "refused: only a single SELECT is allowed" >&2; exit 2
fi
cd "${AI7_DIR:-$HOME/src/x2u/ai7}"
exec npx wrangler d1 execute ai7 --remote --json --command "$trimmed"
