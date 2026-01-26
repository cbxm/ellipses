# docs: gh

Path: @/gh

### What This Configures

- **GitHub CLI** — command-line GitHub interface
- Protocol preference, aliases

### Key Choices

**HTTPS protocol**
`git_protocol: https` — works everywhere, gh handles auth via `gh auth login`.

**`co` alias for PR checkout**
`gh co 123` instead of `gh pr checkout 123`. Common operation, worth shortening.

**Tokens not tracked**
`~/.config/gh/hosts.yml` contains auth tokens — excluded from this repo. Run `gh auth login` on new machines.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [gh CLI docs](https://cli.github.com/manual/)
- Related: `git/` uses gh as credential helper
