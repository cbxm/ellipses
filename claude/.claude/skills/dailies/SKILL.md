---
name: dailies
description: Write and post Caden's end-of-day #dailies report from the day's GitLab activity and #weeklies. Runs as a 4pm weekday routine; also on demand via /dailies. Pass --dry-run to print without posting.
---

# dailies

Caden's end-of-day status, posted to #dailies (Slack `C0BN8FRCZ9Q`) for the owners. Readers are non-technical. It replaces the 4pm standup, so it goes out on its own; work still in flight is normal and gets reported as in flight, not wrapped up.

## Modes

- **Scheduled** (prompt says "scheduled"): the routine fires twice an hour apart to cover DST. Run only if `TZ=America/Denver date +%H` prints `16` or `17` (if `date` shows UTC, tzdata is missing: post nothing, say so in #support). The already-posted check below is what prevents a double post. Then post without asking.
- **Manual**: draft, show it, post on approval.
- `--dry-run` in either mode: print the draft, never post.

Skip (and say why) if an end-of-day report for today already exists: any top-level `M/D:` report message in #dailies after 15:00 Denver, whoever posted it (Caden, this routine, or a manual run). Morning "plan for today" posts don't count.

## Gather

Let `D` = today in Denver (`TZ=America/Denver date +%F`) and `SINCE` = local midnight as ISO-8601 with offset.

1. **GitLab, the main source.** Everything Caden's agents ship is authored as `cbxm`.
   - `glab api "groups/x2u/merge_requests?author_username=cbxm&updated_after=$SINCE&state=all&per_page=100"`: `merged_at` ≥ `SINCE` = shipped today (an MR merged earlier but updated today is not new); opened/updated and still open = MR up / in progress; note drafts.
   - `glab api "users/cbxm/events?after=<D minus 1 day>&per_page=100"`: pushes to branches with no MR = in progress. Ignore pushes that only belong to MRs already listed.
   - For merged MRs, check the main pipeline's deploy job (`glab api "projects/x2u%2F<repo>/pipelines?ref=main&updated_after=$SINCE"`) to say "live" vs "merged, deploying" vs "deploy failed".
2. **#weeklies** (`C0BSRJLAPGR`): items struck with today's date (`(MM/DD)`) are done. Use them to name the work in Caden's own words.
3. **#support** (`C0CCN2S04RY`): if today's support report exists, one bullet summarising it (tickets handled, anything needing a human).

Read MR titles and descriptions to understand what changed, both for customers and technically; read the diff only if the description is useless.

## Write

Two messages: a top-level post for the CEO, and a thread reply under it for the CTO.

### Top-level: non-technical

The CEO reads only this. Write it for someone who knows the customers and the product from the outside, not the code.

```
10/24:
• booking replies are fast again. the AI was sometimes waiting up to 28 seconds to reach the booking system; now it's instant. live.
• a few fixes to how the AI texts: it can tell which messages staff sent, offered times now include an end time, and one slow login no longer locks out a whole location. live.
• one customer conversation never got a reply; someone should follow up.
```

- First line `M/D:` (no leading zeros). Then 3–7 `•` bullets. Lowercase and terse.
- Each bullet is what changed for customers or the business, then where it stands: `live`, `ready, waiting on review`, `in progress`, `needs a human`, `waiting on <who>`.
- No jargon at all: no app or repo names (`salon`, `ai7`), MR numbers, migrations, pipelines, deploys, models, or databases. Name customers (schools, salons) and features as the customer sees them. If an item can't be said without jargon, say what it means for customers, or leave it to the thread.
- Group related work into one bullet. Lead with what matters most to the owners.
- Never invent work or health claims; only what the sources show. Don't claim "monitored prod" without evidence. If there's no activity at all, post nothing in scheduled mode and say so in the session output.

### Thread reply: technical

The CTO reads this. Same items, same order, one bullet each, plus anything technical that didn't earn a top-level bullet. (Example below is illustrative; the MR numbers are made up.)

```
• salon!151: MCP connect latency, DO per session → stateless handler. merged, main pipeline green (deployed 14:02).
• ai7!248/!249: staff-sent flag on outbound messages; slot end time in offers; Meevo login breaker per location. merged + deployed. migration 0091.
• open: ai7!252 (draft), branch feat/bulk-tags pushed, no MR yet.
```

- `repo!iid` for every MR, as a link to it. Status from the sources: open / draft / merged / deployed / deploy failed (with the pipeline link).
- One line of what changed technically and why (root cause, not just symptom). Call out migrations, flags, config, anything that needs care to ship, and anything blocked on review.
- Support items: ticket link plus MR link.

## Post

1. `slack_send_message` to `C0BN8FRCZ9Q`, top-level, with the non-technical message.
2. `slack_send_message` to `C0BN8FRCZ9Q` with `thread_ts` set to the first message's ts, with the technical reply.

If step 2 fails, retry once, then say so in the session output; don't repost the top level. Return both message links.
