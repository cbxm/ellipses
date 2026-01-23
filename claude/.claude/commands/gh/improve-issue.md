---
description: Transform rough draft issue into well-crafted spec
---

Improve an existing GitHub issue by analyzing context and rewriting as a proper spec.

**Usage:**
- `/improve-issue <number>` - Improve issue by number
- `/improve-issue 5` - Improve issue #5

**Execution flow:**

1. **Fetch issue + comments** (use gh-issue-ops skill scripts)
   ```bash
   # Issue details with type
   bash ~/.claude/skills/gh-issue-ops/scripts/get-issue.sh <number>

   # Comments (may contain context, decisions, prior discussion)
   bash ~/.claude/skills/gh-issue-ops/scripts/get-issue-comments.sh <number>
   ```

2. **Light codebase inspection**
   - Extract keywords, file references, component names from issue
   - Search codebase for relevant files (Glob, Grep)
   - Read key files to understand context
   - Goal: understand what user is referring to, not full investigation
   - Note: This is lighter than /investigate - just enough to inform the spec

3. **Analyze gaps**
   - Check for: Objective, Context, Scope, Done When
   - Identify weak/missing/vague sections
   - Evaluate title: is it action-oriented and clear?

4. **Ask clarifying questions**
   - Only ask what's missing or unclear
   - Inform questions with codebase findings
     - e.g., "I see UserProfile.vue handles X - is that what you're referring to?"
   - Iterate until spec is solid
   - Don't ask about things you can infer

5. **Generate improved spec**
   - Rewrite body to match template:
     ```markdown
     ## Objective
     [clear, actionable - what needs to happen]

     ## Context
     [why it matters - informed by codebase understanding]

     ## Scope
     [affected files/areas - from codebase inspection]

     ## Done When
     [specific acceptance criteria]

     ## Branch
     [current branch from git]
     ```
   - Suggest improved title if original is weak
     - Make it action-oriented, scannable
     - e.g., "dark mode bug" → "Fix unreadable input text in dark mode"

6. **Preview**
   - Show current vs proposed (title + body)
   - User can request changes or approve
   - Loop until approved

7. **Update issue**
   ```bash
   gh issue edit <number> --title "<new title>" --body "$(cat <<'EOF'
   <new body>
   EOF
   )"
   ```

8. **Set/update type if needed** (use gh-issue-ops skill script)
   - Check if current type matches content (Bug/Feature/Task)
   - If missing or wrong:
   ```bash
   bash ~/.claude/skills/gh-issue-ops/scripts/set-issue-type.sh <number> "<type>"
   ```
   Script dynamically fetches available types - no hardcoded IDs.

9. **Return** confirmation with issue URL

**Key requirements:**
- Fetch issue AND comments (prior context matters)
- Light codebase inspection (understand context, not deep research)
- Only ask questions for gaps - don't be redundant
- Fully replace original content
- Suggest better title if weak
- Set correct type if missing/wrong
- Use skill scripts (dynamic per-repo)
- Preview before updating
- Concise output
