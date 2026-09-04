---
description: Create a new issue (GitHub or GitLab)
---

Create well-structured issues for agent consumption and customer communication.

**Usage:**
- `/appa:issue` - Interactive, prompts for description
- `/appa:issue "brief description"` - Start with description

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

6. **Detect the forge**
   ```bash
   bash ~/.claude/skills/forge/scripts/detect.sh
   ```

7. **Create issue**
   - GitHub: `gh issue create --title "<title>" --body "$(cat <<'EOF'
     <body>
     EOF
     )"`
   - GitLab: `glab issue create --title "<title>" --description "$(cat <<'EOF'
     <body>
     EOF
     )"`

8. **Set the type** (see the forge skill for vocabulary)
   - GitHub: `bash ~/.claude/skills/forge/scripts/set-issue-type.sh <number> "<type>"` — the script fetches the repo's available types, no hardcoded IDs
   - GitLab: `bash ~/.claude/skills/forge/scripts/set-scoped-label.sh <number> type <value>` — GitLab has no first-class issue types, so type lives in a `type::` scoped label. Scoped labels are mutually exclusive within their scope, so this replaces any existing `type::` value — no removal step. Run `get-labels.sh` to see which values already exist; GitLab creates a missing label rather than rejecting the request.

9. **Return** issue URL + number only

**Key requirements:**
- Intent only - no implementation details
- Iterate until spec is solid (spec-driven development)
- No priority labels (handled on the board/project)
- Auto-detect branch, include only if relevant
- Use the forge scripts for type operations (dynamic per-repo)
