---
name: post-report-to-slack
description: Announce a shipped x2u change in Slack #devlog with before/after screenshots of production. `old <MR>` captures the OLD screen while the MR is unmerged and is required before merging any x2u MR whose Screens is not none (a hook blocks the merge otherwise); `new <MR>` captures NEW once main has deployed it and posts a title, a plain-language paragraph and up to two technical ones; `sweep` posts `new` for every deployed MR still owed one. Use before merging an MR with a user-visible change, after it deploys, from the devlog routine, or whenever the user asks to post a report, announce a release or share before/after screenshots in Slack.
argument-hint: "old|new <MR url or !iid> | sweep"
---

# post-report-to-slack

The post is read by non-engineers first and by Steve (the CTO) second, so it
needs a real picture of the change, not a diff. Prod serves one version at a
time, which forces two runs: `old` while the MR is still unmerged, `new` once
the main pipeline has deployed it. Usually different sessions run them, so
`old` leaves everything `new` needs on disk.

Two things enforce this outside the prose. A PreToolUse hook
(`scripts/hook-gate.sh`, registered in `~/.claude/settings.json`) denies
`glab mr create` in x2u/{ai7,salon,admick,gcal} without a `Screens:` line, and
`glab mr merge` of an MR without a Screens line, or whose Screens is not
`none` (`n/a` and `no user-visible change` count as none), until
`$DIR/old-annotated.png` exists. `DEVLOG_SKIP=1 glab mr merge ...` waives it
for an MR the user waived. It sees only `glab mr create|merge`: merging
through `glab api .../merge` or the GitLab web UI bypasses it. A routine runs
`sweep`, which posts `new` unattended once the deploy is live.

**Who approves a post.** `new` invoked by a person: dry-run, show them the
title, body and images, and post only after they agree. `sweep` (the routine,
or a person asking for a sweep): posts without asking. Nowhere else differs.

Scripts live in `~/.claude/skills/post-report-to-slack/scripts/`. First use on
a machine: `npm ci` in `~/.claude/skills/post-report-to-slack/` (playwright is
pinned to the version whose chromium is already in `~/.cache/ms-playwright`;
if it reports a missing browser, the pin and the cache have drifted, so match
the pin to an installed `chromium-<rev>` rather than downloading).
`scripts/annotate` is python3 and needs Pillow: `sudo apt install python3-pil`
(Ubuntu blocks `pip install --user`).

Setup the scripts expect (they fail with instructions if missing):
- `~/.config/x2u-devlog/prod-test-account.json` (chmod 600):
  `{"email": "...", "password": "..."}` for the prod test account.
- `~/.config/x2u-devlog/bot-token` (chmod 600): the Caden's Bot app's
  `xoxb-` token. The app is defined by `slack-app-manifest.yaml` here and must
  be invited to #devlog.

## Shot directory

`DIR=~/src/x2u/.work/devlog/<repo>-<iid>/` (e.g. `ai7-214`), created by `old`.
It holds `old.png`, `old.png.boxes.json`, `old-annotated.png` and `recipe.md`:
the exact capture and annotate commands, so `new` repeats them on the deployed
site. Name the directory in your report.

## 1. Know what to show

Resolve the MR with glab (`glab mr view <iid> -R x2u/<repo> -F json`). Read
its description for a `Screens:` line: a page under `https://app.x2u.ai/`
(`/ai7/...`, the salon console `/salon/...`, the admin console
`/console/...`; often written as just the path, with `:id` placeholders) and
the element that shows the change, or `none`. The value is the rest of that
line, or, when the line ends at the colon, the lines below it up to the next
blank line (often a `- ` list of several screens; capture the first, or the
one the title is about). Without a Screens line, work out the screen from the
diff (routes and components touched) and confirm it with the user (in
`sweep`, decide yourself). A backend-only change or `Screens: none` gets no
images; say so in the post.

All x2u apps sit on the one `app.x2u.ai` origin behind the same sign-in, so
`capture.mjs --url '/salon/...'` or `'/console/...'` works like `/ai7/...`.

The seeded Review org has one "Review Demo Agent" and one web conversation to
point at. Anything else the screen needs, set up as the test account would,
and leave it there. Never touch real customer data.

## 2. Capture

One `capture.mjs` call signs in if needed, navigates, runs the clicks and
waits in the order given, measures the boxes and screenshots, all in the same
viewport state (screenshot pixels match CSS boxes only within one state).

