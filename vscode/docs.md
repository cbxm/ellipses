# docs: vscode

Path: @/vscode

### What This Configures

- **VS Code** — graphical editor (secondary to nvim)
- Settings, file nesting, terminal profiles

### Key Choices

**Activity bar at top**
`workbench.activityBar.location: top` — more vertical space for code.

**Auto-save on focus change**
`files.autoSave: onFocusChange` — no manual saving needed.

**Rulers at 90 and 120**
Visual guides for line length. 90 for comfort, 120 for hard limit.

**No minimap**
`editor.minimap.enabled: false` — visual noise, rarely useful.

**File nesting**
Groups related files: `package.json` nests lockfiles, `*.ts` nests `.js`/`.d.ts`.

**MesloLGS NF font**
Nerd Font for terminal and editor. Same as system terminal.

**WSL/Windows terminal profiles**
Config includes Windows-specific terminal profiles (Git Bash, Ubuntu WSL). Portable across machines.

**AI features disabled**
`chat.disableAIFeatures: true` — using Claude Code instead of Copilot.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [VS Code docs](https://code.visualstudio.com/docs)
- Related: `nvim/` for terminal editing
