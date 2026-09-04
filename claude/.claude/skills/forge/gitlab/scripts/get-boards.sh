#!/bin/bash
# Issue boards and their lists.
#
# Replaces the GitHub `get-projects.sh` / `get-project-fields.sh` pair: GitLab
# has no Projects V2, so "which columns exist" is a board's lists, each backed
# by a label.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENC=$("$DIR/encoded-path.sh")

glab api "projects/$ENC/boards" | jq '[.[] | {
  id,
  name,
  lists: [.lists[]? | {id, position, label: .label.name}]
}]'
