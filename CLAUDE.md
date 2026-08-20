# ellipses

Stow-based dotfiles for Caden's machines.

## Quick Reference

```bash
# Apply all packages
cd ~/ellipses && stow fish ghostty tmux starship bash nvim lazygit git kanata gh vscode claude wireplumber

# Apply single package
stow fish

# Remove package (unstow)
stow -D fish

# Dry run (see what would happen)
stow -n -v fish
```

## Packages

| Package | Configures | Notes |
|---------|------------|-------|
| `fish` | Fish shell | config.fish, functions/, conf.d/ |
| `ghostty` | Ghostty terminal | config, custom.css |
| `tmux` | Tmux multiplexer | tmux.conf, scripts/ (plugins installed by tpm) |
| `starship` | Starship prompt | starship.toml |
| `bash` | Bash shell | .bashrc (fallback shell) |
| `nvim` | Neovim | init.lua, lua/, after/ |
| `lazygit` | Lazygit TUI | config.yml |
| `git` | Git | .gitconfig (uses includes for identity) |
| `kanata` | Keyboard remapping | kanata.kbd |
| `gh` | GitHub CLI | config.yml only (tokens stay local) |
| `vscode` | VS Code | settings.json, snippets/ |
| `claude` | Claude Code | CLAUDE.md, settings, skills, commands, hooks |
| `wireplumber` | PipeWire session manager | BT output-only (no HFP), device priorities |

## Working With Claude

**Autonomy:** High. Make changes freely, but always explain what changed and why.

**Always tell me:**
- What you modified
- Why (the motivation, not just "added X")
- Any side effects or things to watch for

**Ask first for:**
- Adding new packages to stow
- Structural reorganization
- Machine-specific conditionals
- Anything that affects multiple packages

**Documentation:**
Each package has a `docs.md` explaining config choices. Update when making changes — focus on "why" not "what".

## Secrets Policy

**This is a public repo.** Never commit:
- API keys or tokens
- Email addresses (use ~/.gitconfig.local)
- Internal hostnames or IPs
- Paths that reveal personal info

**Patterns to watch:**
- `export.*KEY=`
- `export.*TOKEN=`
- `export.*SECRET=`
- Hardcoded credentials in any form

**Local files (not tracked):**
- `~/.gitconfig.local` - git identity (name, email)
- `~/.config/gh/hosts.yml` - GitHub auth tokens
- `~/.claude/settings.local.json` - machine-specific Claude settings

## Adding New Configs

1. Create package directory: `mkdir -p ~/ellipses/newpkg/.config/newpkg`
2. Move config: `mv ~/.config/newpkg/config.file ~/ellipses/newpkg/.config/newpkg/`
3. Stow it: `cd ~/ellipses && stow newpkg`
4. Verify symlink: `ls -la ~/.config/newpkg`
5. Add to this table above

## Machine-Specific Configs

**Current machines:**
- **Carina** - Pop!_OS laptop (Lenovo Slim Pro 7), primary dev machine
- **lynx.local** - Headless Ubuntu server

**For conditionals in fish:**
```fish
# By hostname
if test (hostname) = "Carina"
    # laptop-specific
else if test (hostname) = "lynx"
    # server-specific
end

# By environment
if set -q SSH_CONNECTION
    # running over SSH
end
```

## Common Tasks

**Add fish alias:**
Edit `fish/.config/fish/config.fish`, add to appropriate section.

**Add fish function:**
Create `fish/.config/fish/functions/funcname.fish`.

**Modify tmux keybindings:**
Edit `tmux/.config/tmux/tmux.conf`.

**Change terminal colors:**
Edit `ghostty/.config/ghostty/config` for terminal, or fish config for shell colors.

**Add nvim plugin:**
Edit `nvim/.config/nvim/lua/plugins/` (depends on plugin manager setup).

## Foundational Decisions

**Why stow?**
Simplest mental model for dotfiles. Directory structure mirrors home. Symlinks are explicit and debuggable. No magic, no dependencies beyond stow itself.

**Why fish over zsh/bash?**
Sane defaults, better autocompletions, readable syntax. Bash kept as fallback for scripts and compatibility.

**Why split git identity?**
Public repo - email shouldn't be committed. Git's `[include]` directive lets us keep identity local while sharing everything else.

**Why track Claude Code config?**
Skills, commands, and settings are valuable customizations worth preserving across machines.

## Commit Style

Write commits with motivation, not just description:
- Bad: `add alias`
- Good: `add alu alias - tired of typing apt list --upgradeable`

Git history is the decision log. Make it useful.
