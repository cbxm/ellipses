# wireplumber

WirePlumber session-manager overrides for PipeWire. Drop-ins in `wireplumber.conf.d/`
layer on top of `/usr/share/wireplumber/wireplumber.conf` — never edit that file directly,
it is package-owned and overwritten on upgrade.

Apply changes with `systemctl --user restart wireplumber` (this cuts audio briefly).

## bluetooth-audio.conf

Bluetooth headsets run **full duplex**: stereo A2DP for playback, HFP for the mic.

This file previously did the opposite — it stripped `bluez5.roles` down to A2DP and set
`hfphsp-backend = "none"` so a mic could never be offered, deliberately, to stop apps
dragging the headset out of stereo. That was reversed on 2026-08-21 when the earbuds became
the primary call device.

**The tradeoff that motivated the old lockout still exists**, it is just scoped now. HFP is
mono and much worse than A2DP; `bluez5.enable-msbc` keeps it wideband (16 kHz) rather than
telephone-grade (8 kHz), but it is still audibly a step down.

The switch is narrower than it looks. `device/autoswitch-bluetooth-profile.lua`
(`checkStreamStatus`) resolves a capture stream's *peer* and only switches profile if that
peer is the headset's loopback source. Capture from the Focusrite or the internal array and
the headset stays in A2DP — merely having a mic open somewhere does not trigger it.

Practical consequence: because the headset mic outranks the internal array, **with the
Focusrite unplugged the earbuds become the default mic and calls will drop to HFP.** Keep
the 2i2 connected to stay in stereo, or set
`bluetooth.autoswitch-to-headset-profile = false` to never switch.

Role names are from our side: `hfp_ag`/`hsp_ag` mean this machine is the Audio Gateway and
the headset is the hands-free unit. `hfp_hf`/`hsp_hf` are the reverse, for connecting to a
phone. Both are listed so either direction works.

## 50-default-priorities.conf

Sets `priority.session` so the right device wins automatically instead of needing a manual
pick after every reconnect.

| | Order (highest first) |
|---|---|
| Outputs | bluetooth 2000 → Focusrite 1500 → HDMI 1200 → internal 1000 |
| Inputs | Focusrite 2500 → bluetooth 2010 → internal 1500 → StreamCam 500 |

The StreamCam mic is deliberately last so the webcam never silently becomes the default mic.

**Bluetooth sinks are matched by pattern, not MAC.** Per-device rules were a trap: every new
pair of earbuds silently landed at the default 1010 and lost to HDMI at 1500 until someone
noticed. Note the syntax — a leading `~` makes the value a regular expression. A plain glob
like `bluez_output.*` matches nothing here and fails silently.

**There is deliberately no rule for bluetooth sources.** The headset mic is exposed as a
loopback node created with `LocalModule` (`scripts/monitors/bluez.lua:130`), which never
passes through `monitor.bluez.rules` — a rule there is dead config. Its priority is
hardcoded to 2010 (same file, `:283`). That already sits between the Focusrite and the
internal array, so instead of fighting it the internal array is lowered to 1500 to keep a
comfortable gap.

### Gotcha: priority only breaks ties

A user-pinned default stored as `default.configured.audio.sink` in
`~/.local/state/wireplumber/default-nodes` **overrides priority entirely**. If a connected
device still refuses to become the output, that state file is the thing to inspect — not
this config. Repoint it with `wpctl set-default <id>`; never hand-edit it, as WirePlumber
holds the state in memory and rewrites the file on exit.

## Verifying

```bash
pactl get-default-sink
pw-cli info <node.name> | grep priority.session   # confirm a rule actually applied
pactl list short sources | grep bluez             # headset mic present?
pactl list cards | grep 'Active Profile'          # should be a2dp-sink when not on a call
```

## Troubleshooting

### Playback is pitched down / plays slow

The A2DP transport and the node disagree on sample rate. This shows up after restarting
WirePlumber **while audio is playing** — the transport keeps a stale format while the node
comes back at a different rate. Renegotiate by bouncing the profile:

```bash
pactl set-card-profile bluez_card.<MAC_WITH_UNDERSCORES> off && sleep 1 && \
pactl set-card-profile bluez_card.<MAC_WITH_UNDERSCORES> a2dp-sink
```

Cheapest avoidance: pause audio before `systemctl --user restart wireplumber`.

### A connected device won't become the default

Priorities in `50-default-priorities.conf` only break ties between candidates. A pinned
default in `~/.local/state/wireplumber/default-nodes` beats them outright:

```
default.configured.audio.sink=...      # the active pin
default.configured.audio.sink.0=...    # fallback list, in order
```

Those pins accumulate silently — every manual pick in the sound settings writes one, and the
fallback list keeps entries for hardware that no longer exists. To hand control back to
priority, delete the pin rather than editing the file (WirePlumber holds it in memory and
rewrites it on exit):

```bash
pw-metadata -n default -d 0 default.configured.audio.sink
pw-metadata -n default -d 0 default.configured.audio.source
```

Both were cleared on 2026-08-21; the file is empty and selection is purely priority-driven.
Re-pin only if you want a device to win *regardless* of priority.
