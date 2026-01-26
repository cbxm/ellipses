# docs: starship

Path: @/starship

### What This Configures

- **Starship** — cross-shell prompt
- Module format overrides (strips version numbers)

### Key Choices

**Hide version numbers**
All language modules use `format = 'via [$symbol]($style)'` — shows icon only, no version string. Keeps prompt compact.

**Default everything else**
Starship's defaults are sensible. Only override what's noisy.

### Workarounds & Gotchas

*(none yet)*

### See Also

- [Starship docs](https://starship.rs/)
- Related: `fish/` sources starship
