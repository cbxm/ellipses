#!/usr/bin/env bash
# Feedback-center access for the support skill, as the least-privilege `support_bot`
# role (NOBYPASSRLS; SELECT all, INSERT comments, UPDATE status/priority only).
#
#   fb.sh list                       open/triaged/in_progress tickets, oldest first
#   fb.sh show <id>                  one ticket with its comment thread
#   fb.sh status <id> <status> [note]
#   fb.sh priority <id> <low|normal|high|urgent>
#
# Writes mirror the Feedback app's staff status action (app/routes/detail.tsx):
# status + updated_at + resolved_at, and a status_change comment in the same
# transaction. status_change rows never email the submitter.
set -euo pipefail

AUTHOR_ID='system:support-agent'
AUTHOR_NAME='Support bot'

q() { local URL="${FEEDBACK_DB_URL:-$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/x2u/feedback-db")}"; psql "$URL" -X -q -v ON_ERROR_STOP=1 "$@" 2>&1 | sed -E 's#postgres(ql)?://[^ ]*#<db-url>#g'; }

usage() { sed -n '2,9p' "$0"; exit 2; }
cmd="${1:-}"; shift || true
case "$cmd" in
list)
  q -A -F $'\t' <<'SQL'
begin;
select set_config('request.system','on',true) \g /dev/null
select f.id, f.created_at::date, f.status, coalesce(f.priority,'-') as priority, f.type, f.origin,
       f.source_app_key, f.org_id, left(regexp_replace(f.title,'\s+',' ','g'),80) as title,
       (select count(*) from feedback_comment c where c.feedback_id=f.id and c.author_user_id='system:support-agent') as bot_touches,
       (select count(*) from feedback_comment c where c.feedback_id=f.id and c.author_is_staff
          and c.author_user_id is distinct from 'system:support-agent') as staff_comments,
       (select max(c.created_at)::date from feedback_comment c where c.feedback_id=f.id) as last_comment
from feedback f
where f.status in ('open','triaged','in_progress')
order by f.created_at;
commit;
SQL
  ;;
show)
  [ $# -ge 1 ] || usage; id="$1"
  q -x -v id="$id" <<'SQL'
begin;
select set_config('request.system','on',true) \g /dev/null
select * from feedback where id = :'id';
select created_at, kind, new_status, author_name, author_is_staff, body
from feedback_comment where feedback_id = :'id' order by created_at;
select r2_key, content_type from feedback_attachment where feedback_id = :'id';
commit;
SQL
  ;;
status)
  [ $# -ge 2 ] || usage; id="$1"; st="$2"; note="${3:-}"
  case "$st" in open|triaged|in_progress|resolved|closed|wont_fix) ;; *) echo "bad status: $st" >&2; exit 2 ;; esac
  out=$(q -A -t -v id="$id" -v st="$st" -v note="$note" -v aid="$AUTHOR_ID" -v aname="$AUTHOR_NAME" <<'SQL'
begin;
select set_config('request.system','on',true) \g /dev/null
with cur as (
  select id, org_id, user_id from feedback
  where id = :'id' and status <> :'st' for update
), upd as (
  update feedback f set status = :'st', updated_at = now(),
         resolved_at = case when :'st' = 'resolved' then now() else null end
  from cur where f.id = cur.id returning f.id
)
insert into feedback_comment (feedback_id, org_id, feedback_user_id, author_user_id,
                              author_name, author_is_staff, kind, new_status, body)
select cur.id, cur.org_id, cur.user_id, :'aid', :'aname', true, 'status_change', :'st', nullif(:'note','')
from cur join upd on upd.id = cur.id
returning 'changed', feedback_id;
commit;
SQL
)
  echo "${out:-unchanged: $id is already $st (or does not exist)}"
  ;;
priority)
  [ $# -ge 2 ] || usage; id="$1"; p="$2"
  case "$p" in low|normal|high|urgent) ;; *) echo "bad priority: $p" >&2; exit 2 ;; esac
  out=$(q -A -t -v id="$id" -v p="$p" <<'SQL'
begin;
select set_config('request.system','on',true) \g /dev/null
update feedback set priority = :'p', updated_at = now() where id = :'id' returning 'priority', id, priority;
commit;
SQL
)
  echo "${out:-not found: $id}"
  ;;
*) usage ;;
esac
