# docs: ghostty

Path: @/ghostty

### What This Configures

- **Ghostty** — GPU-accelerated terminal emulator
- Theme, font, keybindings, split/tab behavior
- Auto-launches tmux on startup

### Key Choices

**Kanagawa Dragon Cream / Flexoki Light themes**
Dark: `Kanagawa Dragon Cream`, a local variant in `themes/` (matches fish/tmux/nvim colors). Light: Flexoki Light. Ghostty auto-switches based on the desktop color-scheme preference (the freedesktop portal setting; COSMIC exposes it in Settings > Appearance, and `gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'` also works).

Why a local variant: the Kanagawa Dragon theme bundled with Ghostty changed its foreground from `#c8c093` (warm cream) to `#c5c9c5` (cool grey) in upstream iTerm2-Color-Schemes #653 (2026-01-25), which landed here with the Ghostty 1.2.3 → 1.3.1 upgrade on 2026-09-03. Upstream calls the grey the correct `dragonWhite`; the cream is simply what Carina has always looked like. The variant is a byte-for-byte copy of the bundled 1.3.1 file with only `foreground` changed, so the corrected cursor/selection colours are kept. User themes in `~/.config/ghostty/themes/` shadow bundled ones by name; a distinct name was chosen so `ghostty +list-themes` and the config line make the override obvious. Setting a bare `foreground =` in `config` was rejected because it would also override Flexoki Light's foreground in light mode.

**Maple Mono at 10pt**
Good readability on laptop display. This is the plain build, not `Maple Mono NF`: powerline glyphs (U+E0B0) are present, but the wider Nerd Font icon ranges are not, so starship/nvim icons render via fontconfig fallback.

**Auto-launch tmux**
`command = tmux new -A -s 0main` — ghostty becomes a thin wrapper around tmux. Attaches to existing session or creates new one. Leading `0` keeps it sorted with other numbered sessions; status bar strips the digit. That leading `0` is why tmux sets `@resurrect-never-overwrite` — see the gotcha in `tmux/docs.md`.

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

**`~/.config/ghostty` is not a folded symlink**
An untracked `config.526c5393.bak` sits in the real directory, so stow links files individually. Adding a new file or directory to this package (e.g. `themes/`) needs `stow -R ghostty` before Ghostty can see it.

### See Also

- [Ghostty docs](https://ghostty.org/docs)
- Related: `tmux/` for session management
