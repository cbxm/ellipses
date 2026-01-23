---
description: Initialize GitHub config for current repo
---

Initialize `.claude/gh-config.json` for the current repository. Sets up project linking for other /gh commands.

**Usage:**
```
/gh:init
```

**Execution flow:**

1. **Check if config exists**
   - If `.claude/gh-config.json` exists, show current config and ask if user wants to reconfigure

2. **Detect repo context**
   ```bash
   OWNER=$(gh repo view --json owner -q '.owner.login')
   OWNER_TYPE=$(gh api users/$OWNER --jq '.type')
   ```

3. **List available projects**
   - For organizations: `gh project list --owner <org>`
   - For users: `gh project list`
   - Show project number and title

4. **Prompt user to select project**
   - Show numbered list of projects
   - Ask user to select by number
   - Allow "none" if user doesn't want to link a project

5. **Create config directory if needed**
   ```bash
   mkdir -p .claude
   ```

6. **Write config file**
   ```json
   {
     "project": {
       "org": "<detected-org>",
       "number": <selected-number>
     }
   }
   ```

7. **Confirm setup**
   - Show created config
   - Remind user to add `.claude/gh-config.json` to `.gitignore` if they don't want to share project settings

**Key requirements:**
- Auto-detect org vs user repos
- Handle case where no projects exist
- Create .claude directory if missing
- Show helpful output
