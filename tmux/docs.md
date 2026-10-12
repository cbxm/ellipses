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

**Kanagawa Dragon status bar**
Custom status format with git branch, CPU/mem/battery scripts, copy-mode indicator. Colors match fish/ghostty.

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

### See Also

- [tmux wiki](https://github.com/tmux/tmux/wiki)
- Plugins: [tpm](https://github.com/tmux-plugins/tpm), [resurrect](https://github.com/tmux-plugins/tmux-resurrect), [fingers](https://github.com/Morantron/tmux-fingers)
- Related: `ghostty/` auto-launches tmux
