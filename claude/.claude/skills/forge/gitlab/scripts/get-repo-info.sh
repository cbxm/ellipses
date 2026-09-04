#!/bin/bash
# Basic project info: namespace, name, default branch, numeric id.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENC=$("$DIR/encoded-path.sh")

glab api "projects/$ENC" | jq '{
  projectId: .id,
  path: .path_with_namespace,
  namespace: .namespace.full_path,
  name: .path,
  defaultBranch: .default_branch,
  webUrl: .web_url
}'
