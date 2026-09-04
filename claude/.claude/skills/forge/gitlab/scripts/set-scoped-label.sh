#!/bin/bash
# Set a scoped label on an issue (type/priority/size/status).
# Usage: set-scoped-label.sh <iid> <scope> <value>
#   e.g. set-scoped-label.sh 1234 type bug
#
# Replaces the GitHub `set-issue-type.sh` GraphQL mutation. No removal step is
# needed: GitLab scoped labels are mutually exclusive within a scope, so adding
# `type::bug` automatically drops an existing `type::feature`.
set -euo pipefail
IID="${1:-}"; SCOPE="${2:-}"; VALUE="${3:-}"
if [ -z "$IID" ] || [ -z "$SCOPE" ] || [ -z "$VALUE" ]; then
  echo "Usage: set-scoped-label.sh <iid> <scope> <value>" >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")

glab api --method PUT "projects/$ENC/issues/$IID?add_labels=${SCOPE}::${VALUE}" \
  | jq '{number: .iid, labels}'
