# wireplumber

WirePlumber session-manager overrides for PipeWire. Drop-ins in `wireplumber.conf.d/`
layer on top of `/usr/share/wireplumber/wireplumber.conf` — never edit that file directly,
it is package-owned and overwritten on upgrade.

Apply changes with `systemctl --user restart wireplumber` (this cuts audio briefly).

## bluetooth-audio.conf

Bluetooth headsets are **output-only on purpose**: stereo A2DP, no mic.

```
bluez5.roles = [ a2dp_sink, a2dp_source ]
bluez5.hfphsp-backend = "none"
```

Dropping the `hfp_*`/`hsp_*` roles and killing the backend means the headset profile is never
negotiated at all — `pactl list cards` shows only `off` / `a2dp-sink` / `a2dp-sink-sbc_xq`,
and no bluez source node ever appears. The backend setting is the one doing the real work;
roles alone are not enough.

**Why:** HFP is mono and audibly much worse than A2DP, and the failure mode is invisible —
a call starts, WirePlumber flips the profile, and music quality collapses with no warning.
Mic duty belongs to the Focusrite 2i2 or the internal array.

`bluetooth.autoswitch-to-headset-profile = false` is belt-and-braces: with the backend gone
there is nothing to switch to, but it documents the intent and survives someone re-adding
the roles.

**This has flipped twice.** It was opened up to full duplex on 2026-08-21 when the earbuds
became the primary call device, then locked back down on 2026-08-24. To re-enable, set
`bluez5.roles = [ a2dp_sink, a2dp_source, hfp_ag, hfp_hf, hsp_ag, hsp_hs ]`,
`bluez5.hfphsp-backend = "native"`, add `bluez5.enable-msbc = true` for wideband (16 kHz)
voice, and flip the autoswitch setting. Read the priorities note below first — the headset
mic outranks the internal array on its own, so with the Focusrite unplugged the earbuds
become the default mic and calls drop to HFP.

`bluez5.enable-hw-volume = true` is unrelated to any of this; it lets headset hardware volume
keys drive system volume over A2DP.

## 50-default-priorities.conf

Sets `priority.session` so the right device wins automatically instead of needing a manual
pick after every reconnect.

| | Order (highest first) |
|---|---|
| Outputs | bluetooth 2000 → Focusrite 1500 → HDMI 1200 → internal 1000 |
| Inputs | Focusrite 2500 → internal 2000 → StreamCam 500 |

The StreamCam mic is deliberately last so the webcam never silently becomes the default mic.

**Bluetooth sinks are matched by pattern, not MAC.** Per-device rules were a trap: every new
pair of earbuds silently landed at the default 1010 and lost to HDMI at 1500 until someone
noticed. Note the syntax — a leading `~` makes the value a regular expression. A plain glob
like `bluez_output.*` matches nothing here and fails silently.

**There are no bluetooth sources to rank** — HFP is disabled in `bluetooth-audio.conf`. If it
is ever re-enabled, note that a rule for bluez sources is *dead config*: the headset mic is a
loopback node created with `LocalModule` (`scripts/monitors/bluez.lua:130`) and never passes
through `monitor.bluez.rules`. Its priority is hardcoded to 2010 (same file, `:283`), above
the internal array at 2000 — which is why enabling HFP alone is enough to make the earbuds
the default mic.

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
pactl list short sources | grep bluez             # should print nothing
pactl list cards | grep -A5 'bluez'               # profiles: off / a2dp-sink only, no headset-head-unit
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

### A bluetooth device connects but no sink appears at all

Distinct from the problem below: there is no node to rank, so nothing in this package can
help. `bluetoothctl info <MAC>` says `Connected: yes`, but `pactl list sinks short` shows no
`bluez_output.*` line and the sound settings list no such device. Disconnecting and
reconnecting from the computer fixes it every time, which is the tell.

Check the trust flag:

```bash
bluetoothctl info <MAC> | grep -E 'Paired|Trusted'
```

`Paired: yes` with `Trusted: no` is the failure. When the device initiates the connection
itself — earbuds coming out of the case — BlueZ treats the incoming A2DP service request as
needing authorization and asks the registered agent. The COSMIC bluetooth applet does not
answer service-authorization requests, so bluetoothd refuses:

```
bluetoothd: profiles/audio/a2dp.c:auth_cb() Access denied: Request was rejected.
```

The ACL link still comes up, hence `Connected: yes`, but the AVDTP transport is never
established and WirePlumber has no transport to build a node on. A connect initiated from
this end is implicitly authorized and skips the agent entirely — that is why the manual
reconnect works, and why it is not a fix.

```bash
bluetoothctl trust <MAC>
```

Safe to run mid-call: it writes a flag under `/var/lib/bluetooth` and does not touch an
active stream.

**Pairing does not set this**, so every newly paired audio device needs it — trust the device
as part of pairing it. The Nothing Ear (open) hit this on 2026-08-25 (paired but untrusted;
`auth_cb` rejections at 13:45, 13:47 and 15:59, each followed by a manual reconnect). The MX
Master 3 was trusted earlier and never showed the symptom; the two keyboards are still
untrusted but HID takes a different authorization path.

Confirm with `journalctl -b -u bluetooth | grep -E 'auth_cb|fd\(' ` — a healthy connect logs
`sepN/fdN: fd(NN) ready` with no preceding `Access denied`.

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

Both were cleared on 2026-08-21, but a sink pin for the earbuds has since reappeared (any
manual pick in the sound settings writes one) — as of 2026-08-24 the file holds
`default.configured.audio.sink=bluez_output.3C_B0_ED_52_9E_78.1`, so the earbuds win as
output regardless of priority. No source pin, so mic selection is purely priority-driven.
Re-pin only if you want a device to win *regardless* of priority.
