#!/usr/bin/env bash
# forge dispatcher: runs the encoded-path.sh implementation for the detected forge.
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
forge=$("$D/detect.sh")
impl="$D/../$forge/scripts/encoded-path.sh"
[ -x "$impl" ] || { echo "forge: encoded-path.sh not supported on $forge" >&2; exit 2; }
exec "$impl" "$@"
