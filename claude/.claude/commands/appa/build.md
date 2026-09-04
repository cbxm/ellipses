---
description: Dispatch a builder agent in the background to implement a plan file in its own worktree
---

Kick off implementation of a plan without leaving the conversation.

**Usage:**
- `/appa:build <path-to-plan.md>` — plan file written during brainstorming (usually in the scratchpad)
- `/appa:build <path> --fork` — use a fork instead of a fresh builder when the conversation itself is the spec

**Execution flow:**

1. **Check the plan exists** and skim its Goal and Open questions. If an open question changes the work materially, ask the user now rather than letting the builder guess. Otherwise proceed.

2. **Derive a branch name** from the plan's goal (`feat/…`, `fix/…`, `chore/…`).

3. **Dispatch the builder** in the background with `name` set to something memorable (the branch name is fine). Brief:
   - the plan path, and the instruction to read it fully first
   - the branch name and the instruction to work in a worktree: use the repo's `worktree-setup` agent if `.claude/agents/worktree-setup.md` exists, else the `worktree` skill
   - "commit as you go; do not push; report when done"
   - Without `--fork`: `subagent_type: builder` (Opus, fresh). With `--fork`: `subagent_type: fork`, same brief, and tell it to act as the builder agent would.

4. **Tell the user** the builder's name and that it is running in the background. Continue whatever was in progress.

5. **When the completion notification arrives**, relay the builder's report: outcome, files changed, test results, deviations, open questions. Record any candidate gotchas worth keeping to memory. Do not read the diff yourself; that is `/appa:yipyip`'s reviewer.

**Key requirements:**
- One builder per plan. Follow-ups and review findings go to the SAME builder via SendMessage; never start a second builder on the same branch.
- Never dispatch onto `main`. The builder must be in a worktree before it edits anything.
- Do not block waiting for the builder.
