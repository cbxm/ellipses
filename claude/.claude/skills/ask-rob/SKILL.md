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
```

Run `wait` with Bash `run_in_background`, so the session is re-invoked when it
exits, and carry on with anything that does not depend on the answer. Exit 0
prints the replies from Rob, and from Caden (labelled), who may answer instead;
exit 2 is a timeout. Other people's replies and the bot's own are ignored. On
exit 2, tell the user and leave it pending; don't re-ask or nudge Rob.

A reply answers only what it says. If it is ambiguous or covers half the
question, bring it to the user rather than reading it as a decision.

## Later sessions

`node $S/ask-rob.mjs check` lists every pending question with any replies
that have arrived, and moves answered ones to `answered/`. `check <id>` looks
at one. Run it at the start of a session that may have asked Rob something.

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
