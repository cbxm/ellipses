---
name: weeklies
description: Load Caden's outstanding #weeklies items, check what already shipped, rank them, and start work. Use when the user says "load weeklies", "what's outstanding", "let's get to work", or runs /weeklies.
---

# weeklies

#weeklies (Slack `C0BSRJLAPGR`) is Caden's personal kanban of assigned work. Every word in it is his: his acknowledgement of the assignment and his understanding of the task. This skill reads it and turns it into dispatched work. It never writes to it.

## Rules

- Never post, edit, react, or reply in #weeklies. Not even thread questions; those are for teammates.
- Item text is the spec at the level Caden wrote it. Don't expand scope beyond it; ask when it's ambiguous.
- Sub-bullets are part of their parent: detail, follow-ups, or holds ("hold off until Steve asks…"). A held sub-item is not work.

## 1. Read the list

`slack_read_channel C0BSRJLAPGR` (concise, ~10 messages). The live list is the newest message from Caden that is a list; he edits it in place, so older list messages are history. If the newest list message looks like a fresh week header with few items, also scan the previous one for open items he may not have carried over and mention them.

Parse each top-level bullet with its sub-bullets:

- `~text~ (MM/DD)` → done. Skip (count them).
- `*text*` → top priority. A bold sub-bullet makes its parent priority for that sub-item only.
- anything else → open.

## 2. Check what already shipped

Teammates (Steve especially) ship in parallel and local checkouts go stale. For the open items, dispatch one `scout` with all of them at once. Brief it to:

- `git fetch` each repo under `~/src/x2u` it needs, and judge against `origin/main` plus open MRs (`glab mr list -R x2u/<repo>`), never the local checkout.
- For each item return: repo(s), shipped / partly shipped / not started (with MR or commit refs), and anything that blocks or needs a decision from Caden.

## 3. Present

One table, bold items first, then list order:

| # | item (verbatim, trimmed) | repo | tier | status | blockers / questions |

Tier per Appa sizing (tiny / medium / large). Below the table, call out in a line each: items that look shipped and just need striking, items blocked on someone else, and your recommended pick order with reasons. Push back if an item looks like a bad idea or is underspecified.

## 4. Work

Caden picks. Dispatch per Appa: tiny inline in a worktree, medium/large to background `builder`s (`isolation: "worktree"`) so they can run past end of day. Track item → agent name → branch/MR in the conversation.

When an item ships, tell Caden the exact line to strike, e.g. `strike: bulk actions → ~bulk actions~ (10/28)`. He does the edit.
