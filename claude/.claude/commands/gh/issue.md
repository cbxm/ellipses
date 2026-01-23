---
description: Create a new GitHub issue
---

Create well-structured GitHub issues for agent consumption and customer communication.

**Usage:**
- `/issue` - Interactive, prompts for description
- `/issue "brief description"` - Start with description

**Execution flow:**

1. **Gather context silently**
   - Branch: `git branch --show-current`
   - Modified files: `git diff --name-only` (if any)

2. **Get description** (if not provided in args)
   - Ask: "What needs to happen?"

3. **Generate draft issue**
   - Title: action-oriented, scannable
   - Body structure:
     ```
     ## Objective
     [what needs to happen - clear, actionable]

     ## Context
     [why it matters, background info]

     ## Scope
     [affected areas/files if relevant]

     ## Done When
     [acceptance criteria - be specific]

     ## Branch
     [auto-detected branch]
     ```

4. **Preview + iterate**
   - Show full draft to user
   - Ask unresolved questions to strengthen the spec
   - User can request changes ("make title shorter", "add detail to done-when")
   - User approves with "create", "looks good", "ship it", etc.
   - Loop until approved

5. **Infer type from content**
   - Bug: broken behavior, error, regression
   - Feature: new capability, enhancement
   - Task: maintenance, refactor, docs, chore

6. **Create issue**
   ```bash
   gh issue create --title "<title>" --body "$(cat <<'EOF'
   <body>
   EOF
   )"
   ```

7. **Set issue type** (use gh-issue-ops skill script)
   ```bash
   bash ~/.claude/skills/gh-issue-ops/scripts/set-issue-type.sh <number> "<type>"
   ```
   Script dynamically fetches available types for the repo - no hardcoded IDs.

8. **Return** issue URL + number only

**Key requirements:**
- Intent only - no implementation details
- Iterate until spec is solid (spec-driven development)
- No priority labels (handled in Projects)
- Auto-detect branch, include only if relevant
- Use skill scripts for type operations (dynamic per-repo)
