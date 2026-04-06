#!/bin/bash
# Fetch ALL PR review comments: inline code comments, review summaries, and conversation comments.
# Usage: get-review-comments.sh [pr-number]
# If no PR number is provided, auto-detects from the current branch.

set -euo pipefail

TMPDIR_PATH=$(mktemp -d)
trap 'rm -rf "$TMPDIR_PATH"' EXIT

NUMBER="${1:-}"

if [ -z "$NUMBER" ]; then
  NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null) || true
  if [ -z "$NUMBER" ]; then
    echo "Error: No PR number provided and could not detect one from current branch." >&2
    echo "Usage: get-review-comments.sh [pr-number]" >&2
    exit 1
  fi
fi

OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Fetch all three endpoints in parallel
gh api --paginate "repos/$OWNER/$REPO/pulls/$NUMBER/comments" \
  > "$TMPDIR_PATH/inline.json" 2>"$TMPDIR_PATH/inline.err" &
PID_INLINE=$!

gh api --paginate "repos/$OWNER/$REPO/pulls/$NUMBER/reviews" \
  > "$TMPDIR_PATH/reviews.json" 2>"$TMPDIR_PATH/reviews.err" &
PID_REVIEWS=$!

gh api --paginate "repos/$OWNER/$REPO/issues/$NUMBER/comments" \
  > "$TMPDIR_PATH/conversation.json" 2>"$TMPDIR_PATH/conversation.err" &
PID_CONVERSATION=$!

FAILED=0
wait $PID_INLINE || { echo "Error fetching inline comments: $(cat "$TMPDIR_PATH/inline.err")" >&2; FAILED=1; }
wait $PID_REVIEWS || { echo "Error fetching reviews: $(cat "$TMPDIR_PATH/reviews.err")" >&2; FAILED=1; }
wait $PID_CONVERSATION || { echo "Error fetching conversation comments: $(cat "$TMPDIR_PATH/conversation.err")" >&2; FAILED=1; }

if [ "$FAILED" -eq 1 ]; then
  exit 1
fi

# --paginate outputs multiple JSON arrays (one per page), merge them
jq -s 'flatten' "$TMPDIR_PATH/inline.json" > "$TMPDIR_PATH/inline_merged.json"
jq -s 'flatten' "$TMPDIR_PATH/reviews.json" > "$TMPDIR_PATH/reviews_merged.json"
jq -s 'flatten' "$TMPDIR_PATH/conversation.json" > "$TMPDIR_PATH/conversation_merged.json"

# Format everything into readable output
jq -r --arg number "$NUMBER" --arg owner "$OWNER" --arg repo "$REPO" '
def truncate_hunk:
  split("\n") |
  if length > 5 then
    ["  ...(" + (length - 5 | tostring) + " lines truncated)"] + .[-5:]
  else .
  end |
  map("  " + .) |
  join("\n");

def format_date:
  split("T")[0];

# Read all three files from inputs
input as $reviews_raw |
input as $conversation_raw |

# Filter out PENDING reviews
[$reviews_raw[] | select(.state != "PENDING")] as $reviews |

# Separate root inline comments from replies
[.[] | select(.in_reply_to_id == null)] as $roots |
[.[] | select(.in_reply_to_id != null)] as $replies |

# Group roots by file path, sort by path then line
[$roots | sort_by(.path, (.line // .original_line // 0))[] |
  . as $root |
  {
    root: $root,
    replies: [$replies[] | select(.in_reply_to_id == $root.id)] | sort_by(.created_at)
  }
] |
group_by(.root.path) as $by_file |

# Count totals
($reviews | length) as $review_count |
($roots | length) as $inline_count |
($conversation_raw | length) as $conversation_count |

# Output header
"## PR #\($number) Review Comments (\($owner)/\($repo))\n" +

# Reviews section
"### Reviews (\($review_count))\n" +
if $review_count == 0 then "(none)\n"
else
  [$reviews | sort_by(.submitted_at)[] |
    "**\(.state)** by \(.user.login) — \(.submitted_at | format_date)\n" +
    if (.body // "") == "" then "> (no summary)\n"
    else "> \(.body | gsub("\n"; "\n> "))\n"
    end
  ] | join("\n")
end +

"\n### Inline Comments (\($inline_count))\n" +
if $inline_count == 0 then "(none)\n"
else
  [$by_file[] |
    [.[] |
      "**\(.root.path):\(.root.line // .root.original_line // "?")** — \(.root.user.login) (\(.root.created_at | format_date))\n" +
      (.root.diff_hunk | truncate_hunk) + "\n\n" +
      "> \(.root.body | gsub("\n"; "\n> "))\n" +
      if (.replies | length) > 0 then
        [.replies[] |
          "\n  Reply by \(.user.login) (\(.created_at | format_date)):\n  > \(.body | gsub("\n"; "\n  > "))\n"
        ] | join("")
      else ""
      end
    ] | join("\n")
  ] | join("\n")
end +

"\n### Conversation Comments (\($conversation_count))\n" +
if $conversation_count == 0 then "(none)\n"
else
  [$conversation_raw | sort_by(.created_at)[] |
    "**\(.user.login)** (\(.created_at | format_date))\n" +
    "> \(.body | gsub("\n"; "\n> "))\n"
  ] | join("\n")
end
' "$TMPDIR_PATH/inline_merged.json" "$TMPDIR_PATH/reviews_merged.json" "$TMPDIR_PATH/conversation_merged.json"
