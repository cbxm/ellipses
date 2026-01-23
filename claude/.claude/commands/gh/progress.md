---
description: Generate daily progress summary for team
---

Generate concise daily progress summary for non-technical team members. Appends to `docs/daily-updates.md`.

**Usage:**
```
/progress
```

**Execution flow:**

1. **Get project items and today's activity** (use gh-project-ops skill scripts)
   ```bash
   # All project items with current status
   bash ~/.claude/skills/gh-project-ops/scripts/get-project-items.sh

   # Issues with status changes today
   bash ~/.claude/skills/gh-project-ops/scripts/get-status-changes-today.sh
   ```
   Requires `.claude/gh-config.json` in repo. Run `/gh:init` if missing.

2. **Categorize by activity**
   - **Completed**: In "Done" or "In review" AND status changed today
   - **Started**: In "In progress" AND status changed today
   - **Ongoing**: In "In progress" AND no status change today
   - **Up Next**: In "Ready" (top 3-5 items)

3. **Build summary**
   - Translate technical titles to non-technical descriptions
   - Keep extremely concise
   - Format:
     ```markdown
     ## [YYYY-MM-DD]

     ### Completed
     - [Non-technical summary of what shipped]

     ### In Progress
     - [What's being worked on] - [status/next step]

     ### Up Next
     - [What's coming]

     ### Blockers/Risks
     - [Issues blocking progress, if any]
     ```

4. **Preview to user**
   - Show generated summary
   - Ask for any adjustments
   - User approves with "save", "write", "looks good", etc.

5. **Append to file**
   - Prepend new entry to `docs/daily-updates.md` (newest first)
   - Create file if doesn't exist

6. **Return** confirmation

**Key requirements:**
- Use skill scripts for project queries (dynamic per-repo)
- Non-technical language (customer-readable)
- Very concise - sacrifice grammar
- Only show items with actual today activity in Completed
- Prepend to preserve history (newest first)
- Preview before writing
- Skip empty sections
