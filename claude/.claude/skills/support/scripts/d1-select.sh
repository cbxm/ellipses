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
# cf (1.0.0-beta.18) refreshes an expired OAuth token on the call that finds it
# expired, but that call still fails with 7403; the next one succeeds. Routine
# runs always start with an expired token, so retry once on 7403.
query() { cf d1 query 336feb62-e178-4824-a865-a9cdc0bf5884 --profile x2u --sql "$trimmed" 2>&1; }
out="$(query)" || { grep -q 7403 <<<"$out" && out="$(query)"; } || { printf '%s\n' "$out" >&2; exit 1; }
printf '%s\n' "$out"
