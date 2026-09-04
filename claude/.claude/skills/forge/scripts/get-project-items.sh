#!/usr/bin/env bash
# forge dispatcher: runs the get-project-items.sh implementation for the detected forge.
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
forge=$("$D/detect.sh")
impl="$D/../$forge/scripts/get-project-items.sh"
[ -x "$impl" ] || { echo "forge: get-project-items.sh not supported on $forge" >&2; exit 2; }
exec "$impl" "$@"
