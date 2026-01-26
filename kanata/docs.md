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
The shift key is special — `tap-hold-release` caused issues with fast repeated A presses. Plain `tap-hold` with slightly longer timeout works better.

**L uses plain tap-hold at 250ms**
GUI key needed faster activation than the 500ms default. Switched from `tap-hold-release` to `tap-hold` for snappier response.

**Caps Lock → Escape**
Escape in home position. Standard vim ergonomics.

**Nav layer on right Alt**
Hold right Alt to get: `h/j/k/l` → arrows, `n/m/,/.` → home/pgdn/pgup/end. Vim-style navigation everywhere.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Kanata docs](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
- Related: Lily58 firmware handles its own homerow mods via QMK
