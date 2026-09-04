---
description: Initialize forge config for current repo (GitHub Projects V2 only)
---

Write `.claude/forge.json` for the current repository. Only needed on **GitHub** repos that use a Projects V2 board — it tells the project scripts which project to read. On GitLab nothing is needed: the scripts resolve the project from `CI_PROJECT_PATH` or the `origin` remote, and milestones/boards need no config.

**Usage:**
```
/appa:init
```

**Execution flow:**

1. **Detect the forge**
   ```bash
   bash ~/.claude/skills/forge/scripts/detect.sh
   ```
   If it prints `gitlab`, print "No config needed on GitLab" and stop.

2. **Check if config exists**
   - If `.claude/forge.json` exists, show current config and ask if user wants to reconfigure

3. **Detect repo context**
   ```bash
   OWNER=$(gh repo view --json owner -q '.owner.login')
   OWNER_TYPE=$(gh api users/$OWNER --jq '.type')
   ```

4. **List available projects**
   - For organizations: `gh project list --owner <org>`
   - For users: `gh project list`
   - Show project number and title

5. **Prompt user to select project**
   - Show numbered list of projects
   - Ask user to select by number
   - Allow "none" if user doesn't want to link a project

6. **Create config directory if needed**
   ```bash
   mkdir -p .claude
   ```

7. **Write config file**
   ```json
   {
     "forge": "github",
     "project": {
       "org": "<detected-org>",
       "number": <selected-number>
     }
   }
   ```

8. **Confirm setup**
   - Show created config
   - Remind user to add `.claude/forge.json` to `.gitignore` if they don't want to share project settings

**Key requirements:**
- GitHub only — on GitLab, report that nothing is needed and exit
- Auto-detect org vs user repos
- Handle case where no projects exist
- Create .claude directory if missing
- Show helpful output
