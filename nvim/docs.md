# docs: nvim

Path: @/nvim

### What This Configures

- **Neovim** — terminal editor (primary)
- lazy.nvim plugin manager bootstrap, basic options

### Key Choices

**Semicolon as leader**
`vim.g.mapleader = ";"` — home row, easy to reach. Unconventional but comfortable.

**2-space indentation**
`shiftwidth = 2`, `tabstop = 2`, `expandtab = true` — matches JS/TS ecosystem conventions.

**System clipboard**
`clipboard = "unnamedplus"` — yank/paste integrates with system clipboard.

**Smart case search**
`ignorecase = true` + `smartcase = true` — lowercase searches are case-insensitive, uppercase forces exact match.

**Minimal plugin setup**
lazy.nvim bootstrapped but no plugins configured yet. Intentionally bare — add plugins as needed.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Neovim docs](https://neovim.io/doc/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
