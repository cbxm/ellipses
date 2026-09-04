#!/bin/bash
# All human comments on an issue.
# Usage: get-issue-comments.sh <iid>
#
# GitLab notes include SYSTEM notes ("changed the description", "added label"),
# which are timeline events rather than comments — filtered out here so this
# matches what the GitHub comments endpoint returned. Use get-issue-timeline.sh
# when you want those.
set -euo pipefail
IID="${1:-}"
[ -z "$IID" ] && { echo "Usage: get-issue-comments.sh <iid>" >&2; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")

glab api "projects/$ENC/issues/$IID/notes?per_page=100&sort=asc&order_by=created_at" \
  | jq '[.[] | select(.system == false) | {author: .author.username, created_at, body}]'
