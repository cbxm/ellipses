# docs: fish

Path: @/fish

### What This Configures

- **Fish** — friendly interactive shell (primary shell)
- Aliases, environment variables, syntax highlighting colors
- Integrations: fnm (Node), zoxide (cd), starship (prompt), Homebrew

### Key Choices

**Kanagawa Dragon theme**
Consistent color scheme across terminal tools. Colors defined inline rather than sourcing a theme file for simplicity.

**Alias philosophy: short mnemonics**
Git aliases are two letters (`gs`, `gp`, `gl`). APT aliases follow `s` (sudo) + `a` (apt) + action (`i`, `r`, `u`). Fly.io uses app suffix (`flp` = fly logs prod).

**fnm over nvm**
Faster, written in Rust, auto-switches on `.nvmrc` via `--use-on-cd`.

**zoxide over cd**
Smarter directory jumping. `z project` beats `cd ~/src/some/deep/path/project`.

**No fish_greeting**
`set -g fish_greeting` disables the default greeting. Cleaner startup.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Fish docs](https://fishshell.com/docs/current/)
- Related: `starship/` for prompt config
