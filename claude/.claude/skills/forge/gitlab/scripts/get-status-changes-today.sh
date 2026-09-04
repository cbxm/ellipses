#!/bin/bash
# Issues whose board column changed today.
# Usage: get-status-changes-today.sh [YYYY-MM-DD]
#
# GitLab board lists ARE labels, so a column move is a `status::*` label event.
# Reconstructed from resource_label_events per issue — there is no Projects V2
# item-level status history to query.
#
# Bounded: inspects at most 100 issues updated since the target date.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")
DAY="${1:-$(date -u +%Y-%m-%d)}"

ISSUES=$(glab api "projects/$ENC/issues?updated_after=${DAY}T00:00:00Z&per_page=100&scope=all" \
  | jq -r '.[].iid')

{
  for IID in $ISSUES; do
    glab api "projects/$ENC/issues/$IID/resource_label_events?per_page=100" 2>/dev/null \
      | jq --arg day "$DAY" --arg iid "$IID" '
          [.[]
           | select(.label.name? // "" | startswith("status::"))
           | select(.created_at | startswith($day))
           | {number: ($iid | tonumber), at: .created_at,
              actor: .user.username, action: .action, status: .label.name}]'
  done
} | jq -s 'flatten | sort_by(.at)'
