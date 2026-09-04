#!/bin/bash
# Full issue details.
# Usage: get-issue.sh <iid>
#
# `type` comes from a `type::*` scoped label rather than a first-class field —
# GitLab has no issue types, so the GitHub issueType GraphQL query became this.
set -euo pipefail
IID="${1:-}"
[ -z "$IID" ] && { echo "Usage: get-issue.sh <iid>" >&2; exit 1; }

ENC=$("$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/encoded-path.sh")

glab api "projects/$ENC/issues/$IID" | jq '{
  number: .iid,
  title,
  body: .description,
  state,
  url: .web_url,
  labels,
  weight,
  milestone: .milestone.title,
  assignees: [.assignees[]?.username],
  type:     (.labels | map(select(startswith("type::")))     | first // "none"),
  priority: (.labels | map(select(startswith("priority::"))) | first // "none"),
  size:     (.labels | map(select(startswith("size::")))     | first // "none"),
  status:   (.labels | map(select(startswith("status::")))   | first // "none")
}'
