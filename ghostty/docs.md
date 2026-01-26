# docs: ghostty

Path: @/ghostty

### What This Configures

- **Ghostty** — GPU-accelerated terminal emulator
- Theme, font, keybindings, split/tab behavior
- Auto-launches tmux on startup

### Key Choices

**Kanagawa Dragon theme**
Built-in theme, matches fish/tmux/nvim colors.

**NotoSansM Nerd Font at 10.5pt**
Good readability on laptop display. Nerd Font variant for icons in starship/nvim.

**Auto-launch tmux**
`command = tmux new -A -s main` — ghostty becomes a thin wrapper around tmux. Attaches to existing session or creates new one.

**Tabs hidden**
`gtk-tabs-location = hidden` — tmux handles windowing, ghostty tabs are redundant.

**Shift+Enter sends literal newline**
`keybind = shift+enter=text:\x1b\r` — useful for multiline input in REPLs.

**Ctrl+Backspace deletes word**
`keybind = ctrl+backspace=text:\x17` — standard word-delete behavior.

**Focus follows mouse**
Splits activate on hover, no click required.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Ghostty docs](https://ghostty.org/docs)
- Related: `tmux/` for session management
