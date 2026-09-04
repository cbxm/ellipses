#!/usr/bin/env bash
# forge dispatcher: runs the set-scoped-label.sh implementation for the detected forge.
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
forge=$("$D/detect.sh")
impl="$D/../$forge/scripts/set-scoped-label.sh"
[ -x "$impl" ] || { echo "forge: set-scoped-label.sh not supported on $forge" >&2; exit 2; }
exec "$impl" "$@"
