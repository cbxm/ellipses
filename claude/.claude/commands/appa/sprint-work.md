---
description: Fan /appa:work-issue across the current sprint — one tmux window + worktree per issue
---

Launch parallel work sessions for the current sprint (GitHub Project / GitLab milestone): one tmux window per issue, each in its own git worktree, each running a fresh Claude session with the issue loaded via `/appa:work-issue`.

**Usage:**
- `/appa:sprint-work` - Top 4 sprint issues (by priority, then smaller size first)
- `/appa:sprint-work --all` - Every open sprint issue
- `/appa:sprint-work 849 35 311` - Explicit issue list (overrides sprint selection)
- `/appa:sprint-work --no-setup` - Skip per-worktree dependency setup (fast context-load only)
- Flags and issue lists combine: `/appa:sprint-work --all --no-setup`

**Execution flow:**

1. **Fetch the sprint's issues** (skip when an explicit issue list was given) — detect the forge first (`bash ~/.claude/skills/forge/scripts/detect.sh`)
   ```bash
   # GitHub: bash ~/.claude/skills/forge/scripts/get-project-items.sh
   # GitLab: bash ~/.claude/skills/forge/scripts/get-milestone-issues.sh
   ```
   Exclude issues already in review or done (past the working stage — status column on GitHub, `status::in-review`/`status::done` scoped labels on GitLab; the GitLab script only excludes CLOSED issues, so an open-but-done issue would otherwise get a session).

2. **Select the set**
   - Order by priority (`p0` → `p1` → `p2` → none), then size ascending (`xs` → `xl`, unsized last). On GitHub these are Project fields; on GitLab they are `priority::`/`size::` scoped labels — the scripts surface both as `priority`/`size`.
   - Take the first **4** unless `--all` or an explicit list was given
   - For each selected issue, check comments for a `## Investigation` header (`get-issue-comments.sh <n>`); warn per-issue when missing — the spawned session will load thin context

3. **Confirm with the user** before creating anything:
   ```
   Will launch 4 sessions in tmux session "sprint-june-8-12":
     #849 [P0/S]  lookup_availability is exposing stylists' names   ⚠ no investigation
     #35  [P1/S]  reimplement 10DLC compliance messages
     ...
   Each gets a worktree at .worktrees/issue-<n> (dependency setup per worktree unless --no-setup).
   ```

4. **Ensure the tmux session** (slugify the sprint title), remembering whether it was freshly created:
   ```bash
   tmux new-session -d -s "sprint-<slug>" 2>/dev/null && FRESH_SESSION=1 || FRESH_SESSION=0
   ```

5. **Per issue** (from the repo root):
   - Branch name: `issue-<n>`, unless the issue body's `## Branch` section names one — use that instead
   - Create the worktree, reusing branch/worktree if they already exist, and VERIFY the directory exists before opening a window (the fallback chain can mask real failures like "branch checked out elsewhere"):
     ```bash
     git worktree add ".worktrees/issue-<n>" -b "<branch>" 2>/dev/null \
       || git worktree add ".worktrees/issue-<n>" "<branch>" 2>/dev/null \
       || true  # worktree already exists - reuse it
     [ -d ".worktrees/issue-<n>" ] || { echo "worktree creation failed for #<n>"; }  # report and skip this issue
     ```
   - Open the window with setup + claude chained INSIDE it (setup runs in parallel across windows; windows open instantly). Keep the window alive on setup failure so the error is readable:
     ```bash
     tmux new-window -t "sprint-<slug>" -n "issue-<n>" -c "$(git rev-parse --show-toplevel)/.worktrees/issue-<n>" \
       "bash .claude/skills/worktree-setup/scripts/setup.sh && claude --dangerously-skip-permissions '/appa:work-issue <n>' || { echo '#<n> exited nonzero (setup failure or claude exit) — window kept open'; exec bash; }"
     ```
   - With `--no-setup`, drop the `setup.sh &&` prefix

6. **Clean up the default window** — a fresh `tmux new-session -d` leaves an unused bare-shell window 0. AFTER the issue windows are open (never before — killing a session's only window kills the session), and only when the session was freshly created:
   ```bash
   [ "$FRESH_SESSION" = "1" ] && tmux kill-window -t "sprint-<slug>:0" 2>/dev/null || true
   ```

7. **Hand off:**
   - If NOT already inside tmux: `tmux attach -t "sprint-<slug>"`
   - If inside tmux (`$TMUX` set): print `tmux switch-client -t "sprint-<slug>"` for the user instead

**Key requirements:**
- `--dangerously-skip-permissions` is intentional — the user's standard invocation (`ccyo` alias) does the same. Use the explicit flag: tmux runs window commands via `sh -c`, where fish aliases don't resolve
- One shared tmux SESSION, one WINDOW per issue — do NOT use `claude --worktree --tmux` (it creates a separate session per call)
- Always confirm the selected set before creating worktrees/windows
- `claude '<slash command>'` fires the slash command as the initial prompt — no send-keys needed
- Idempotent: existing worktrees/branches are reused, existing tmux session is reused; rerunning adds only missing windows (skip issues that already have a window: `tmux list-windows -t "sprint-<slug>" -F '#W'`)
