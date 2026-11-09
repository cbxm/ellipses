# hypercare queries

Read-only queries against ai7's D1. Each one is the **header**, filled in for the customer, followed directly by one query block, passed as the single argument to `~/.claude/skills/support/scripts/d1-select.sh`. Copy only the text inside the fences: the SQL holds no comments, and nothing outside it goes to the script (a leading `--` line makes the cf CLI read the SQL as a flag and fail). The script refuses the words insert, update, delete, drop, alter, create, replace, pragma and attach anywhere in the text, so no `replace()` either.

Every ai7 timestamp is epoch milliseconds.

## header

One `tz` row per agent with the school's UTC offset in seconds on the reviewed day (`TZ=<tz> date -d '<D> 12:00' +%z`; `-0800` is `-28800`), then the reviewed day `D` and the go-live date. `grid` has one row per (agent, school-local day) from go-live to `D`, with `t0`/`t1` the day's bounds. `weekday` holds every Monday to Friday at the school from 30 days before go-live to `D`; the `_wh` columns count age only inside it, so a weekend adds nothing.

```sql
with recursive
tz(agent_id, off) as (values ('<agent id>', <offset seconds>), ('<agent id>', <offset seconds>)),
p(d, golive) as (select '<D>', '<go-live>'),
days(day) as (select golive from p union all select date(day, '+1 day') from days, p where day < p.d),
grid as (select tz.agent_id, tz.off, days.day, (strftime('%s', days.day) - tz.off) * 1000 t0,
  (strftime('%s', days.day, '+1 day') - tz.off) * 1000 t1 from tz, days),
wdays(day) as (select date(golive, '-30 days') from p union all select date(day, '+1 day') from wdays, p where day < p.d),
weekday as (select tz.agent_id, (strftime('%s', w.day) - tz.off) * 1000 t0,
  (strftime('%s', w.day, '+1 day') - tz.off) * 1000 t1 from tz, wdays w where strftime('%w', w.day) not in ('0', '6'))
```

## agent

Current row plus every disabled or timezone change, with who made it. With `--as-of`, replay the changes after `D` to get the state on `D`.

```sql
select a.id agent_id, a.name, a.disabled disabled_now, a.timezone timezone_now, a.deleted_at,
  e.created_at, e.actor_email, json_extract(e.changes, '$.disabled') disabled_change,
  json_extract(e.changes, '$.timezone') timezone_change
from tz join agent a on a.id = tz.agent_id
left join audit_event e on e.agent_id = a.id and e.action like 'agent.%'
  and (json_extract(e.changes, '$.disabled') is not null or json_extract(e.changes, '$.timezone') is not null)
order by a.id, e.created_at
```

## activity

Per agent per day: conversations a guest texted in, guest texts, AI texts, staff texts. Imported (Cassie) history excluded.

```sql
, m as (select c.agent_id, m.conversation_id, m.role, m.source, m.created_at
    from tz join conversation c on c.agent_id = tz.agent_id join message m on m.conversation_id = c.id, p
   where m.imported_from is null and m.created_at >= (strftime('%s', p.golive) - 86400) * 1000)
select g.agent_id, g.day,
  count(distinct case when m.role = 'user' then m.conversation_id end) guest_convs,
  coalesce(sum(m.role = 'user'), 0) guest_texts,
  coalesce(sum(m.role = 'assistant' and m.source = 'ai'), 0) ai_texts,
  coalesce(sum(m.role = 'assistant' and m.source = 'operator'), 0) staff_texts
from grid g left join m on m.agent_id = g.agent_id and m.created_at >= g.t0 and m.created_at < g.t1
group by 1, 2 order by 1, 2
```

## questions

Per agent per day: AI Questions asked, open at the day's end, the oldest open one's age (wall clock and weekday hours), and Teach threads staff started. A question closes at its first non-empty operator comment, resolve, or never-mind, the SQL mirror of `isOpenQuestion` in ai7's `discussions.server.ts`.

