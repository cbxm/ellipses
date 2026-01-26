# docs: bash

Path: @/bash

### What This Configures

- **Bash** — fallback shell for scripts and compatibility
- Mostly stock Ubuntu `.bashrc` with minor additions

### Key Choices

**Fallback shell, not primary**
Fish is the daily driver. Bash exists for:
- Scripts with `#!/bin/bash`
- Environments where fish isn't installed
- Compatibility testing

**Minimal customization**
Stock Ubuntu defaults plus PATH additions (flyctl, .local/bin). No aliases beyond defaults — use fish for interactive work.

### Workarounds & Gotchas

*(none yet)*

### See Also

- Related: `fish/` for primary shell config
