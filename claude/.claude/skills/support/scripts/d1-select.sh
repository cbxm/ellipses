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
# ai7's D1 database (database_id in ai7/wrangler.jsonc). Uses the cf CLI's x2u
# profile; wrangler has no non-interactive auth on the routine host.
exec cf d1 query 336feb62-e178-4824-a865-a9cdc0bf5884 --profile x2u --sql "$trimmed"
