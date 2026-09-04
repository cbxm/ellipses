#!/bin/bash
# Fetch ALL MR discussion: inline code comments (with replies) and conversation
# comments, plus approval state.
# Usage: get-review-comments.sh [mr-iid]
# If no IID is given, auto-detects from the current branch.
#
# GitLab collapses GitHub's three endpoints (pulls/comments, pulls/reviews,
# issues/comments) into ONE /discussions endpoint: a discussion is inline when
# its first note carries a `position`, conversation otherwise. GitLab has no
# submitted-review object with a body, so the "Reviews" section becomes approval
# state from /approvals.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
ENC=$("$DIR/encoded-path.sh")
IID="${1:-}"

if [ -z "$IID" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  IID=$(glab api "projects/$ENC/merge_requests?source_branch=$BRANCH&state=opened" \
    | jq -r 'first.iid // empty')
  if [ -z "$IID" ]; then
    echo "Error: No MR iid provided and no open MR found for branch '$BRANCH'." >&2
    echo "Usage: get-review-comments.sh [mr-iid]" >&2
    exit 1
  fi
fi

TMPDIR_PATH=$(mktemp -d)
trap 'rm -rf "$TMPDIR_PATH"' EXIT

glab api "projects/$ENC/merge_requests/$IID/discussions?per_page=100" \
  > "$TMPDIR_PATH/discussions.json"
glab api "projects/$ENC/merge_requests/$IID/approvals" \
  > "$TMPDIR_PATH/approvals.json" 2>/dev/null || echo '{}' > "$TMPDIR_PATH/approvals.json"

jq -r --arg iid "$IID" '
def format_date: split("T")[0];

input as $approvals |

# System notes are timeline noise ("changed the description"), not review.
[.[] | select((.notes | length) > 0) | select(.notes[0].system == false)] as $ds |
[$ds[] | select(.notes[0].position != null)] as $inline |
[$ds[] | select(.notes[0].position == null)] as $conversation |
($approvals.approved_by // []) as $approved |

"## MR !\($iid) Review Comments\n" +

"### Approvals (\($approved | length))\n" +
(if ($approved | length) == 0 then "(none)\n"
 else [$approved[] | "**APPROVED** by \(.user.username)\n"] | join("")
 end) +

"\n### Inline Comments (\($inline | length))\n" +
(if ($inline | length) == 0 then "(none)\n"
 else
  [$inline
   | sort_by(.notes[0].position.new_path, (.notes[0].position.new_line // 0))[]
   | .notes[0] as $root
   | "**\($root.position.new_path // $root.position.old_path):\($root.position.new_line // $root.position.old_line // "?")** — \($root.author.username) (\($root.created_at | format_date))" +
     (if .notes[0].resolved == true then "  _(resolved)_" else "" end) + "\n" +
     "> \($root.body | gsub("\n"; "\n> "))\n" +
     (if (.notes | length) > 1 then
        [.notes[1:][] | "\n  Reply by \(.author.username) (\(.created_at | format_date)):\n  > \(.body | gsub("\n"; "\n  > "))\n"] | join("")
      else "" end)
  ] | join("\n")
 end) +

"\n### Conversation Comments (\($conversation | length))\n" +
(if ($conversation | length) == 0 then "(none)\n"
 else
  [$conversation | sort_by(.notes[0].created_at)[]
   | [.notes[] | "**\(.author.username)** (\(.created_at | format_date))\n> \(.body | gsub("\n"; "\n> "))\n"] | join("")
  ] | join("\n")
 end)
' "$TMPDIR_PATH/discussions.json" "$TMPDIR_PATH/approvals.json"
