# docs: tmux

Path: @/tmux

### What This Configures

- **tmux** — terminal multiplexer
- Prefix key, keybindings, pane/window navigation, status bar
- Plugins: resurrect (persist sessions), continuum (auto-save), fingers (quick copy)

### Key Choices

**Ctrl-A prefix**
`C-a` is closer than `C-b`. Matches GNU screen muscle memory.

**Vim-style navigation**
`h/j/k/l` for pane selection, `H/J/K/L` for resizing. `C-h/j/k/l` are repeatable (`-r` flag).

**Split keys: u/i**
`u` = horizontal (under), `i` = vertical (side-by-side). Mnemonic based on visual orientation.

**New windows open in the current pane's directory**
`w` passes `-c "#{pane_current_path}"` like the splits do. Without it, new windows open in the session's start directory (wherever `tmux new` ran — `~` for Ghostty's `0main`), which is rarely where you're working.

**Window navigation: n/m**
`n` = previous, `m` = next. Adjacent keys, easy to hit repeatedly.

**Status bar**
Custom status format with git branch, CPU/mem/battery scripts, copy-mode indicator.

**Colours follow the terminal's dark/light theme**
Every colour in `tmux.conf` and `scripts/` is an ANSI name (`blue`, `brightblack`, ...) or `default`, never hex. tmux sends those to Ghostty as palette indexes, so they render from whichever Ghostty theme is active, Kanagawa Dragon Cream or Kanagawa Lotus Gray, and change the moment the desktop flips, with no reload and no hook. The hardcoded Kanagawa hex it replaced left the bar dark-on-light and fish's text unreadable in light mode. `set -s theme terminal` does the same for tmux's built-in styles (copy-mode selection, menus, choose-tree, the command prompt). Its default, `detect`, draws those from tmux 3.8's own light and dark colour sets, which wouldn't match Ghostty's palette.

Borders (pane, menu, popup, choose-tree) are `brightblack`, i.e. slot 8. Both Ghostty themes are local variants that set slot 8 for this purpose (see `ghostty/docs.md`). Dark gets `#625e5a`, which the pane borders were as hex. Light gets `#716e61`, darker than the bundled grey, so it stays readable.

Inactive window names are `white` (slot 7), which is the foreground in both themes. Their old `#a6a69c` (7.3:1) isn't a slot in the dark variant any more. Slot 7 (9.8:1) is the closest, while slot 8 (2.8:1) would make them nearly vanish.

Dark mode differs from the old hex in three places:
- Inactive window names are `#c8c093` instead of `#a6a69c`.
- Plain bar text, like the git branch, is the `#c8c093` foreground instead of `#c5c9c5`.
- The bar's slightly lifted background (`#1d1c19` on `#181616`) is now just the terminal background.

**Badge text is the terminal background**
Coloured badges (the active window, PREFIX/ZOOM, datetime, CPU/RAM/swap/battery warnings, COPY MODE, fingers hints) need text that reads on the accent in both themes. Black text on Lotus's accents is 3.0–3.4:1 on blue, red and yellow. The terminal background colour does better on those, but tmux has no colour name for "terminal background" as a foreground. `reverse` gets it: `fg=blue,bg=default,reverse` draws background-coloured text on blue. Contrast ratios:

| badge | text | Dragon Cream | Lotus |
|---|---|---|---|
| blue | terminal bg (`reverse`) | 6.9 | 4.6 |
| red | terminal bg (`reverse`) | 5.2 | 4.1 |
| yellow | terminal bg (`reverse`) | 8.7 | 4.2 |

CPU, RAM, swap and battery only get a badge at their yellow and red levels. At the normal level they're plain text in the terminal's foreground (9.8:1 in Dragon Cream, 6.2:1 in Lotus). They used to sit in green badges, black on green, 4.2:1 in Lotus. That was the hardest text to read of anything on screen all the time. It also meant the bar was loudest when there was nothing to report. Now a badge only appears when a reading needs attention.

