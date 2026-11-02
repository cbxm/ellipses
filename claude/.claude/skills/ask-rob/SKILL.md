---
name: ask-rob
description: Ask Rob Thatcher (X2U/SalesComm business owner) a business, policy or customer question in Slack #dev through Caden's bot, then wait for his answer and resume. Use when work is blocked on a decision only Rob can make, or to check whether earlier questions to Rob have been answered.
argument-hint: "send|wait|check|cancel"
---

# ask-rob

Rob owns X2U's business decisions: pricing, policy, what customers are told,
which customer gets what. He is not an engineer. The question goes to #dev
(`C0ASA6TH7QQ`, public) as a mention of him from the Caden Devlog bot, and he
answers in the thread.

Script: `S=~/.claude/skills/ask-rob/scripts` then `node $S/ask-rob.mjs ...`.
State lives in `~/src/x2u/.work/ask-rob/`: drafts as `<id>.md`, sent questions
in `pending/`, then `answered/` or `cancelled/`. `<id>` is a short slug
(`no-show-fee-rebook`), the draft's basename.

## When to ask

Only for decisions that are Rob's to make. Never for facts: anything the code,
Meevo data, D1/Neon, docs or Slack history can answer, look up instead, and
search Slack for whether he has already decided it. A technical choice is
Caden's, not Rob's.

Before drafting, ask Caden in the conversation first: he may know the answer,
or prefer to ask Rob himself. Draft only once he says to.

One message per decision. Related sub-questions go in the same message,
numbered so he can answer `1. yes 2. no`.

## Drafting

Write `~/src/x2u/.work/ask-rob/<id>.md` in Slack mrkdwn (`*bold*`, `_italic_`,
`<url|text>`), short, for a non-engineer:

- what is being decided, in product and customer terms (no table names, no code);
- the options considered and what each means for customers or the business;
- Claude's recommendation and why, in a sentence;
- what is blocked until he answers.

The script adds the mention of Rob, a line saying Claude is asking on Caden's
behalf, and "Reply in thread." Don't repeat them.

## Approval

Show the user the exact text (`send --file <draft> --dry-run` prints the
payload) and send only after they explicitly OK it in the conversation. Any
edit after the OK needs a fresh OK. Never mention or DM Rob any other way.

## Send, then wait

```bash
node $S/ask-rob.mjs send --file ~/src/x2u/.work/ask-rob/<id>.md --approved --context <task slug>
node $S/ask-rob.mjs wait <id>            # --timeout 4h --interval 60s by default
node $S/ask-rob.mjs done <id>            # once the question is settled
```

`send` writes `pending/<id>.json` with `ts: null` before posting and fills it
in after. If it dies in between, the question may or may not be in #dev, so
`send` refuses to run again until someone has looked at #dev and deleted the
stub. Never delete it without looking.

Run `wait` with Bash `run_in_background`, so the session is re-invoked when it
exits, and carry on with anything that does not depend on the answer. Exit 0
prints the replies from Rob, and from Caden (labelled), who may answer instead;
exit 2 is a timeout. Other people's replies and the bot's own are ignored.

A reply answers only what it says. "Let me check" or half an answer is not a
decision: bring it to the user, and wait again with the `--since <ts>` that
`wait` prints so old replies don't count. Nothing leaves `pending/` until
`done <id>`, run when the user and you agree it is answered.

On a timeout or a long silence, read #dev around the question's permalink
with the Slack MCP (`slack_read_channel` / `slack_read_thread`): Rob may have
answered top-level instead of in the thread, or with just a reaction, which
the script cannot see. Tell the user either way; don't re-ask or nudge Rob.

## Later sessions

`node $S/ask-rob.mjs check` lists every pending question with all its replies
so far, so an answer a backgrounded `wait` printed into a finished session is
not lost. `check <id>` looks at one. A question that fails (deleted thread,
interrupted send) is reported and the rest are still checked. Run it at the
start of a session that may have asked Rob something, then `done` the settled
ones.

## Cancel

`node $S/ask-rob.mjs cancel <id> --approved` deletes the question from #dev
and moves it to `cancelled/`. Only with the user's OK, e.g. when the question
became moot.

## Setup

The bot is the Caden Devlog app (`post-report-to-slack/slack-app-manifest.yaml`;
token in `~/.config/x2u-devlog/bot-token`). It needs `channels:history` to
read replies and must be a member of #dev. `missing_scope` means the app has
not been reinstalled since that scope was added; `not_in_channel` means
`/invite @Caden Devlog` in #dev. The script says which.

Tests: `node --test ~/.claude/skills/ask-rob/test/*.test.mjs` (offline).