```sql
, q as materialized (select c.agent_id, d.conversation_id, d.created_at,
    min(coalesce(json_extract(d.state, '$.resolved.at'), 9e15),
        coalesce(json_extract(d.state, '$.neverMind.at'), 9e15),
        coalesce((select min(dc.created_at) from discussion_comment dc
                   where dc.discussion_id = d.id and dc.author = 'operator' and trim(dc.body) <> ''), 9e15)) closed_at
    from tz join conversation c on c.agent_id = tz.agent_id join discussion d on d.conversation_id = c.id
   where d.type = 'question'),
o as materialized (select g.agent_id, g.t0, g.t1, g.day,
    (select min(q.created_at) from q where q.agent_id = g.agent_id and q.created_at < g.t1 and q.closed_at >= g.t1) oldest
    from grid g)
select o.agent_id, o.day,
  (select count(*) from q where q.agent_id = o.agent_id and q.created_at >= o.t0 and q.created_at < o.t1) asked,
  (select count(*) from q where q.agent_id = o.agent_id and q.created_at < o.t1 and q.closed_at >= o.t1) open_at_end,
  round((o.t1 - o.oldest) / 3600000.0, 1) oldest_open_h,
  case when o.oldest is not null then round((select coalesce(sum(max(0, min(o.t1, w.t1) - max(o.oldest, w.t0))), 0)
    from weekday w where w.agent_id = o.agent_id and w.t0 < o.t1 and w.t1 > o.oldest) / 3600000.0, 1) end oldest_open_wh,
  (select count(*) from discussion d join conversation c on c.id = d.conversation_id
    where c.agent_id = o.agent_id and d.type = 'teach' and d.created_by_email is not null
      and d.created_at >= o.t0 and d.created_at < o.t1) teach_threads
from o order by 1, 2
```

## question_titles

`D`'s questions and every one open at `D`'s end, judged as of `D` exactly as `questions` counts them. `staff_texted_after` is 1 when staff texted the guest in that conversation after the question was asked: the question may have been handled by text without anyone closing it. Titles are AI-written and can hold guest names: read them, never post them.

```sql
, d as (select g.* from grid g, p where g.day = p.d),
qq as (select d.agent_id, d.t0, d.t1, q.conversation_id, q.created_at, q.title,
    min(coalesce(json_extract(q.state, '$.resolved.at'), 9e15),
        coalesce(json_extract(q.state, '$.neverMind.at'), 9e15),
        coalesce((select min(dc.created_at) from discussion_comment dc
                   where dc.discussion_id = q.id and dc.author = 'operator' and trim(dc.body) <> ''), 9e15)) closed_at
    from d join conversation c on c.agent_id = d.agent_id join discussion q on q.conversation_id = c.id
   where q.type = 'question' and q.created_at < d.t1)
select agent_id, conversation_id, created_at >= t0 asked_on_d, closed_at >= t1 open_at_end,
  exists (select 1 from message m where m.conversation_id = qq.conversation_id and m.source = 'operator'
    and m.created_at > qq.created_at and m.created_at < qq.t1) staff_texted_after,
  substr(title, 1, 120) title
from qq where created_at >= t0 or closed_at >= t1
order by agent_id, created_at limit 60
```

## approvals

Per agent per day: approval cards created, answered, approve clicks Salon refused, rejects, cards cancelled, pending at the day's end, and the oldest pending card's age (wall clock and weekday hours). Cancelled cards carry no timestamp, so pending counts for earlier days miss cards cancelled later.

```sql
, r as materialized (select c.agent_id, ur.status, ur.created_at, ur.answered_at, ur.expires_at,
    json_extract(ur.answer, '$.option') opt, json_extract(ur.effect_outcome, '$.ok') ok
    from tz join conversation c on c.agent_id = tz.agent_id join user_request ur on ur.conversation_id = c.id),
o as materialized (select g.agent_id, g.t0, g.t1, g.day,
    (select min(r.created_at) from r where r.agent_id = g.agent_id and r.created_at < g.t1
       and (r.status = 'pending' or r.answered_at >= g.t1 or (r.status = 'expired' and r.expires_at >= g.t1))) oldest
    from grid g)
select o.agent_id, o.day,
  (select count(*) from r where r.agent_id = o.agent_id and r.created_at >= o.t0 and r.created_at < o.t1) cards,
  (select count(*) from r where r.agent_id = o.agent_id and r.answered_at >= o.t0 and r.answered_at < o.t1) answered,
  (select count(*) from r where r.agent_id = o.agent_id and r.answered_at >= o.t0 and r.answered_at < o.t1
     and r.opt <> 'reject' and r.ok = 0) refused_by_salon,
  (select count(*) from r where r.agent_id = o.agent_id and r.answered_at >= o.t0 and r.answered_at < o.t1
     and r.opt = 'reject') rejected,
  (select count(*) from r where r.agent_id = o.agent_id and r.created_at >= o.t0 and r.created_at < o.t1
     and r.status = 'cancelled') cancelled,
  (select count(*) from r where r.agent_id = o.agent_id and r.created_at < o.t1
     and (r.status = 'pending' or r.answered_at >= o.t1 or (r.status = 'expired' and r.expires_at >= o.t1))) pending_at_end,
  round((o.t1 - o.oldest) / 3600000.0, 1) oldest_pending_h,
  case when o.oldest is not null then round((select coalesce(sum(max(0, min(o.t1, w.t1) - max(o.oldest, w.t0))), 0)
    from weekday w where w.agent_id = o.agent_id and w.t0 < o.t1 and w.t1 > o.oldest) / 3600000.0, 1) end oldest_pending_wh
from o order by 1, 2
```

