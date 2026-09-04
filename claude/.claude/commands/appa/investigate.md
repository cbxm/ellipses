---
description: Research an issue and propose implementation
---

Thoroughly investigate an issue, explore the codebase, and propose a technical approach.

**Usage:**
- `/appa:investigate #123` - Investigate issue by number
- `/appa:investigate <url>` - Investigate issue by URL

**Execution flow:**

1. **Fetch issue + comments** (run the forge scripts directly)
   ```bash
   # Issue details with type
   bash ~/.claude/skills/forge/scripts/get-issue.sh <number>

   # Comments (may contain prior discussion, context, previous investigations)
   bash ~/.claude/skills/forge/scripts/get-issue-comments.sh <number>
   ```

2. **Review existing comments**
   - Check for prior investigation comments
   - Note any context, decisions, or constraints mentioned
   - Avoid duplicating existing research

3. **Deep codebase exploration** (delegate to the `scout` agent — model sonnet, read-only, returns file paths and call chains; use plain WebSearch for anything external)
   - Search for keywords from issue title/body
   - Trace code paths related to the objective
   - Find similar patterns/implementations
   - Identify dependencies and side effects
   - Check for existing tests
   - Be EXTREMELY thorough - this is the research step

4. **Analyze findings**
   - Map issue requirements to code locations
   - Identify what needs to change
   - Consider edge cases and risks
   - Note any ambiguities or open questions

5. **Present findings locally**
   - Show structured investigation report
   - Format:
     ```markdown
     ## Investigation: #<number>

     ### Summary
     [1-2 sentence TLDR]

     ### Relevant Files
     - `path/to/file.ts` - [why relevant]

     ### Current Behavior
     [what happens now]

     ### Proposed Approach
     1. [step]
     2. [step]

     ### Risks & Edge Cases
     - [potential issue]

     ### Open Questions
     - [unresolved uncertainty]
     ```

6. **User review**
   - User can ask questions, request deeper investigation
   - User approves with "post", "comment", "ship it", etc.

7. **Post the comment** — detect the forge first (`bash ~/.claude/skills/forge/scripts/detect.sh`)
   - GitHub: `gh issue comment <number> --body "$(cat <<'EOF'
     <investigation report>
     EOF
     )"`
   - GitLab: `glab issue note <number> --body "$(cat <<'EOF'
     <investigation report>
     EOF
     )"`

8. **Return** confirmation with comment URL

**Key requirements:**
- Fetch issue AND comments (prior context matters)
- Thorough exploration - don't cut corners
- Implementation-focused
- Present locally before posting
- Structured output for agent consumption
- Include risks and edge cases
