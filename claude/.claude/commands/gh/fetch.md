---
description: Fetch and address PR review comments (inline, reviews, conversation)
---

Fetch all review comments for a PR and address the feedback.

**Usage:**
- `/gh:fetch` - Auto-detect PR from current branch
- `/gh:fetch 123` - Explicit PR number

**Steps:**

1. Fetch all PR comments using the gh-review-comments script:

```bash
bash ~/.claude/skills/gh-review-comments/scripts/get-review-comments.sh $ARGUMENTS
```

2. Read ALL comments completely before reacting.

3. For each comment, assess whether it:
   - Points out a real issue that needs fixing
   - Is a nit/suggestion that improves code quality
   - Is incorrect or based on a misunderstanding (push back with reasoning)

4. Create a TodoWrite checklist of all actionable items.

5. Address each item:
   - Implement fixes one at a time
   - Test each fix individually
   - Commit after each logical group of fixes

6. Run tests, lint, and typecheck before pushing.

7. Push changes and summarize what was addressed.
