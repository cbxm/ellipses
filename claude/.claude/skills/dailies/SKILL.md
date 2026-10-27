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

Skip (and say why) if an end-of-day report for today already exists: any `M/D:` report message in #dailies after 15:00 Denver, whoever posted it (Caden, this routine, or a manual run). Morning "plan for today" posts don't count.

## Gather

Let `D` = today in Denver (`TZ=America/Denver date +%F`) and `SINCE` = local midnight as ISO-8601 with offset.

1. **GitLab, the main source.** Everything Caden's agents ship is authored as `cbxm`.
   - `glab api "groups/x2u/merge_requests?author_username=cbxm&updated_after=$SINCE&state=all&per_page=100"`: `merged_at` ≥ `SINCE` = shipped today (an MR merged earlier but updated today is not new); opened/updated and still open = MR up / in progress; note drafts.
   - `glab api "users/cbxm/events?after=<D minus 1 day>&per_page=100"`: pushes to branches with no MR = in progress. Ignore pushes that only belong to MRs already listed.
   - For merged MRs, check the main pipeline's deploy job (`glab api "projects/x2u%2F<repo>/pipelines?ref=main&updated_after=$SINCE"`) to say "live" vs "merged, deploying" vs "deploy failed".
2. **#weeklies** (`C0BSRJLAPGR`): items struck with today's date (`(MM/DD)`) are done. Use them to name the work in Caden's own words.
3. **#support** (`C0CCN2S04RY`): if today's support report exists, one bullet summarising it (tickets handled, anything needing a human).

Read MR titles and descriptions to understand what changed for customers; read the diff only if the description is useless.

## Write

Match the house style exactly. Recent example:

```
10/24:
• fixed slow `salon` booking tool connects. ~20ms now, was up to 28s. live.
• canary fixes, live: AI can tell which texts staff sent, offered times show end time, slow Meevo logins no longer lock out a location.
• monitored prod all day. healthy. one convo (4ae7a1bb) never got a reply; needs a human.
```

- First line `M/D:` (no leading zeros, matching past posts). Then 3–7 `•` bullets. Nested `◦` only for a list of related fixes.
- Lowercase, terse, outcome first, then status: `live`, `MR up`, `in progress`, `needs a human`, `waiting on <who>`.
- Customer/business words, not code words. App names in backticks (`salon`, `ai7`) are fine; file names, function names, MR numbers are not.
- Group related MRs into one bullet. Lead with what matters most to the owners.
- Never invent work or health claims. Only what the sources show. Don't claim "monitored prod" unless there's evidence. If there's no activity at all, post nothing in scheduled mode and say so in the session output.

## Post

`slack_send_message` to `C0BN8FRCZ9Q`, top-level (not a thread). Return the message link.
