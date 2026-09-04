#!/bin/bash
# Unified issue timeline.
# Usage: get-issue-timeline.sh <iid>
#
# GitLab has no single timeline endpoint like GitHub's. Reconstructed by merging
# three sources and sorting by timestamp:
#   resource_state_events  -> opened/closed/reopened
#   resource_label_events  -> label added/removed (this is where board-column
#                             moves live, since board lists are labels)
#   notes (system + human) -> everything else
set -euo pipefail
IID="${1:-}"
[ -z "$IID" ] && { echo "Usage: get-issue-timeline.sh <iid>" >&2; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")
BASE="projects/$ENC/issues/$IID"

STATE=$(glab api "$BASE/resource_state_events?per_page=100" \
  | jq '[.[] | {kind: "state", at: .created_at, actor: .user.username, detail: .state}]')

LABEL=$(glab api "$BASE/resource_label_events?per_page=100" \
  | jq '[.[] | {kind: "label", at: .created_at, actor: .user.username,
                detail: ((.action) + " " + (.label.name // "?"))}]')

NOTES=$(glab api "$BASE/notes?per_page=100" \
  | jq '[.[] | {kind: (if .system then "system" else "comment" end),
                at: .created_at, actor: .author.username, detail: .body}]')

jq -n --argjson a "$STATE" --argjson b "$LABEL" --argjson c "$NOTES" \
  '($a + $b + $c) | sort_by(.at)'
