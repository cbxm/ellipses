#!/bin/bash
# Available labels, including the scoped labels that replaced GitHub Projects
# single-select fields (type::, priority::, size::, status::).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENC=$("$DIR/encoded-path.sh")

glab api "projects/$ENC/labels?per_page=100&with_counts=false" \
  | jq '[.[] | {name, description, color}]'
