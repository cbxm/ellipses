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

**Pane cycling that keeps zoom: o/O, M-o/M-O**
Default `prefix + o` unzooms the window when it switches panes, so there is no way to page through panes one at a time at full size. `select-pane -Z` (tmux 3.1+) re-applies zoom to the pane it lands on, so `o` walks forward and `O` back without ever showing the layout. `M-o`/`M-O` are the repeatable (`-r`) variants for holding the prefix and tapping to scan, following the same plain-key/`M-` split as the rest of the file. The plain keys must *not* be `-r`: repeat keeps the prefix table live for `repeat-time` afterwards, so the first keystroke typed into the pane you just landed on gets swallowed if it happens to be bound there with `-r` — a bare `o` would cycle again instead of opening a line in vim, and `H` would resize and drop the zoom. (Non-`-r` bindings are safe: matching one ends the repeat and the key reaches the pane.) `M-o`/`M-O` shadow the default `rotate-window -D`/`-U`, which is a trade worth making here; `C-o` still rotates forward. `h/j/k/l` deliberately keep the default unzoom behaviour — directional moves only make sense once the layout is visible.

**Split keys: u/i**
`u` = horizontal (under), `i` = vertical (side-by-side). Mnemonic based on visual orientation.

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

### See Also

- [tmux wiki](https://github.com/tmux/tmux/wiki)
- Plugins: [tpm](https://github.com/tmux-plugins/tpm), [resurrect](https://github.com/tmux-plugins/tmux-resurrect), [fingers](https://github.com/Morantron/tmux-fingers)
- Related: `ghostty/` auto-launches tmux
