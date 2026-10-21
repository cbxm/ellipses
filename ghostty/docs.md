# docs: ghostty

Path: @/ghostty

### What This Configures

- **Ghostty** — GPU-accelerated terminal emulator
- Theme, font, keybindings, split/tab behavior
- Auto-launches tmux on startup

### Key Choices

**Kanagawa Dragon Cream / Kanagawa Lotus Gray themes**
Dark: `Kanagawa Dragon Cream`. Light: `Kanagawa Lotus Gray`. Both are local variants in `themes/`. Light mode is Kanagawa because that palette is the one Caden likes, and Lotus is its official light variant (it replaced Flexoki Light on 2026-10-20). Ghostty auto-switches based on the desktop color-scheme preference, which is the freedesktop portal setting, set in COSMIC under Settings > Appearance. On COSMIC, `gsettings set org.gnome.desktop.interface color-scheme` does not change it: on 2026-10-20, setting `prefer-light` left the portal's `color-scheme` at dark.

Everything inside Ghostty follows the switch live. tmux and fish colour only with ANSI names, so they render from whichever palette is active (see `tmux/docs.md`, `fish/docs.md`). Ghostty also tells programs about the change (mode 2031). tmux 3.8 passes that on to its panes, so Claude Code re-reads the background and switches too. That needs `"theme": "auto"` in `~/.claude.json`, which is machine-local and untracked, so set it on each machine. nvim (apt's 0.9.5, no colorscheme set) only checks the background when it starts, so an nvim that's already open keeps the old `background`.

Why a local dark variant: the Kanagawa Dragon theme bundled with Ghostty changed its foreground from `#c8c093` (warm cream) to `#c5c9c5` (cool grey) in upstream iTerm2-Color-Schemes #653 (2026-01-25), which landed here with the Ghostty 1.2.3 → 1.3.1 upgrade on 2026-09-03. Upstream calls the grey the correct `dragonWhite`; the cream is simply what Carina has always looked like. The variant is a byte-for-byte copy of the bundled 1.3.1 file with two changes, so the corrected cursor/selection colours are kept. One is `foreground`. The other is `palette = 8`, changed from `#a6a69c` (`dragonGray`) to `#625e5a` (`dragonBlack6`) on 2026-10-20, when tmux and fish switched to ANSI names. Before that, their muted elements were hardcoded to `#625e5a`. Now they use slot 8, and the bundled `#a6a69c` made autosuggestions look like typed text and inactive pane borders nearly as bright as the active one. At 2.8:1 on `#181616`, `#625e5a` is deliberately faint, as those elements always were. Side effect: every other program that prints bright black (ANSI 90), including some `ls` and `git` output, is now dimmer in dark mode than under the bundled theme. User themes in `~/.config/ghostty/themes/` shadow bundled ones by name; a distinct name was chosen so `ghostty +list-themes` and the config line make the override obvious. Setting a bare `foreground =` in `config` was rejected because it would also override the light theme's foreground.

Why a local light variant: most muted elements in tmux and fish (pane and menu borders, autosuggestions, comments, pager descriptions) use ANSI slot 8, since those tools use colour names only. The bundled Lotus slot 8, `#8a8980` (`lotusGray3`), is 2.9:1 on its `#f2ecbc` background, which is too faint to read. `Kanagawa Lotus Gray` is a byte-for-byte copy of the bundled 1.3.1 `Kanagawa Lotus` with only `palette = 8` changed, to `#716e61`. That's `lotusGray2`, another colour from Kanagawa's own Lotus palette: 4.3:1 on the background and still clearly greyer than the `#545464` foreground (6.2:1). Its name follows the Dragon Cream pattern. Fixing it in the theme rather than in tmux and fish keeps those tools on plain ANSI names. Two Lotus accents are borderline as text, left as upstream ships them: green (`#6f894e`, 3.3:1) for fish strings and magenta (`#b35b79`, 3.7:1) for fish keywords.

**Maple Mono at 10pt**
Good readability on laptop display. This is the plain build, not `Maple Mono NF`: powerline glyphs (U+E0B0) are present, but the wider Nerd Font icon ranges are not, so starship/nvim icons render via fontconfig fallback.

**Auto-launch tmux**
`command = tmux new -A -s 0main` — ghostty becomes a thin wrapper around tmux. Attaches to existing session or creates new one. Leading `0` keeps it sorted with other numbered sessions; status bar strips the digit. That leading `0` is why tmux sets `@resurrect-never-overwrite` — see the gotcha in `tmux/docs.md`.

`tmux` here is a bare name, and it has to resolve to Homebrew's tmux 3.8 (`tmux/docs.md` says why). It does, because Ghostty runs as the systemd user service `app-com.mitchellh.ghostty.service`, and that manager's `PATH` comes from the fish login environment, where `brew shellenv` puts `/home/linuxbrew/.linuxbrew/bin` ahead of `/usr/bin`. The tmux server inherits that `PATH`, so the `tmux` calls its scripts and plugins make resolve to the same binary. An absolute path here would pin only the server, and if `PATH` ever lost brew, those calls would quietly reach 3.4, which can't run any command against a 3.8 server. With the bare name, losing brew starts a 3.4 server instead, and its config errors show right away (`tmux/docs.md` lists them). Check with `systemctl --user show-environment | grep ^PATH`. Brew's tmux also has to be linked: if `tmux -V` in a new shell says 3.4, run `brew link tmux`. On Carina it was installed and then unlinked until the 3.8 cutover.

**Tabs hidden**
`gtk-tabs-location = hidden` — tmux handles windowing, ghostty tabs are redundant.

**Shift+Enter sends literal newline**
`keybind = shift+enter=text:\x1b\r` — useful for multiline input in REPLs.

**Ctrl+Backspace deletes word**
`keybind = ctrl+backspace=text:\x17` — standard word-delete behavior.

**Focus follows mouse**
Splits activate on hover, no click required.

**Installed from the mkasberg PPA, not a downloaded `.deb`**
Upstream ships no Linux packages. Newer Ubuntu releases carry Ghostty in the archive, but noble (Pop!_OS 24.04's base) does not, so `ghostty-ubuntu` (mkasberg) is the source here. Carina originally ran a hand-downloaded `.deb` from its GitHub releases, which apt never upgraded because no repo stood behind it (it showed up in `sysup`'s MANUAL list). The project now publishes a Launchpad PPA as its recommended install path, so as of 2026-09 Carina uses that instead and `apt upgrade` (hence `sys up`) keeps Ghostty current. Pop!_OS 24.04 is noble-based, so the noble build applies. New machine setup:

```
sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu && sudo apt install ghostty
```

### Workarounds & Gotchas

**`~/.config/ghostty` is not a folded symlink**
An untracked `config.526c5393.bak` sits in the real directory, so stow links files individually. Adding a new file or directory at the top of this package needs `stow -R ghostty` before Ghostty can see it. `themes/` itself is a single symlink to the repo directory, so a new theme file inside it shows up without a re-stow.

### See Also

- [Ghostty docs](https://ghostty.org/docs)
- Related: `tmux/` for session management
