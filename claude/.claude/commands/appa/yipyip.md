---
description: Tests, cold review, fix loop, then push and open the PR/MR for a builder's branch (yip yip)
---

Take a builder's finished branch to an open PR/MR.

**Usage:**
- `/appa:yipyip` — ships the branch of the most recent builder
- `/appa:yipyip <builder-name>` — names the builder explicitly

**Execution flow:**

1. **Verify** via the builder's last report (or a one-line SendMessage to it) which branch and worktree path it used. Everything below runs against that worktree path with absolute paths or `git -C`.

2. **Tests, lint, typecheck.**
   - Full suite through the `test-runner` agent (repo-level one if present). Never run the suite in this context.
   - Lint and typecheck directly; their output is small. Read the repo's CLAUDE.md for the commands if unsure.
   - Any failure → SendMessage the builder with the failing test names / errors and "fix and report". Wait for its report, then rerun. Fix CI-adjacent failures even if the builder did not cause them.

3. **Cold review.** Dispatch a fresh `reviewer` agent with: the worktree path, the base branch, and `git diff <base>...HEAD` as its starting point. It reports ranked findings with a failure scenario each.

4. **Fix loop.** Send the reviewer's findings to the same builder via SendMessage with "verify each finding before acting; push back with evidence where a finding is wrong". When the builder reports back, run ONE more reviewer pass on the new diff. If that still has confirmed findings, relay them to the user and stop; do not loop indefinitely.

5. **Memory sweep** (repo-specific). If `.claude/skills/finishing-a-development-branch/scripts/sweep-memory.sh` or `.claude/scripts/sweep-memory.sh` exists in the repo, run it from the worktree so main-checkout memory changes ride this branch as a `chore(memory)` commit.

6. **Push and open the PR/MR.**
   ```bash
   git -C <worktree> push -u origin <branch>
   ~/.claude/skills/forge/scripts/detect.sh   # github | gitlab
   ```
   GitHub: `gh pr create --title … --body …`. GitLab: `glab mr create --title … --description … --remove-source-branch`. Body: 2–3 summary bullets from the builder's report, a Test Plan checklist, and the issue reference if there is one. Never a Claude Code footer.

7. **Watch CI** with the Monitor tool (or a single long-interval check), never a sleep loop. On GitLab the MR pipeline runs on `refs/merge-requests/<iid>/head`, NOT the branch: get its id from `glab api projects/<enc>/merge_requests/<iid>/pipelines` and poll `pipelines/<id>` + `pipelines/<id>/jobs`; a `--branch` filter finds nothing. On GitHub, `gh pr checks <n> --json name,bucket`. On failure: relay to the builder with the job log excerpt, then re-push. CI must be green before reporting done.

8. **Report** the PR/MR URL and CI status to the user. Offer `/appa:fetch` for addressing review comments later.

**Key requirements:**
- Appa does not read the diff. The reviewer does.
- Findings and fixes go to the SAME builder. Its context is the point.
- Never merge. Never push to `main`.
