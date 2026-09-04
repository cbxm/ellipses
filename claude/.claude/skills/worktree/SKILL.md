---
name: worktree
description: Work inside a git worktree so the main checkout stays clean. Covers the harness-provided worktree (isolation:"worktree"), project setup inside it, and the manual fallback.
---

# Worktree

## You probably already have one

An agent dispatched with `isolation: "worktree"` starts in
`.claude/worktrees/agent-<id>` on a placeholder branch. That IS the worktree.
Do not create another and do not invoke a project `worktree-setup` agent on top
of it; that produces a second worktree that claims the branch name and leaves
the harness one stranded. Instead:

```bash
git branch -m <intended-branch-name>
```

then set the project up in place: run its setup script if there is one (check
CLAUDE.md; cassie has `bash .claude/skills/worktree-setup/scripts/setup.sh`,
which works from any worktree), otherwise install dependencies by project type:
`npm install` (`package.json`), `cargo build` (`Cargo.toml`),
`pip install -r requirements.txt` / `poetry install` (Python), `go mod download`
(`go.mod`). If nothing obvious applies, ask.

Check `git branch --show-current`. If it prints `main`, you are not in a
worktree; stop and report rather than editing.

## Manual fallback (no isolation)

Only when you were not given a worktree. Worktrees live in
`.worktrees/<branch-name>` at the repo root; make sure `.worktrees/` is in
`.gitignore` first.

```bash
git worktree add ".worktrees/$BRANCH" -b "$BRANCH"
```

Then set it up as above. If the repo has `.claude/agents/worktree-setup.md`,
that agent does creation and setup together; use it only on this path.

## Staying in it

The shell working directory resets between Bash calls, so `cd ..` or a bare
relative command can silently put you back in the main checkout on `main`.

- Use absolute paths, or `git -C <worktree>`, never relative navigation.
- Run project commands from the worktree root, never via `cd .. && npm run lint`.
- If `git branch --show-current` prints `main`, navigate back to the full
  worktree path and verify before doing anything else.

Report the full worktree path when setup is done, so it is clear what
directory everything now refers to.
