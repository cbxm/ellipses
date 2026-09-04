---
name: forge
description: Forge-neutral issue/PR/MR/label/milestone operations for GitHub and GitLab. Use whenever a task touches issues, PRs/MRs, labels, milestones, boards, or review comments.
---

# forge

One set of scripts that work on both GitHub and GitLab. Every op is a dispatcher
in `scripts/` that detects the forge and execs the matching implementation in
`github/scripts/` or `gitlab/scripts/`.

## Detection

`scripts/detect.sh` prints `github` or `gitlab`, in this precedence order:

1. `$FORGE` env var
2. `.claude/forge.json` → `"forge"` key (repo root)
3. CI vars — `CI_PROJECT_PATH` → gitlab, `GITHUB_REPOSITORY` → github
4. the `origin` remote host

If none resolve it exits 1 and tells you to set `FORGE` or write
`.claude/forge.json`.

## Calling an op

```bash
bash ~/.claude/skills/forge/scripts/get-issue.sh 1234
```

Never call `github/scripts/*` or `gitlab/scripts/*` directly. An op that has no
implementation on the detected forge exits **2** with
`forge: <op>.sh not supported on <forge>` — branch on the forge before calling
those (the commands under `/appa:*` show the pattern).

Project resolution needs no config on GitLab. On GitHub, the Projects V2 ops read
`.claude/forge.json`:

```json
{ "forge": "github", "project": { "org": "myorg", "number": 3 } }
```

Write it with `/appa:init`. (This replaces the older `.claude/gh-config.json`.)

## Ops

| op | GitHub | GitLab |
|---|---|---|
| `get-repo-info.sh` | owner, repo, default branch | project id, path, namespace, default branch, web URL |
| `get-labels.sh` | ✅ | ✅ |
| `get-issue.sh <n>` | full issue incl. type | full issue, scoped-label fields flattened |
| `get-issue-comments.sh <n>` | ✅ | ✅ (system notes filtered out) |
| `get-issue-timeline.sh <n>` | timeline events | merged state + label + note events, time-sorted |
| `get-review-comments.sh [n]` | all PR review comments | all MR review discussion |
| `get-status-changes-today.sh [d]` | project status changes | board-column moves |
| `get-issue-types.sh` | available types + ids | not supported |
| `set-issue-type.sh <n> <type>` | set type by name | not supported |
| `set-scoped-label.sh <n> <scope> <v>` | not supported | `type::`/`priority::`/`size::`/`status::` |
| `set-weight.sh <n> <w>` | not supported | set the estimate |
| `get-projects.sh` | linked Projects V2 | not supported |
| `get-project-items.sh [num]` | items with status | not supported |
| `get-project-fields.sh [num]` | fields + option ids | not supported |
| `get-boards.sh` | not supported | issue boards and their lists |
| `get-milestone-issues.sh [title]` | not supported | milestone issues with their fields |
| `project-path.sh` / `encoded-path.sh` | not supported | `group/project` and its URL-encoded form |

Writes that have no script go through `gh` / `glab` directly:

| action | GitHub | GitLab |
|---|---|---|
| create issue | `gh issue create --title --body` | `glab issue create --title --description` |
| edit issue | `gh issue edit <n> --title --body` | `glab issue update <n> --title --description` |
| comment | `gh issue comment <n> --body` | `glab issue note <n> --body` |

## Vocabulary

| concept | GitHub | GitLab |
|---|---|---|
| change request | PR | MR |
| numbering | issues and PRs share `#` | issues `#`, MRs `!`, separate sequences |
| issue type | first-class issue type | `type::` scoped label |
| sprint container | Project V2 | milestone (+ issue board) |
| estimate | Project numeric field | native `weight` |
| size | Project single-select field | `size::` scoped label |
| status column | Project Status field | `status::` scoped label / board list |

## Things that trip you up

**GitLab**

- **Issues are `#`, merge requests are `!`, and they are separate sequences.** A repo
  imported from GitHub keeps the original numbers, so a historical "PR #1052" is now
  MR **!1052**; issue references are unchanged.
- **There are no issue types.** Type, priority, size and status are all scoped labels.
  Scoped labels are mutually exclusive within their scope, so setting one replaces the
  old value with no removal step.
- **Estimate is the native `weight` field**, not a label.
- **GitLab creates missing labels on write.** An unknown label on create/update succeeds
  rather than erroring — a typo silently makes a new label. Check `get-labels.sh` when a
  value should already exist.
- **Notes include system events.** `get-issue-comments.sh` filters them; raw `/notes`
  calls do not.
- **Label values are case-sensitive.** `size::m` and `size::M` are two labels and will
  silently split a scope. Use lowercase.

**GitHub**

- **Never hardcode owner/repo** — the scripts detect them.
- **Project ops need `.claude/forge.json`** (org + project number) or an explicit project
  number argument; without it they exit with a message pointing at `/appa:init`.
- **Issue types are ids, not names** on the wire — `set-issue-type.sh` resolves the name
  to the repo's type id for you, so pass the name.
- **`gh pr view --comments` misses inline review comments** — use
  `get-review-comments.sh`.
