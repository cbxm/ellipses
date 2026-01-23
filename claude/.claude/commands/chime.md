---
description: Toggle sound notifications globally
allowed-tools: Read, Write
argument-hint: [on|off]
---

# Chime Toggle

Toggle sound notifications on/off globally.

## Check Argument

If argument provided: "$ARGUMENTS"
- `on` → Enable chime
- `off` → Disable chime
- anything else → Show current state

If no argument: Show current state

## Implementation

**Config file:** `~/.claude/chime-config.json`

### Show State (no arg or invalid arg)

Read `~/.claude/chime-config.json` if exists.
Output: `Sound notifications: [ON|OFF]`
If no file: `Sound notifications: OFF (run /chime on to enable)`

### Enable (`on`)

Write to `~/.claude/chime-config.json`:
```json
{"enabled": true}
```
Output: "Sound notifications: ON"

### Disable (`off`)

Write to `~/.claude/chime-config.json`:
```json
{"enabled": false}
```
Output: "Sound notifications: OFF"