Every badge that sets `reverse` clears it afterwards (`noreverse` or `#[default]`). Otherwise it carries into the next segment, and that segment's spaces render as a solid block of colour.

**Built-in UI styles are overridden for Lotus**
With `theme terminal`, tmux's defaults draw menus and popups as black boxes with slot-7 text, and highlights as black text on yellow, cyan or magenta. Kanagawa Lotus's slot 7 is its foreground grey, so in light mode menus were 2.2:1 and copy-mode highlights 3.3–3.7:1. The overrides use the same tools as the badges. Selections (`mode-style`, which choose-tree's selected line and the copy-mode position also use) are plain reverse video. That's how Ghostty draws its own selection. Each selected cell keeps its own colours with reverse on top: default text becomes terminal background on foreground, and coloured text becomes terminal background on that colour. On the scratch server, selected blue text was drawn as SGR 34 + 7, not as plain reverse. So a selection's contrast equals the selected text's normal contrast. Menus and popups use the terminal's own colours, with `brightblack` borders. Contrast ratios:

| style | rendering | Dragon Cream | Lotus | Lotus before |
|---|---|---|---|---|
| `mode-style` (copy selection, tree selection) | reverse video (default-coloured text) | 9.8 | 6.2 | 3.3 |
| `copy-mode-match-style` | black on `brightblue` | 8.6 | 5.1 | 3.5 |
| `copy-mode-current-match-style` | terminal bg on `brightmagenta` | 5.5 | 6.1 | 3.7 |
| `copy-mode-mark-style` | terminal bg on blue | 6.9 | 4.6 | 3.3 |
| `menu-style`, `popup-style` | terminal fg on bg | 9.8 | 6.2 | 2.2 |
| `menu-selected-style` | reverse video | 9.8 | 6.2 | 3.3 |
| menu, popup, choose-tree, display-panes borders | `brightblack` | 2.8 (faint on purpose, like the pane borders) | 4.3 | 2.2 |

Left at tmux's defaults, because they're rarely seen: `message-command-style` (the command prompt after Escape in vi mode, yellow on black, 3.3:1 in Lotus), `switch-mode-match-style` (switch-mode isn't bound), copy-mode line numbers (off), `fill-character` and pane scrollbars (off).

**tmux 3.8 from Homebrew, not apt**
Pop!_OS 24.04 ships tmux 3.4, which never passes a terminal theme change on to programs in its panes. It also answers their OSC 11 "what's the background?" query with the colour it cached at attach. So Claude Code (`theme: auto`) and nvim couldn't follow a flip. tmux 3.6 added mode 2031 (an app subscribes and gets `CSI ? 997 ; 1|2 n` on every change), and 3.8 forwards the terminal's own report instead of guessing from the background. When Ghostty reports a flip, 3.8 re-queries Ghostty's colours first and only then notifies the panes, so an app that re-queries OSC 11 on the notification gets the new colour. Verified 2026-10-20 on a scratch server with a fake outer terminal. New machine: `brew install tmux`, then check that `tmux -V` says 3.8. If it says 3.4, run `brew link tmux`: brew links a formula on install, but one that was unlinked stays unlinked, as on Carina before the cutover. apt's 3.4 stays installed as a fallback. Started with this config, 3.4 reports four errors: `invalid option: theme`, `invalid style: noattr,reverse`, `invalid option: tree-mode-border-style` and `invalid option: display-panes-border-style`. Copy-mode selection then keeps 3.4's default yellow. Those errors are the sign 3.4 is the one that ran.

Which binary runs comes from `PATH` (brew's bin is ahead of `/usr/bin`; see `ghostty/docs.md`), not an absolute path. That's deliberate: the popup binding, `copy-mode-bar` and the plugins all call plain `tmux` from the server's environment, and they have to resolve to the same version as the server (see the gotcha below).

**`allow-passthrough` stays off**
Inside tmux, Claude Code first sends its OSC 11 query wrapped in a DCS passthrough. With passthrough on, the query does reach Ghostty, but tmux reads Ghostty's answer as a reply to its own colour query and keeps it, so the pane never sees it. Checked in the tmux 3.8 source (`tty_keys_colours`) and on the scratch server. Claude gives up on the wrapped query after its timeout and sends a plain OSC 11, which tmux answers from the colour it just refreshed. Passthrough would add nothing here, and it would give every pane a raw channel to the outer terminal.

**Scroll speed: 1 line**
Default is 5 lines per wheel tick — too fast. Changed to 1 line for precision.

**Mouse double/triple click: select only**
Doesn't auto-copy on mouse release. Must explicitly yank with `y` or Enter.

**Popup terminal**
`prefix + p` toggles a floating `1popup` session (leading `1` keeps it sorted with other numbered sessions; status bar strips the digit). Quick scratchpad without disrupting layout.

**Pane borders at top**
`pane-border-status top` with empty format — shows thick line only, no text. Border turns red in copy mode.

### Workarounds & Gotchas

**`@resurrect-never-overwrite on` — do not remove**
Without it, resurrect's "restore from scratch" mode (used on a fresh server, i.e. every reboot) finishes with `tmux kill-session -t 0` to remove the throwaway session a bare `tmux` creates. No session is named exactly `0`, so tmux falls back to prefix matching and `-t 0` resolves to `0main` — the session Ghostty is attached to. Ghostty's `tmux new -A -s 0main` command exits and the window closes right after "Restoring...". The option skips from-scratch mode entirely; the pre-existing `0main` pane is kept as-is (fresh fish in `~`, same as what was saved) and every other session restores normally.

**`#{T:status-right}` at the end of `status-format[0]` — do not remove**
tmux-continuum has no daemon: it appends `#(continuum_save.sh)` to `status-right` and relies on the status line re-running it every refresh. The custom `status-format[0]` replaces the default layout, which is what normally renders `status-right`, so auto-save never fired under this config; the few files in `~/.local/share/tmux/resurrect/` before the fix were manual saves. Rendering `status-right` explicitly brings it back; the script prints nothing, so the bar looks the same. resurrect never prunes saves, so a working auto-save leaves a steady trickle of files there; a sparse directory means it is broken again.

The second way it dies: continuum only adds its trigger when no *other* tmux server is running at load time, and `tmux -L` scratch servers count. Reloading (`prefix r`) while a scratch server is up resets `status-right` to `""` and leaves it empty. Kill scratch servers before reloading.

**Client and server must be the same tmux version**
Changing tmux versions means restarting the server:

1. Save with `prefix C-s`.
2. If the new tmux is brew's and isn't linked yet, run `brew link tmux`, then check `tmux -V`.
3. `tmux kill-server`.
4. Reopen Ghostty. Continuum restores the sessions. Mixing versions breaks differently in each direction (both verified 2026-10-20):

- A 3.4 client against a 3.8 server fails on every command, `tmux ls` included, with `server exited unexpectedly`. The server is fine; it's the client that gave up. So `tmux ls` from the old binary tells you nothing about whether the server is up.
- A 3.8 client can run commands against a 3.4 server (`tmux ls`, `display -p`, `kill-server`), but attaching fails with `open terminal failed: not a terminal`.

In practice, Ghostty windows close as soon as they open, the `prefix p` popup closes immediately, and the status scripts and plugins, which call `tmux` from the server's `PATH`, quietly stop working. A `brew upgrade` (via `sys up`) that moves tmux to a new version under a running server could do the same, so if new windows start closing right after an update, check this first.

### See Also

- [tmux wiki](https://github.com/tmux/tmux/wiki)
- Plugins: [tpm](https://github.com/tmux-plugins/tpm), [resurrect](https://github.com/tmux-plugins/tmux-resurrect), [fingers](https://github.com/Morantron/tmux-fingers)
- Related: `ghostty/` auto-launches tmux
