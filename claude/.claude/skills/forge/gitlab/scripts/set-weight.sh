#!/bin/bash
# Set an issue's weight — the GitLab home for the GitHub Project "Estimate"
# field (XS=1, S=2, M=3, L=5, XL=8).
# Usage: set-weight.sh <iid> <weight>
set -euo pipefail
IID="${1:-}"; WEIGHT="${2:-}"
if [ -z "$IID" ] || [ -z "$WEIGHT" ]; then
  echo "Usage: set-weight.sh <iid> <weight>" >&2; exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")

glab api --method PUT "projects/$ENC/issues/$IID?weight=$WEIGHT" | jq '{number: .iid, weight}'
