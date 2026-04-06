---
name: gh-review-comments
description: Fetch ALL PR review comments (inline code comments, review summaries, and conversation comments). More reliable than `gh pr view --comments` which misses inline review comments.
allowed-tools: Bash, Read
---

# GitHub PR Review Comments

Reliably fetches all three types of PR comments from GitHub's REST API with pagination support.

`gh pr view --comments` misses inline code review comments. This script hits all three endpoints directly.

## Available Scripts

### get-review-comments.sh [pr-number]

Fetches all PR comments and formats them as structured readable text.

```bash
# Auto-detect PR from current branch
bash ~/.claude/skills/gh-review-comments/scripts/get-review-comments.sh

# Explicit PR number
bash ~/.claude/skills/gh-review-comments/scripts/get-review-comments.sh 123
```

### What it fetches

| Type | API Endpoint | What it captures |
|------|-------------|------------------|
| Inline review comments | `pulls/{n}/comments` | Line-specific code feedback with diff context, threaded replies |
| Review summaries | `pulls/{n}/reviews` | APPROVED/CHANGES_REQUESTED/COMMENTED state + summary body |
| Conversation comments | `issues/{n}/comments` | Top-level PR discussion thread |

### Output format

- **Reviews** — state + summary, sorted chronologically, PENDING reviews filtered out
- **Inline comments** — grouped by file, sorted by line number, replies threaded under parent
- **Conversation comments** — chronological top-level discussion
- Empty sections show `(none)` to confirm the fetch succeeded
- Diff hunks truncated to last 5 lines to conserve context window
