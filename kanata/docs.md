# docs: kanata

Path: @/kanata

### What This Configures

- **Kanata** — keyboard remapping daemon for Linux
- Homerow mods on the laptop's internal keyboard (Lily58 handles its own via QMK)
- Caps Lock → Escape, nav layer on right Alt

### Key Choices

**Modifier order: SGAC (Shift-GUI-Alt-Ctrl)**
Pinky to index. Matches Lily58 layout for muscle memory consistency. Ctrl on index fingers since it's the most used modifier.

**Laptop keyboard only**
`linux-dev` targets `platform-i8042-serio-0-event-kbd` — the internal laptop keyboard. External keyboards (including Lily58) are unaffected since they have their own firmware.

**tap-hold-release for most keys**
Resolves issues with rapid typing and held modifiers. F and J use faster 200ms activation (index fingers, most used). Outer fingers use 500ms to reduce accidental triggers.

**A uses plain tap-hold at 300ms**
`tap-hold` is less likely to trigger on rolling keypresses than `tap-hold-release`. A-Shift rarely used for capitals anyway — mainly for combo modifiers (Ctrl+Shift+X), so quick activation isn't needed.

**L uses plain tap-hold at 250ms**
Same rationale as A — `tap-hold` reduces accidental activations from rolling. Slightly shorter timeout than A since GUI combos feel more latency-sensitive.

**Caps Lock → Escape**
Escape in home position. Standard vim ergonomics.

**Nav layer on right Alt**
Hold right Alt to get: `h/j/k/l` → arrows, `n/m/,/.` → home/pgdn/pgup/end. Vim-style navigation everywhere.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Kanata docs](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
- Related: Lily58 firmware handles its own homerow mods via QMK
