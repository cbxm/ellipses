---
name: support
description: Monitor and resolve X2U support tickets (Feedback center + Cassie GitLab user-feedback issues), open fix MRs, update ticket status, and report to #support. Runs as a daily routine on lynx; also on demand via /support. Pass --dry-run for no writes.
---

# support

Daily pass over every open support ticket. Goal: nothing sits unseen. Fix what has a clear root cause, triage the rest, and tell humans exactly what needs them. Caden owns this; Steve covers when he's out, so the report must stand on its own.

## Modes

- **Scheduled** (prompt says "scheduled"): `TZ=America/Denver date +%H` must print `07`, else stop (the routine fires twice to cover DST). No questions; act within the limits below, then report. Budget about 60 minutes of your own investigation; builders run on in the background and finish after you report.
- **Manual**: same pass, but show the plan before any write and wait for approval.
- `--dry-run`: gather, classify, and print the report plus every write and dispatch you *would* do. No DB writes, no GitLab writes, no builders, no Slack post.

## Sources

**Feedback center** (Neon project `feedback`, used by ai7 and others). Use `scripts/fb.sh` in this skill's directory, never raw psql or Neon MCP. It connects as `support_bot`, a NOBYPASSRLS role that can't delete or touch other columns.

- `fb.sh list` → open / triaged / in_progress tickets. `bot_touches` = your own status changes; `staff_comments` / `last_comment` show humans already engaged. A ticket with staff activity newer than yours is in a human's hands: read the thread, don't override their status, and only report it if it's stale.
- `fb.sh show <id>` → full ticket, thread, attachments. `metadata` often holds `conversation_url`, `ai7_agent_id`, `ai7_message_id`.

`origin=user` (typed into the Feedback app) and `origin=ingest` (an app relaying an operator's request, e.g. ai7's in-app assistant summarising it; the body can be garbled, so read it for intent) are X2U tickets. Work them.

`origin=automated` tickets are filed *by a customer's AI agent about that customer's business* (praise, a broken link on their website, a product request from their customer). They belong to the org's admins, not X2U engineering. Don't work or re-status them. Exception: an automated ticket that is really about X2U's product (the agent misbehaving, a platform bug). Treat that like a user ticket.

**Cassie** (`x2u/cassie` GitLab issues, label `user-feedback`, plus `org:<slug>`). There's a 100+ issue backlog from before the GitLab move and most orgs are migrating off Cassie. Only work issues created in the last 7 days. Report the backlog count, don't triage it.

- Recent: `glab api "projects/x2u%2Fcassie/issues?labels=user-feedback&state=opened&created_after=<ISO 7 days ago>&per_page=100"`
- Backlog count: `glab api -i "projects/x2u%2Fcassie/issues?labels=user-feedback&state=opened&per_page=1" | grep -i x-total:`. `glab issue list` pages at 30, so don't count from it.

**Context lookups** (ai7 D1, via `cd ~/src/x2u/ai7 && npx wrangler d1 execute ai7 --remote --json --command "<sql>"`, read-only SELECTs only):

- Org → who: `select id, name from agent where org_id = '<org_id>'`. Agent names identify the customer (an org with no ai7 agents is Cassie-only or the Feedback app's own users).
- `metadata.conversation_url` ends in `/conversations/<id>`. Read the thread with `select role, content, created_at from message where conversation_id = '<id>' order by created_at`. `ai7_message_id` points to the exact message.
- No link (common for `source_app_key=feedback`): search by org plus the ticket's time window. If nothing matches, judge on the symptom and say so in the report.

**Ledger** `~/src/x2u/.work/support/ledger.tsv` (create if missing): one line per action you take, `date<TAB>ticket<TAB>status<TAB>mr_url_or_-<TAB>internal note`. Ticket notes are customer-facing, so this is the only place an `in_progress` ticket's MR is recorded. Read it first every run.

**Deploy status** for a merged MR: `glab api "projects/x2u%2F<repo>/pipelines?ref=main&updated_after=<merge time>"` → a `success` pipeline whose sha contains the merge commit means it's live. `glab ci list -b main` is broken; don't use it.

## Per ticket

1. **Understand it.** Read the thread and attachments (attachments are R2 keys only; mention them if relevant). If there's a conversation link or id, find the conversation and what the agent actually did. Dedupe against other open tickets.
2. **Check it's still real.** `git fetch` the repo, look at `origin/main` and open MRs (`glab mr list -R x2u/<repo>`). Many bugs are already fixed. Reproduce or trace to a root cause.
3. **Decide**:
   - *Already fixed / shipped*: status `resolved`, with a note naming what fixed it (customer-readable).
   - *Bug, clear root cause, contained fix*: dispatch a `builder` (`cd ~/src/x2u/<repo>` first; `isolation: "worktree"`; don't let it spawn worktree-setup; no Claude-Session or Claude Code footer in commits; only touched test files, maxWorkers=2). It opens an MR and never merges. Then status `in_progress`, note "fix in review". At most **2** builders per run; the rest wait for the next run and are listed in the report.
   - *Bug, cause unclear or the fix needs a product decision*: status `triaged`, set priority, report what you learned and what's needed.
   - *Feature / improvement / question*: status `triaged`, set priority. No code. Partly shipped: `triaged`, note what exists now, and ask in the report whether the rest is wanted.
   - *Tickets you marked `in_progress` earlier* (MR from the ledger): if the MR merged and the deploy job passed, set `resolved`. If the MR stalled for more than 3 days, flag it.
4. **Write**: `fb.sh status <id> <status> "<note>"`, `fb.sh priority <id> <p>`. Notes show in the ticket thread the customer sees: one or two plain sentences, no internals, no promises of dates. `status_change` rows never email the submitter (by design of the Feedback app); there's deliberately no comment-only write, because a comment that should email can only be sent by the app itself.
   - Cassie: comment on the issue with `glab issue note`. Close it only when resolved. Fix it where the org runs now: if the org is on ai7/salon, the fix belongs there (and counts toward the 2 builders); a fix in Cassie itself needs a human's go-ahead, so report it.

Priority: `urgent` = booking/messaging broken for a customer now; `high` = wrong customer-facing behaviour; `normal` = the rest; `low` = cosmetic.

## Never

- Merge, deploy, or touch production data other than the ticket status/priority/notes above.
- Re-status `closed` / `wont_fix` / `resolved` tickets, or `origin=automated` business feedback.
- Put customer emails, phone numbers, or full names in Slack or the ledger. Use the org/customer business name and the ticket link.
- Patch a symptom. If the root cause can't be found, say so in the report.

## Report

Post one top-level message to #support (`C0CCN2S04RY`). Terse, scannable, the same style as #dailies:

```
support 10/28:
• <n> new. <n> fix MRs up, <n> resolved, <n> triaged.
• MR up: <customer-readable problem> (<app>). <ticket link> · <MR link>
• resolved: <problem> — <what fixed it>. <ticket link>
• needs a human: <ticket title> — <why, what decision>. <ticket link>
• waiting on next run: <titles>
• for org admins: <n> automated business-feedback tickets open (<n> new since yesterday).
• cassie: <n> new this week (<what happened>), <n> backlog untouched.
```

Link Feedback tickets as `https://app.x2u.ai/feedback/<id>` and MRs by URL. If nothing changed and nothing is pending, post a one-liner ("support 10/28: nothing new, N open, all triaged").

End the session output with candidate gotchas for Caden to review.