Find selectors first with `--aria`, which prints the accessibility tree:

```bash
S=~/.claude/skills/post-report-to-slack/scripts
node $S/capture.mjs --url '/ai7/...' --aria
node $S/capture.mjs --url '/ai7/...' --click 'role=tab[name="Settings"]' --aria --parent '<css>'
```

Selectors are Playwright locator strings: CSS, `role=button[name="Save"]`,
`text=Quiet hours`. Then capture:

```bash
node $S/capture.mjs --url '/ai7/...' \
  --click '<sel>' --wait '<sel>' \
  --parent '<modal / tab panel / card>' --target '<changed element>' \
  --out $DIR/old.png
$S/annotate $DIR/old.png $DIR/old-annotated.png --crop parent --circle target
```

`capture` writes the boxes and DPR to `old.png.boxes.json`; `annotate` reads
them when given `parent` / `target` (explicit box JSON in CSS px also works).
Default viewport is skinny, `800x900`; if that hides or squashes the feature,
re-run the whole capture with `--viewport 1440x900`. A warning that a box runs
outside the viewport means the crop will be cut: use a taller viewport.

Read the annotated PNG before going on. Crop to the parent that gives context
(the whole modal, the tab panel, the settings card), never the whole page. Put
a red circle round the change, or an arrow (`--arrow target`) when it is small
or new and has no old counterpart, or a full-width row in a dense list (a
circle round it crosses the rows above and below). For OLD, mark where the
change will appear. Never write OLD / NEW onto the images: the Slack captions
say which is which.

## Mode `old <MR>`

1. The MR must be open and unmerged; if it already merged, prod may be serving
   NEW already, so say so and stop.
2. Steps 1–2 above into `$DIR`, then write `$DIR/recipe.md` with the MR URL,
   the `Screens:` target and the exact commands used.
3. Report the directory and the annotated image path.

## Mode `new <MR>`

1. Confirm the MR is merged and its commit has deployed: find the main
   pipeline for `merge_commit_sha` (null on a fast-forward merge: then
   `squash_commit_sha`, else `sha`) with `glab api
   "projects/x2u%2F<repo>/pipelines?sha=<sha>&ref=main"` and check its
   `deploy:production` and `smoke:production` jobs succeeded (salon and gcal
   have no smoke job; admick deploys in a child pipeline; a run of
   `rollback:production` means NEW is not live). `sweep.mjs` does exactly
   this check. Not deployed yet → stop and say when to retry.
2. Re-run `$DIR/recipe.md`'s commands with `--out $DIR/new.png`, annotate to
   `$DIR/new-annotated.png`, and Read it. If the element moved, adjust the
   selectors, not the crop logic.
3. No `$DIR/old-annotated.png` → post anyway, and the text says why there is
   no before picture.
4. Write the body (below) to `$DIR/body.md`, dry-run it and Read the
   payload as a self-check (title, paragraph 1 in plain language, images and
   alt text present, links right). Then approval as set out at the top
   (person: show and wait for agreement; `sweep`: none), then post for real.
5. Report the permalink. `post.mjs` writes `$DIR/posted.json`
   `{ts, permalink}` as soon as the card is up, which marks the MR done for
   `sweep`. If #devlog already has a card linking the MR (posted from another
   machine), it posts nothing, records that card, and prints its permalink.

## Mode `sweep`

Run by the devlog routine; also fine by hand.

```bash
node $S/sweep.mjs   # JSON {cutoff, pending, needs_screen, waiting, skipped}; read-only
```

It covers only MRs authored by the glab-authenticated user (resolved with
`glab api user` each run); other authors' MRs are their own pipeline's job
(Steve's post from his "Steve's Assistant" app), and the #devlog check below
stays as the backstop against a double post.

It lists MRs in x2u/{ai7,salon,admick,gcal} merged after its `CUTOFF`
(no backfill), whose Screens is not `none`, with no `posted.json`, no card in
#devlog already linking them, fewer than 3 recorded failures, and a live deploy (`deploy:production` and,
where the repo has one, `smoke:production` succeeded with no
`rollback:production` run, on its own main pipeline or a later one; admick's
deploy job is in a child pipeline and is followed). `waiting` = merged but not
live yet: leave it for the next sweep. `skipped` says why for the rest.

