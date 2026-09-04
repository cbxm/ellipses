---
name: worktree
description: Create an isolated git worktree for a branch and work inside it. Use before implementing anything on a repo whose current branch is main.
---

# Worktree

Work on a feature branch in its own checkout so the main working tree stays
clean. Claude Code has a native `EnterWorktree` tool that does this; use it when
it's available. The manual path below is the fallback, and describes the setup
that's still needed either way.

## Creating it

Worktrees live in `.worktrees/<branch-name>` at the repo root. Before creating
one, check that the directory is ignored:

```bash
grep -qE '^\.?worktrees/$' .gitignore
```

If it isn't, add it — otherwise the worktree contents show up in `git status`.
If `.worktrees/` doesn't exist yet, check CLAUDE.md for a project convention,
and ask before inventing one.

Pick a branch name from the request, then:

```bash
git worktree add ".worktrees/$BRANCH" -b "$BRANCH"
```

## Setting it up

If the repo has `.claude/agents/worktree-setup.md`, invoke that agent instead of
setting up by hand — it knows the project's specifics (services, migrations,
generated clients) and returns the ready path:

```
Task(subagent_type='worktree-setup', prompt='Run setup for worktree at <path>')
```

Otherwise detect the project type and install dependencies: `npm install`
(`package.json`), `cargo build` (`Cargo.toml`), `pip install -r requirements.txt`
or `poetry install` (Python), `go mod download` (`go.mod`). If nothing obvious
applies, ask.

Then run the test suite once to establish a baseline. If tests fail before
you've written anything, report that and ask whether to proceed — otherwise you
can't tell your bugs from pre-existing ones.

## Staying in it

Once you're in the worktree, stay in it for the rest of the session. Shell
working directory resets between Bash calls, so `cd ..` or a bare relative
command can silently put you back in the main checkout on `main`.

- Use absolute paths, or `git -C <worktree>`, rather than relative navigation.
- Run project commands from the worktree root, never via `cd .. && npm run lint`.
- If `git branch` shows `main` or `pwd` has no `.worktrees/` in it, you've left —
  navigate back to the full worktree path and verify before doing anything else.

Report the full worktree path and test baseline when setup is done, so it's
clear what directory everything now refers to.
