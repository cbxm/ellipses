---
description: Investigate every sprint issue lacking an investigation — parallel research, sequential review
---

Bulk wrapper around `/appa:investigate`: find every issue in the current sprint (GitHub Project / GitLab milestone) with no investigation yet, run the deep codebase exploration in PARALLEL `scout` AGENTS, then review and post each report sequentially with user approval.

**Usage:**
- `/appa:sprint-investigate` - Current sprint (nearest open due date)
- `/appa:sprint-investigate "June 15-19"` - Explicit milestone/iteration title

**Why agents:** one `/appa:investigate` exploration can consume a large share of the context window. Running several inline serially degrades the session before the docket is done. Agents keep raw exploration out of the main session — only the structured reports come back — and run concurrently.

**Execution flow:**

1. **Fetch the sprint's issues** — detect the forge first (`bash ~/.claude/skills/forge/scripts/detect.sh`)
   ```bash
   # GitHub: bash ~/.claude/skills/forge/scripts/get-project-items.sh
   # GitLab: bash ~/.claude/skills/forge/scripts/get-milestone-issues.sh "$ARGUMENTS"
   ```
   Keep the quotes — milestone titles contain spaces ("June 8-12"), and an unquoted title word-splits into the wrong milestone. Omit the argument entirely when no title was given.

2. **Classify candidates** — for each issue, fetch comments:
   ```bash
   bash ~/.claude/skills/forge/scripts/get-issue-comments.sh <number>
   ```
   - An issue **needs investigating** if NO comment contains a `## Investigation` header
   - If a candidate is also a rough draft (body missing `## Objective`/`## Done When`), flag it in the docket: investigating an unspecced issue is allowed but `/appa:sprint-improve` first usually produces better research targets

3. **Show the docket** (candidates, skipped-with-investigation, rough-draft flags) before spawning anything.

4. **Parallel exploration via agents** — spawn one `scout` agent (model sonnet, read-only investigation, returns file paths and call chains) per candidate, 2-3 concurrent at a time. Each agent prompt must include:
   - The full issue body + relevant comment context (agents don't share this session's context)
   - The exploration instructions from `/appa:investigate` steps 2-4: review prior comments, deep codebase exploration (trace code paths, similar patterns, dependencies, side effects, existing tests — be EXTREMELY thorough; plain WebSearch for anything external), analyze findings
   - The exact report format to return, and an instruction to return ONLY the report:
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

     ### Risks & Edge Cases
     - [potential issue]

     ### Open Questions
     - [unresolved uncertainty]
     ```

5. **Sequential review gate** — as reports come back, present them ONE at a time:
   - User can request edits, ask follow-up questions (resume that scout for deeper digging rather than exploring inline), approve, or skip
   - On approval ("post", "ship it", etc.):
     - GitHub: `gh issue comment <number> --body "$(cat <<'EOF'
       <investigation report>
       EOF
       )"`
     - GitLab: `glab issue note <number> --body "$(cat <<'EOF'
       <investigation report>
       EOF
       )"`

6. **End summary:** posted / skipped / remaining, with comment URLs.

**Key requirements:**
- NEVER run the deep exploration inline in the main session — agents only
- Reports are presented and approved one at a time; nothing posts without explicit approval
- Resumable: the `## Investigation` comment marker means rerunning skips completed issues (safe after `/clear`)
- Keep the report format identical to `/appa:investigate` so `/appa:work-issue` detection keeps working
