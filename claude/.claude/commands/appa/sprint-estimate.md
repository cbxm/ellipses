---
description: Size unsized items and derive the estimate from size for the current sprint
---

Two-phase effort pass over the current sprint (GitHub Project / GitLab milestone): interactively size any unsized items, then automatically derive the numeric estimate from size.

**Size → estimate mapping:** XS=1, S=2, M=3, L=5, XL=8

**Usage:**
- `/appa:sprint-estimate` - Current sprint; only fills empty estimates
- `/appa:sprint-estimate --overwrite` - Recompute the estimate from size even where already set
- `/appa:sprint-estimate "07/13-17"` - Explicit milestone/iteration title

---

> **Forge mapping.** On GitHub, Size is a Project V2 single-select field and
> Estimate is a separate numeric field, both edited through `gh project
> item-edit` with field ids and option ids — resolve those first with
> `bash ~/.claude/skills/forge/scripts/get-project-fields.sh`. On GitLab there is
> neither: Size is a **`size::` scoped label** and Estimate is the issue's native
> **`weight`**. Both are written directly on the issue, so there are no
> project/field/option ids to resolve and that preparatory step is skipped.

**Execution flow:**

0. **Detect the forge**
   ```bash
   bash ~/.claude/skills/forge/scripts/detect.sh
   ```

1. **Fetch the sprint's issues**
   ```bash
   # GitHub: bash ~/.claude/skills/forge/scripts/get-project-items.sh
   # GitLab: bash ~/.claude/skills/forge/scripts/get-milestone-issues.sh <milestone-title-if-given>
   ```
   Pass ONLY a milestone title as the argument — never flags like `--overwrite` (the script would treat them as a title).
   The output already includes each issue's current `size` and `estimate`, so no second fetch is needed.

2. **Phase A — size the unsized (interactive).** For each sprint issue with NO size:
   - Gather signal: issue body, any `## Investigation` comment (file count / proposed-approach length is the best size proxy), and a light codebase glance only if neither is informative
   - Propose a size with a one-line rationale:
     ```
     #852 deploy Cost Summary collapse to Demo env
     Proposed: XS — single tag-deploy operation, no code changes
     ```
   - Ask the user to confirm or pick another (offer all five). NEVER write a guessed size without confirmation
   - On confirmation:
     - GitHub: `gh project item-edit` against the Size single-select field (field id + option id from `get-project-fields.sh`)
     - GitLab: `bash ~/.claude/skills/forge/scripts/set-scoped-label.sh <iid> size <xs|s|m|l|xl>` — scoped labels are mutually exclusive within their scope, so this replaces any existing `size::` value without a removal step

3. **Phase B — derive estimates (automatic).** For every sprint issue with a size:
   - Skip issues whose estimate is already set, unless `--overwrite`
   - Map size → number (XS=1, S=2, M=3, L=5, XL=8) and write:
     - GitHub: `gh project item-edit` against the numeric Estimate field
     - GitLab: `bash ~/.claude/skills/forge/scripts/set-weight.sh <iid> <n>`

4. **Summary:**
   ```
   Sized: #852 → XS
   Estimates written: #849 S→2, #35 S→2, #837 XL→8, ...
   Preserved (already set): #745 = 15
   Sprint total: 27
   ```
   The total is the week's committed effort — always print it last.

**Key requirements:**
- Phase A is interactive per item; Phase B runs without prompts
- An explicitly set estimate (e.g. a hand-entered value differing from the mapping) is preserved unless `--overwrite`
- Idempotent: rerun is a no-op once everything is sized and estimated
- On GitLab, use the lowercase label value (`size::m`, not `size::M`) consistently — GitLab labels are case-sensitive, so mixing cases creates two distinct labels and silently splits the scope
