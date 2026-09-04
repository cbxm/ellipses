#!/usr/bin/env bash
# forge dispatcher: runs the get-issue-timeline.sh implementation for the detected forge.
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
forge=$("$D/detect.sh")
impl="$D/../$forge/scripts/get-issue-timeline.sh"
[ -x "$impl" ] || { echo "forge: get-issue-timeline.sh not supported on $forge" >&2; exit 2; }
exec "$impl" "$@"
