# docs: fish

Path: @/fish

### What This Configures

- **Fish** — friendly interactive shell (primary shell)
- Aliases, environment variables, syntax highlighting colors
- Integrations: fnm (Node), zoxide (cd), starship (prompt), Homebrew

### Key Choices

**Kanagawa Dragon theme**
Consistent color scheme across terminal tools. Colors defined inline rather than sourcing a theme file for simplicity.

**Alias philosophy: short mnemonics**
Git aliases are two letters (`gs`, `gp`, `gl`). APT aliases follow `s` (sudo) + `a` (apt) + action (`i`, `r`, `u`). Fly.io uses app suffix (`flp` = fly logs prod).

**fnm over nvm**
Faster, written in Rust, auto-switches on `.nvmrc` via `--use-on-cd`.

**zoxide over cd**
Smarter directory jumping. `z project` beats `cd ~/src/some/deep/path/project`.

**No fish_greeting**
`set -g fish_greeting` disables the default greeting. Cleaner startup.

**`sysup`: one command for every update surface**
`functions/sysup.fish`. Carina accumulated ~10 independent package managers beyond apt (flatpak, brew, uv, bun, cargo, gh extensions, fwupd) and `sauu` only covered apt, so things silently went stale. `sysup` runs them all in sequence. Design choices:

- Every non-apt step is guarded by `command -q <tool>`, so the same function works on lynx (apt only) without per-machine conditionals.
- Interactive by default, matching `sauu`; `-y` opts into unattended apt/flatpak. The other tools never prompt so need no flag. `-n` prints each command instead of running it.
- Every step goes through `_sysup_run`, which records the label of any step that exits non-zero. Failures don't abort the run (one broken tool shouldn't block the rest), but they're listed under a red `FAILED:` heading at the end and `sysup` returns 1, so `sysup; and ...` chaining works. The one ordering dependency is honored: `apt upgrade` only runs if `apt update` succeeded, since upgrading against stale lists is worse than skipping.
- `brew update` runs explicitly before `brew upgrade`. brew's built-in auto-update is throttled to once per 24h (`HOMEBREW_AUTO_UPDATE_SECS`), so `brew upgrade` alone can silently work from stale metadata if any brew command ran recently.
- fwupd is refresh + report only. Firmware installs stay a deliberate manual step. `fwupdmgr get-updates` exits 2 when nothing is pending; that's popped back off the failure list rather than reported.
- Ends with reminders for what it can't do: **REBOOT** if the newest `/boot/vmlinuz-*` isn't the running kernel (found a kernel installed-but-not-booted during the investigation), and **MANUAL** for debs apt tags `[installed,local]`, i.e. installed from a downloaded `.deb` with no repo behind them. `linux-*` is excluded from that list because old kernels also flip to local once the repo drops them; that's autoremove's job.

Deliberately out of scope: npm globals per fnm node version, tmux/nvim plugins, docker image pulls, `pop-upgrade`. Either not "safe" to run blind or not worth the surface area yet.

### Workarounds & Gotchas

**`sysup` cargo step needs the `cargo-update` crate**
Plain cargo has no "upgrade all installed binaries". If `cargo-install-update` isn't on PATH the step prints a hint instead of running. Not installed on Carina as of 2026-09.

**`sysup` MANUAL debs are still manual**
The reminder only names them (obsidian, openlogi, speedtest at time of writing). Re-downloading the `.deb` and `sai`-ing it is on you; nothing tracks upstream versions. Ghostty used to be on this list; it moved to a PPA (see `ghostty/docs.md`).

**`sysup` kernel detection avoids globs**
Newest kernel is `ls -v /boot | string replace -rf '^vmlinuz-' ''`, not `/boot/vmlinuz-*`. A fish wildcard that matches nothing prints its own error that `2>/dev/null` can't suppress, which matters in containers/WSL where `/boot` is empty.

### See Also

- [Fish docs](https://fishshell.com/docs/current/)
- Related: `starship/` for prompt config