## approval_detail

`D` only: who answered how many, why Salon refused, and the AI's reason for each cancelled card (free text; a guest dropping an add-on reads like "guest dropped the deep condition").

```sql
, d as (select g.* from grid g, p where g.day = p.d),
r as (select c.agent_id, ur.conversation_id, ur.status, ur.created_at, ur.answered_at, ur.answered_by_email,
    ur.cancelled_reason, json_extract(ur.answer, '$.option') opt, json_extract(ur.effect_outcome, '$.ok') ok,
    json_extract(ur.effect_outcome, '$.error') err, d.t0, d.t1
    from d join conversation c on c.agent_id = d.agent_id join user_request ur on ur.conversation_id = c.id)
select agent_id, 'answered_by' what, answered_by_email detail, count(*) n, null conversation_ids
  from r where answered_at >= t0 and answered_at < t1 group by 1, 3
union all
select agent_id, 'refused', substr(err, 1, instr(err || ' —', ' —') - 1), count(*), group_concat(distinct conversation_id)
  from r where answered_at >= t0 and answered_at < t1 and opt <> 'reject' and ok = 0 group by 1, 3
union all
select agent_id, 'cancelled', cancelled_reason, 1, conversation_id
  from r where created_at >= t0 and created_at < t1 and status = 'cancelled'
order by 1, 2
```

## nudges

Per agent per day: follow-ups the AI sent on its own, and those sent between 21:00 and 07:00 at the school. The offset in `tz` is the school's real one, so a wrong or missing `agent.timezone` shows up here.

```sql
, n as (select c.agent_id, m.conversation_id, m.created_at,
    cast(strftime('%H', m.created_at / 1000 + tz.off, 'unixepoch') as integer) local_hour
    from tz join conversation c on c.agent_id = tz.agent_id join message m on m.conversation_id = c.id
    join turn_prompt tp on tp.message_id = m.id and tp.path = 'nudge', p
   where m.role = 'assistant' and m.created_at >= (strftime('%s', p.golive) - 86400) * 1000)
select g.agent_id, g.day, count(n.created_at) nudges,
  coalesce(sum(n.local_hour >= 21 or n.local_hour < 7), 0) night_nudges,
  group_concat(case when n.local_hour >= 21 or n.local_hour < 7 then n.local_hour end) night_hours,
  group_concat(distinct case when n.local_hour >= 21 or n.local_hour < 7 then n.conversation_id end) night_convs
from grid g left join n on n.agent_id = g.agent_id and n.created_at >= g.t0 and n.created_at < g.t1
group by 1, 2 order by 1, 2
```

## waiting

At the end of `D` and of the day before: conversations whose last text is the guest's and is over 30 minutes old, and the longest wait (wall clock and weekday hours). `paused_now` is today's flag. Includes guests who closed with "thanks" and staff texting the agent's own number, so read before calling one unanswered.

```sql
, ends as (select g.agent_id, g.day, g.t1 from grid g, p where g.day >= date(p.d, '-1 day')),
w as (select e.agent_id, e.day, e.t1, c.id conversation_id, c.paused,
    (select m.role || '|' || m.created_at from message m
      where m.conversation_id = c.id and m.created_at < e.t1 and m.imported_from is null
      order by m.created_at desc limit 1) last_msg
    from ends e join conversation c on c.agent_id = e.agent_id
   where c.last_activity_at >= e.t1 - 14 * 86400000),
x as (select agent_id, day, t1, conversation_id, paused,
    cast(substr(last_msg, instr(last_msg, '|') + 1) as integer) since
    from w where last_msg like 'user|%'),
y as (select agent_id, day, t1, count(*) waiting, sum(paused) paused_now, min(since) oldest,
    group_concat(conversation_id) convs
    from x where since < t1 - 1800000 group by 1, 2, 3)
select agent_id, day, waiting, paused_now, round((t1 - oldest) / 3600000.0, 1) longest_wait_h,
  round((select coalesce(sum(max(0, min(y.t1, k.t1) - max(y.oldest, k.t0))), 0) from weekday k
    where k.agent_id = y.agent_id and k.t0 < y.t1 and k.t1 > y.oldest) / 3600000.0, 1) longest_wait_wh,
  convs
from y order by 1, 2
```

