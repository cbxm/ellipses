# docs: claude

Path: @/claude

### What This Configures

- **Claude Code** — Anthropic's CLI coding assistant
- Global CLAUDE.md, skills, commands, hooks, profiles, agents

### Key Choices

**nojo system**
Custom framework for Claude Code workflows:
- **Skills** — reusable instruction sets (TDD, debugging, git worktrees, etc.)
- **Profiles** — persona configurations (senior-swe, product-manager, documenter, etc.)
- **Commands** — slash commands (`/commit`, `/issue`, `/progress`, etc.)
- **Agents** — subagent definitions for specialized tasks
- **Hooks** — automation triggers (chime sounds, Discord notifications)

**Profile-based customization**
Different profiles for different work modes. `senior-swe` for coding, `product-manager` for planning, `documenter` for docs. Switch with `/nojo:switch-profile`.

**Skills as executable documentation**
Skills aren't just reference — they're instructions Claude follows. TDD skill enforces test-first, debugging skill enforces root cause analysis.

**Notification hooks**
Sound chimes and Discord notifications when Claude finishes tasks or goes idle. Useful for background work.

**Settings in repo, tokens local**
`settings.json` tracked, but auth tokens stay in `settings.local.json` (gitignored).

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)
- Skills live in `.claude/skills/`
- Profiles live in `.claude/profiles/`
