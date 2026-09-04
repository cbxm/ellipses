#!/bin/bash
# Open issues in the current sprint milestone, with their scoped-label fields.
# "Current milestone" = active milestone with the nearest due date today-or-later;
# falls back to the most recently due active milestone if none are upcoming.
# Data-only: callers (sprint-* commands) apply their own status/spec filters.
# Usage: get-milestone-issues.sh [milestone-title]
#
# Much simpler than the GitHub original, which had to cross-reference an ORG
# Projects V2 board to recover priority/size/status/estimate. In GitLab those
# live on the issue itself — scoped labels and `weight` — so one issues query
# returns everything and there is no board/repo filtering to get wrong.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")
MILESTONE_TITLE="${1:-}"

if [ -z "$MILESTONE_TITLE" ]; then
  TODAY=$(date -u +%Y-%m-%d)
  MILESTONES=$(glab api "projects/$ENC/milestones?state=active&per_page=100")
  MILESTONE_TITLE=$(echo "$MILESTONES" | jq -r --arg today "$TODAY" \
    '[.[] | select(.due_date != null) | select(.due_date >= $today)]
     | sort_by(.due_date) | first.title // empty')
  if [ -z "$MILESTONE_TITLE" ]; then
    MILESTONE_TITLE=$(echo "$MILESTONES" | jq -r \
      '([.[] | select(.due_date != null)] | sort_by(.due_date) | last.title) // first.title // empty')
    if [ -n "$MILESTONE_TITLE" ]; then
      echo "Warning: no upcoming milestone due today or later; falling back to \"$MILESTONE_TITLE\" (past-due or undated). Has this week's milestone been created?" >&2
    fi
  fi
  if [ -z "$MILESTONE_TITLE" ]; then
    echo "No active milestones found" >&2
    exit 1
  fi
fi

ENCODED_MS=$(printf '%s' "$MILESTONE_TITLE" | jq -sRr @uri)

glab api "projects/$ENC/issues?milestone=$ENCODED_MS&state=opened&per_page=100" \
  | jq --arg ms "$MILESTONE_TITLE" '{
      milestone: $ms,
      issues: [.[] | {
        number: .iid,
        title,
        url: .web_url,
        body: (.description // ""),
        priority: (.labels | map(select(startswith("priority::"))) | first // null),
        size:     (.labels | map(select(startswith("size::")))     | first // null),
        status:   (.labels | map(select(startswith("status::")))   | first // null),
        estimate: .weight,
        labels
      }]
    }'
