---
description: Stage and commit changes from current work session
---

Automatically stage and commit changes with generated message. No user prompts.

Steps:
1. Run `git status` to see modified/untracked files
2. Run `git diff` to analyze changes
3. Auto-generate commit message:
   - Determine commit type: `feat:`, `fix:`, `chore:`
   - Generate concise title from changes
   - Add body if: multiple files, complex changes, or mixed types
4. Stage relevant files: `git add <files>`
5. Commit: `git commit -m "message"` (use heredoc for multi-line)
6. Return commit hash and summary

Key requirements:
- Extremely concise (sacrifice grammar for concision)
- Auto-determine if body needed (don't ask user)
- No preview/confirmation (just execute)
- No auto-footer (user manages manually)
- Stage only relevant files (exclude accidental changes)
- Never stage `.claude/memory/**` with feature/fix changes — memory gets its own `chore(memory)` commit. If asked to commit only memory, use type `chore(memory):`

Execute immediately - no user interaction required.