## empty_lookups

`D` and the day before: availability lookups, and the empty ones grouped by the Salon rule that emptied them. A rule or service that keeps coming back is a service guests can't book.

```sql
, d as (select g.* from grid g, p where g.day >= date(p.d, '-1 day')),
t as (select d.agent_id, d.day, m.conversation_id, json_extract(tp.value, '$.output') o
    from d join conversation c on c.agent_id = d.agent_id
    join message m on m.conversation_id = c.id and m.created_at >= d.t0 and m.created_at < d.t1, json_each(m.parts) tp
   where m.role = 'assistant' and m.parts is not null and m.imported_from is null
     and json_extract(tp.value, '$.name') = 'salon_lookup_availability')
select agent_id, day, '(all lookups)' rule, null reason, count(*) n, count(distinct conversation_id) convs, null conv_ids
from t group by 1, 2
union all
select agent_id, day, coalesce(json_extract(o, '$.reason.ruleId'), '?'),
  coalesce(json_extract(o, '$.reason.ruleReason'), json_extract(o, '$.summary')),
  count(*), count(distinct conversation_id), group_concat(distinct conversation_id)
from t where json_valid(o) and json_array_length(json_extract(o, '$.slots')) = 0
group by 1, 2, 3, 4 order by 1, 2, 5 desc
```

## candidates

`D`'s conversations with a guest text, flagged ones first. The keyword flags are hints for picking what to read, not findings.

```sql
, d as (select g.* from grid g, p where g.day = p.d),
dm as (select d.agent_id, m.conversation_id, m.role, m.source, lower(m.body) b
    from d join conversation c on c.agent_id = d.agent_id and c.last_activity_at >= d.t0
    join message m on m.conversation_id = c.id and m.created_at >= d.t0 and m.created_at < d.t1
   where m.imported_from is null),
f as (select agent_id, conversation_id,
    sum(role = 'user') guest_texts,
    sum(source is 'operator') staff_texts,
    sum(role = 'user' and (b like '%manager%' or b like '%supervisor%' or b like '%real person%' or b like '%human%'
      or b like '%speak to someone%' or b like '%talk to someone%' or b like '%call me%' or b like '%front desk%'
      or b like '%agent contact%')) asks_for_person,
    sum(source is 'ai' and (b like '%correction%' or b like '%my mistake%' or b like '%i was wrong%' or b like '%apologi%'
      or b like '%sorry for the confusion%' or b like '%no longer open%' or b like '%couldn''t take%')) ai_corrected
  from dm group by 1, 2)
select f.*,
  (select count(*) from discussion q, d where q.conversation_id = f.conversation_id and q.type = 'question'
     and d.agent_id = f.agent_id and q.created_at >= d.t0 and q.created_at < d.t1) questions,
  (select count(*) from user_request r, d where r.conversation_id = f.conversation_id and d.agent_id = f.agent_id
     and r.answered_at >= d.t0 and r.answered_at < d.t1 and json_extract(r.effect_outcome, '$.ok') = 0) refused,
  (select count(*) from user_request r, d where r.conversation_id = f.conversation_id and d.agent_id = f.agent_id
     and r.created_at >= d.t0 and r.created_at < d.t1 and r.status = 'cancelled') cancelled,
  (select m.role from message m, d where m.conversation_id = f.conversation_id and d.agent_id = f.agent_id
     and m.created_at < d.t1 and m.imported_from is null order by m.created_at desc limit 1) last_role
from f where guest_texts > 0
order by (questions > 0) + (refused > 0) + (cancelled > 0) + (asks_for_person > 0) + (ai_corrected > 0)
  + (last_role = 'user') desc, guest_texts desc
limit 25
```

## read

The last 30 texts before `D`'s end in each picked conversation, school local time, 300 characters each. At most 12 conversations per customer.

```sql
, d as (select g.* from grid g, p where g.day = p.d),
pick(id) as (values ('<conversation id>'), ('<conversation id>')),
x as (select m.conversation_id, m.role, m.source, m.created_at, m.body, d.off,
    row_number() over (partition by m.conversation_id order by m.created_at desc) rn
    from pick join conversation c on c.id = pick.id join d on d.agent_id = c.agent_id
    join message m on m.conversation_id = c.id and m.created_at < d.t1
   where m.imported_from is null)
select conversation_id, case when role = 'user' then 'guest' when source = 'operator' then 'staff' else 'ai' end who,
  strftime('%m-%d %H:%M', created_at / 1000 + off, 'unixepoch') local_at, substr(body, 1, 300) body
from x where rn <= 30 order by conversation_id, created_at
```