For each `pending` entry, run mode `new` on its `url` with no questions to
anyone: no `recipe.md` (`has_recipe: false`, e.g. merged without `old`) →
build the capture from the `screens` value and the diff yourself. Each
`needs_screen` entry has no Screens line: read the diff (`glab mr diff <iid>
-R x2u/<repo>`), pick the screen as in section 1 and run `new`; if nothing
user-visible changed, post text only (no images, `--tag "Backend only:gray"`).
Any step
that fails (capture, selectors gone, Slack error) →

```bash
node $S/sweep.mjs fail <repo>-<iid> "<one-line reason>"
```

which appends to `$DIR/failed.md`; the next sweep retries. The third failure
posts one line to #dev (`C0ASA6TH7QQ`) with the bot and the MR drops out of
the sweep; delete `failed.md` to retry it. `fail --dry-run` shows what it
would write and post. Move on to the next MR after a failure. End with one
line per MR: posted <permalink> | waiting (<reason>) | failed (<reason>).

`post.mjs` needs `--mr` as the MR url, or `--mr !<iid> -R x2u/<repo>`, for any
#devlog post; without it, it refuses rather than post a card the sweep cannot
mark done.

## 3. Post to #devlog (channel `C0CCSDAS7NG`)

The body is Slack mrkdwn (`*bold*`, `_italic_`, `` `code` ``, `<url|text>`),
paragraphs separated by blank lines:

- **Paragraph 1, for anyone**: what a customer or operator notices now, and
  why it matters. No code, no table names.
- **Up to two more, for Steve**: the mechanism and the trade-offs, as
  technical as the change needs and no longer.

Three paragraphs is the ceiling. The title goes in `--title`, in product terms
(`Send Later now snaps out of quiet hours`), and the links go in the buttons,
not the text.

```bash
node $S/post.mjs --title "<title>" --body $DIR/body.md \
  --task <issue url> --mr <mr url> --deploy <pipeline url> \
  --new $DIR/new-annotated.png --new-alt "<what NEW shows, where the mark is>" \
  --old $DIR/old-annotated.png --old-alt "<what OLD shows, where the mark is>" \
  --dry-run
```

Drop `--dry-run` for the real post. The card holds the header, paragraph 1,
See Task / See MR / See Deployment buttons, a muted line (repo and MR number,
ship date, author, and any link that is missing as "nothing linked", since
Block Kit has no disabled button) and the NEW image. A thread reply holds the
technical paragraphs and the OLD image, so the channel reads as what changed
and the thread as how. Author and ship date come from the MR via glab;
`--author` / `--shipped` override. Images left out are skipped; with no
technical paragraphs and no OLD there is no thread reply. It prints the
card's permalink.

Always write `--new-alt` / `--old-alt`: one plain sentence saying which screen
it is and what the red mark points at (`Agent settings, Quiet hours card;
circle round the new "Snap to open" toggle`). It is all a screen reader gets.

Optional pieces, each with its trigger:

- `--tag "<text>:<color>"` (gray, brown, purple, indigo, blue, green, yellow,
  orange, red; without a color suffix the whole string is the text): a caveat the reader must not miss, such as `Behind flag:yellow`
  or `Backend only:gray`. At most one; none is the usual case.
- `--table <file>`: the change is to values or options (a default, a limit, a
  list of choices). Tab-separated, header row first, normally
  `Setting<TAB>Before<TAB>After`. Use it with or without a screenshot, and
  instead of one when the change has no screen. Max 100 rows, 20 columns,
  10,000 characters.
- `--chart <file>`: the change moved a measured number (p95 latency, error
  rate, cost). A `data_visualization` block, or an array of two: `title` ≤50
  chars, `chart.type` bar/line/area/pie, ≤12 series × ≤20 points, labels ≤20
  chars, every series has one point per `axis_config.categories` entry. Use
  real measurements only, and say where they came from in the thread. A bar
  chart with categories `Before` / `After` fits most cases.
- `--collapse`: puts the technical paragraphs and OLD in a collapsed "How it
  works" container on the card instead of the thread. The container block is new
  and untested on older clients; prefer the thread, and use this only when
  the user asks for a single message.

If Slack rejects a block, the error names the flag behind it; fix or drop
that flag rather than retrying.

Exit 1 with a permalink printed = the card is up but its thread reply failed;
re-run with `--thread-ts <ts>` (printed on stderr), never re-run the whole
post. If the bot cannot post, the Slack MCP is the fallback for reading the
channel; do not repost as the user.
