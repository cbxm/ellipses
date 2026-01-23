---
description: Toggle Discord notifications for this project
allowed-tools: Read, Write, Bash
argument-hint: [on|off|init]
---

# Notify Toggle

Toggle Discord notifications on/off for this project, or initialize config.

## Check Argument

If argument provided: "$ARGUMENTS"
- `on` → Enable notifications
- `off` → Disable notifications
- `init` → Create config file for new repo
- anything else → Show current state

If no argument: Show current state

## Implementation

**State file location:** `.claude/notify-state.json` in project root

### Show State (no arg or invalid arg)

Read `.claude/notify-state.json` if it exists.

Output:
```
Discord notifications: [ON|OFF]
```

If no state file exists: "Discord notifications: OFF (no config - run /notify init)"

### Enable (`on`)

Write to `.claude/notify-state.json`:
```json
{"enabled": true}
```

Output: "Discord notifications: ON"

### Disable (`off`)

Write to `.claude/notify-state.json`:
```json
{"enabled": false}
```

Output: "Discord notifications: OFF"

### Init (`init`)

1. Create `.claude` dir if missing: `mkdir -p .claude`
2. Write to `.claude/notify-state.json`:
```json
{"enabled": true}
```

Output: "Discord notifications initialized: ON"

## Notes

- Default behavior (no state file) = notifications OFF (must init first)
- State is per-project
- Hooks check this file before sending to Discord
