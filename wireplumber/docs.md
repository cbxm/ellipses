# wireplumber

WirePlumber session-manager overrides for PipeWire. Drop-ins in `wireplumber.conf.d/`
layer on top of `/usr/share/wireplumber/wireplumber.conf` — never edit that file directly,
it is package-owned and overwritten on upgrade.

## disable-hfp.conf

Bluetooth headsets are **output-only on purpose**.

```
bluez5.roles = [ a2dp_sink, a2dp_source ]
bluez5.hfphsp-backend = "none"
```

Restricting the roles and killing the HFP/HSP backend means the headset profile is never
offered at all — `pactl list cards` shows only `off` / `a2dp-sink` / `a2dp-sink-sbc_xq`, and
no bluez source ever appears.

**Why:** the headset (HFP/HSP) profile is mono and heavily compressed. The moment any app
opens a mic, WirePlumber would otherwise drag the headset out of A2DP into that profile and
music quality collapses. Mic duty belongs to the Focusrite 2i2 or the internal array; the
earbuds are speakers and nothing else.

`bluetooth.autoswitch-to-headset-profile = false` is belt-and-braces — with the backend
already `none` there is nothing to switch to, but the setting documents the intent.

Note `a2dp_source` is still listed: that role lets *this machine* receive audio from a phone.
It is unrelated to the mic question and harmless to keep.

## 50-default-priorities.conf

Sets `priority.session` so the right device wins automatically instead of needing a manual
pick after every reconnect.

Outputs, highest first: HDMI (1500) → internal analog (1000) → Focusrite (100).
Inputs, highest first: Focusrite (2500) → internal analog (2000) → StreamCam (500).
The StreamCam mic is deliberately last; it exists only so the camera does not silently
become the default mic when plugged in.

Bluetooth sinks are pinned at 2000 so connected earbuds outrank the built-in speakers.

**Gotcha worth knowing:** priority only decides between *candidates*. A user-pinned default
stored as `default.configured.audio.sink` in `~/.local/state/wireplumber/default-nodes`
overrides priority entirely. If a device that is connected still refuses to become the
output, that state file — not this config — is the thing to inspect. Repoint it with
`wpctl set-default <id>`, never by hand-editing; WirePlumber holds the state in memory and
rewrites the file on exit.

## Applying changes

```bash
systemctl --user restart wireplumber
```

Verify: `pactl list short sinks`, `pactl get-default-sink`, and for the HFP lockout
`pactl list short sources | grep bluez` should return nothing.
