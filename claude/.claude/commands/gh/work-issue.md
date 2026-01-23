---
description: Load GitHub issue into context to start working on it
---

Load GitHub issue context to prepare for work. No prompts - just loads and displays.

**Usage:**
- `/work-issue <number>` - Load issue by number
- `/work-issue 4` - Load issue #4

**Execution flow:**

1. **Fetch issue** (use gh-issue-ops skill scripts)
   ```bash
   # Issue details with type
   bash ~/.claude/skills/gh-issue-ops/scripts/get-issue.sh <number>

   # Comments
   bash ~/.claude/skills/gh-issue-ops/scripts/get-issue-comments.sh <number>
   ```

2. **Display structured context**
   Parse issue body and display:
   ```
   ## Issue #<number>: <title>
   Type: <type>

   ### Objective
   [from issue body]

   ### Context
   [from issue body]

   ### Scope
   [from issue body, if present]

   ### Done When
   [from issue body - critical for knowing when complete]

   ### Branch
   [from issue body, if specified]
   ```

3. **Check for investigation**
   - Scan comments for investigation report (look for "## Investigation" header)
   - If found: display summary
     ```
     ### Investigation
     [summary of findings, relevant files, proposed approach]
     ```
   - If not found: note it
     ```
     ### Investigation
     None yet. Consider: /investigate <number>
     ```

4. **Show current state**
   ```
   ---
   Current branch: <git branch --show-current>
   Issue URL: <url>
   ```

5. **Suggest next steps** (based on state)
   - No investigation → "Suggest: /investigate <number> for codebase research"
   - Has investigation → "Ready to plan implementation"
   - Missing Done When → "Warning: no acceptance criteria defined"

**Key requirements:**
- Use skill scripts for fetching (dynamic per-repo)
- No interactive prompts - load and display only
- Parse our /issue template format (Objective, Context, Scope, Done When)
- Surface investigation comments prominently
- Warn if acceptance criteria missing
- Show current branch but don't prompt to change
- Concise output
