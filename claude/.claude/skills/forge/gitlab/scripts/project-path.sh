#!/bin/bash
# Resolve the current GitLab project path (`group/project`).
#
# Sourced by every other gl-* script. Prefers CI_PROJECT_PATH so the same
# scripts work inside a pipeline job, then falls back to parsing the git remote
# — `glab repo view` would also work but costs an API round trip per call, and
# these scripts chain several.
set -euo pipefail

if [ -n "${CI_PROJECT_PATH:-}" ]; then
  echo "$CI_PROJECT_PATH"
  exit 0
fi

URL=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$URL" ]; then
  echo "No 'origin' remote found; cannot resolve GitLab project." >&2
  exit 1
fi

# git@gitlab.com:group/project.git  |  https://gitlab.com/group/project.git
PATH_PART=$(echo "$URL" | sed -E 's#^git@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##')

if [ -z "$PATH_PART" ] || [ "$PATH_PART" = "$URL" ]; then
  echo "Could not parse a GitLab project path from origin: $URL" >&2
  exit 1
fi

echo "$PATH_PART"
