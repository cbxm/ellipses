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

**`sys`: one front door for system tools**
`functions/sys.fish`. The system-management commands kept getting forgotten (`sysup`, `conserve`, an `audioauto` alias), so they all live under `sys` now. Bare `sys` lists them, and `sys <TAB>` completes them with descriptions.

- Subcommands are discovered by name. Any function `sys_<name>` on the function path becomes `sys <name>`, and its `--description` is the help text. Adding a tool means adding `functions/sys_<name>.fish`, with no list to update. `__sys_list` does the discovery for both the bare listing and `completions/sys.fish`. Helpers for a subcommand need a leading underscore (`_sys_up_run`), or they'd show up as subcommands too.
- The old top-level names were removed rather than aliased, so there's one way to call each thing.
- `sys audio` is the former `audioauto` alias. `wpctl clear-default` drops the sticky default output/input so WirePlumber's device priorities (see `wireplumber/docs.md`) pick again.

**`sys up`: one command for every update surface**
`functions/sys_up.fish`. Carina accumulated ~10 independent package managers beyond apt (flatpak, brew, uv, bun, cargo, gh extensions, fwupd) and `sauu` only covered apt, so things silently went stale. `sys up` runs them all in sequence. Design choices:

- Every non-apt step is guarded by `command -q <tool>`, so the same function works on lynx (apt only) without per-machine conditionals.
- Interactive by default, matching `sauu`; `-y` opts into unattended apt/flatpak. The other tools never prompt so need no flag. `-n` prints each command instead of running it.
- Every step goes through `_sys_up_run`, which records the label of any step that exits non-zero. Failures don't abort the run (one broken tool shouldn't block the rest), but they're listed under a red `FAILED:` heading at the end and `sys up` returns 1, so `sys up; and ...` chaining works. The one ordering dependency is honored: `apt upgrade` only runs if `apt update` succeeded, since upgrading against stale lists is worse than skipping.
- `brew update` runs explicitly before `brew upgrade`. brew's built-in auto-update is throttled to once per 24h (`HOMEBREW_AUTO_UPDATE_SECS`), so `brew upgrade` alone can silently work from stale metadata if any brew command ran recently.
- fwupd is refresh + report only. Firmware installs stay a deliberate manual step. `fwupdmgr get-updates` exits 2 when nothing is pending; that's popped back off the failure list rather than reported.
- Ends with reminders for what it can't do: **REBOOT** if the newest `/boot/vmlinuz-*` isn't the running kernel (found a kernel installed-but-not-booted during the investigation), and **MANUAL** for debs apt tags `[installed,local]`, i.e. installed from a downloaded `.deb` with no repo behind them. `linux-*` is excluded from that list because old kernels also flip to local once the repo drops them; that's autoremove's job.

Deliberately out of scope: npm globals per fnm node version, tmux/nvim plugins, docker image pulls, `pop-upgrade`. Either not "safe" to run blind or not worth the surface area yet.

**`sys battery`: battery conservation mode toggle**
`functions/sys_battery.fish`. Carina's EC drops any non-Lenovo USB-C PD charger 5–21 min after the battery finishes charging to 100%, then runs on battery until the cable is replugged. Tested 2026-09-23: nothing on the host brings the charger back, including unloading `ucsi_acpi`. Conservation mode caps the battery at ~80%, and at that cap the charger stays connected, both when sitting above the cap and when charging up to it and stopping. So conservation mode stays on day to day, and `sys battery` turns it off before a trip that needs 100%.

- It writes `charge_types` (`Long_Life` / `Fast`) rather than the legacy `conservation_mode` attribute. `charge_types` flips the conservation and Rapid Charge bits together, and "off" restores Rapid Charge, which was the setting before conservation mode.
- Rapid Charge being off costs nothing on third-party chargers: 10→80% took 80 min, at the same wattage as with Rapid on. The charger is the bottleneck.
- It's guarded by the ideapad sysfs path, not a hostname, so on lynx it just prints an error.

### Workarounds & Gotchas

**`sys up` cargo step needs the `cargo-update` crate**
Plain cargo has no "upgrade all installed binaries". If `cargo-install-update` isn't on PATH the step prints a hint instead of running. Building it needs `libssl-dev` (the `openssl-sys` crate fails with "Could not find directory of OpenSSL installation" without it): `sai libssl-dev && cargo install cargo-update`.

**`sys up` MANUAL debs are still manual**
The reminder only names them (obsidian, openlogi, speedtest at time of writing). Re-downloading the `.deb` and `sai`-ing it is on you; nothing tracks upstream versions. Ghostty used to be on this list; it moved to a PPA (see `ghostty/docs.md`).

**`sys up` kernel detection avoids globs**
Newest kernel is `ls -v /boot | string replace -rf '^vmlinuz-' ''`, not `/boot/vmlinuz-*`. A fish wildcard that matches nothing prints its own error that `2>/dev/null` can't suppress, which matters in containers/WSL where `/boot` is empty.

**`sys battery` reads `conservation_mode`, not `charge_types`**
Reading `charge_types` on Carina occasionally fails with `Invalid argument`, and the kernel logs "unexpected charge_types: both [Fast] and [Long_Life] are enabled". It happens when the EC briefly reports both battery-mode bits set, apparently around battery uevents, when the kernel logs the line about once a minute; a plain `cat` almost always succeeds. The legacy `conservation_mode` attribute checks only the conservation bit, so it never hits the both-set rejection. The glitch is harmless.

**`completions/sys.fish` needs a re-stow**
Unlike `functions/` and `conf.d/`, which stow links as whole directories, `~/.config/fish/completions` is a real directory on Carina, since bun writes its completions there. So stow links `sys.fish` into it as a single file, and a new file in `completions/` only appears after `stow fish` is re-run, on each machine.

### See Also

- [Fish docs](https://fishshell.com/docs/current/)
- Related: `starship/` for prompt config
