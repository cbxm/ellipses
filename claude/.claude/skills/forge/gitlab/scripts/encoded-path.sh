#!/bin/bash
# URL-encoded project path, which is what every /projects/:id endpoint wants.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/project-path.sh" | sed 's#/#%2F#g'
