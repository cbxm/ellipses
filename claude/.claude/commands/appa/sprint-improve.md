---
description: Improve every rough-draft issue in the current sprint, one at a time
---

Bulk wrapper around `/appa:improve-issue`: find every issue in the current sprint (GitHub Project / GitLab milestone) whose body is still a rough draft, then run the full interactive improve flow on each, sequentially.

**Usage:**
- `/appa:sprint-improve` - Current sprint (nearest open due date)
- `/appa:sprint-improve "June 15-19"` - Explicit milestone/iteration title

**Execution flow:**

1. **Fetch the sprint's issues** — detect the forge first (`bash ~/.claude/skills/forge/scripts/detect.sh`)
   ```bash
   # GitHub: bash ~/.claude/skills/forge/scripts/get-project-items.sh
   # GitLab: bash ~/.claude/skills/forge/scripts/get-milestone-issues.sh "$ARGUMENTS"
   ```
   Keep the quotes — milestone titles contain spaces ("June 8-12"), and an unquoted title word-splits into the wrong milestone. Omit the argument entirely when no title was given.

2. **Classify candidates**
   - An issue **needs improving** if its body is missing `## Objective` OR `## Done When` (the `/appa:issue` spec template sections)
   - Issues that already match the template are skipped

3. **Show the docket** before starting:
   ```
   Sprint: <title> (<N> open issues)
   Needs improving (<K>): #12 <title>, #34 <title>, ...
   Already specced (skipped): #56, ...
   ```

4. **Loop sequentially** through candidates. For each one, invoke the existing single-issue command:
   ```
   /appa:improve-issue <number>
   ```
   Run its FULL interactive flow — fetch issue + comments, light codebase inspection, clarifying questions, preview, approval, issue update, set type. Do not shortcut the per-issue approval gate.

5. **Between issues**, briefly state progress (`2 of 5 done, next: #837 analytics dashboard`). The user can say `skip` (move on without editing) or `stop` (end the loop) at any point.

6. **End summary:**
   ```
   Improved: #12, #34
   Skipped: #56 (already specced), #78 (user skipped)
   Remaining: #90 (stopped early)
   ```

**Key requirements:**
- Delegate per-issue work to `/appa:improve-issue` — do NOT reimplement its flow here
- Sequential and interactive: one issue fully approved before the next begins
- Resumable: rerunning the command re-classifies, so already-improved issues drop out automatically (safe after `/clear`)
- Detection is the template check only — don't second-guess a body that has both sections
