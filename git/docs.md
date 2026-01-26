# docs: git

Path: @/git

### What This Configures

- **Git** — version control
- Editor, credential helper, identity include

### Key Choices

**Identity in ~/.gitconfig.local**
`[include] path = ~/.gitconfig.local` keeps name/email out of this public repo. Create locally:
```ini
[user]
    name = Your Name
    email = your@email.com
```

**gh as credential helper**
`gh auth git-credential` handles GitHub HTTPS auth. No PATs to manage manually.

**nvim as editor**
Commit messages, interactive rebase, etc. open in nvim.

**Minimal config**
Most git settings use defaults. Aliases live in fish, not gitconfig.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Git config docs](https://git-scm.com/docs/git-config)
- Related: `gh/` for GitHub CLI
