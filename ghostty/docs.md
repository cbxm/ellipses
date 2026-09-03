# docs: ghostty

Path: @/ghostty

### What This Configures

- **Ghostty** — GPU-accelerated terminal emulator
- Theme, font, keybindings, split/tab behavior
- Auto-launches tmux on startup

### Key Choices

**Kanagawa Dragon / Gruvbox Light themes**
Dark: Kanagawa Dragon (matches fish/tmux/nvim colors). Light: Flexoki Light. Ghostty auto-switches based on GNOME color-scheme preference. Toggle via Settings > Appearance or `gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'`.

**NotoSansM Nerd Font at 10.5pt**
Good readability on laptop display. Nerd Font variant for icons in starship/nvim.

**Auto-launch tmux**
`command = tmux new -A -s 0main` — ghostty becomes a thin wrapper around tmux. Attaches to existing session or creates new one. Leading `0` keeps it sorted with other numbered sessions; status bar strips the digit.

**Tabs hidden**
`gtk-tabs-location = hidden` — tmux handles windowing, ghostty tabs are redundant.

**Shift+Enter sends literal newline**
`keybind = shift+enter=text:\x1b\r` — useful for multiline input in REPLs.

**Ctrl+Backspace deletes word**
`keybind = ctrl+backspace=text:\x17` — standard word-delete behavior.

**Focus follows mouse**
Splits activate on hover, no click required.

**Installed from the mkasberg PPA, not a downloaded `.deb`**
Upstream ships no Linux packages. Newer Ubuntu releases carry Ghostty in the archive, but noble (Pop!_OS 24.04's base) does not, so `ghostty-ubuntu` (mkasberg) is the source here. Carina originally ran a hand-downloaded `.deb` from its GitHub releases, which apt never upgraded because no repo stood behind it (it showed up in `sysup`'s MANUAL list). The project now publishes a Launchpad PPA as its recommended install path, so as of 2026-09 Carina uses that instead and `apt upgrade` (hence `sysup`) keeps Ghostty current. Pop!_OS 24.04 is noble-based, so the noble build applies. New machine setup:

```
sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu && sudo apt install ghostty
```

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Ghostty docs](https://ghostty.org/docs)
- Related: `tmux/` for session management
