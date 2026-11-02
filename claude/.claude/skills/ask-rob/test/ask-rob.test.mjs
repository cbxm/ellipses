// node --test ~/.claude/skills/ask-rob/test/
// Exercises the CLI's offline paths (no token is read) and the reply parsing
// and wait loop against a recorded conversations.replies response.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { SlackError, answersIn, formatAnswers, waitForAnswers } from '../scripts/lib.mjs';

const here = import.meta.dirname;
const CLI = join(here, '../scripts/ask-rob.mjs');
const fixture = JSON.parse(readFileSync(join(here, 'replies.fixture.json'), 'utf8'));
const PARENT = fixture.messages[0].ts;
const [parent, botFollowUp, steve] = fixture.messages;

// HOME points at an empty dir so a run that got past the guards would fail on
// the missing token instead of reaching Slack.
const newHome = () => mkdtempSync(join(tmpdir(), 'ask-rob-home-'));
function cliIn(home, ...args) {
  return spawnSync(process.execPath, [CLI, ...args], { encoding: 'utf8', env: { ...process.env, HOME: home } });
}

const cli = (...args) => cliIn(newHome(), ...args);

const stateDir = (home, dir) => join(home, 'src/x2u/.work/ask-rob', dir);
function putState(home, dir, q) {
  mkdirSync(stateDir(home, dir), { recursive: true });
  writeFileSync(join(stateDir(home, dir), `${q.id}.json`), JSON.stringify(q));
}
const sent = (id) => ({ id, ts: PARENT, channel: 'C0ASA6TH7QQ', sent_at: '2026-11-02T00:00:00Z', context: null });

function draft(text) {
  const dir = mkdtempSync(join(tmpdir(), 'ask-rob-'));
  const path = join(dir, 'no-show-fee.md');
  writeFileSync(path, text);
  return path;
}

test('send --dry-run prints the #dev payload mentioning Rob', () => {
  const r = cli('send', '--file', draft('Should a no-show fee apply?\n\n1. a\n2. b\n'), '--dry-run');
  assert.equal(r.status, 0, r.stderr);
  const p = JSON.parse(r.stdout);
  assert.equal(p.channel, 'C0ASA6TH7QQ');
  assert.match(p.text, /^<@U0ARUPH3T2M> Claude here, asking on Caden's behalf\.\n\nShould a no-show fee apply\?\n\n1\. a\n2\. b\n\n_Reply in thread\._$/);
});

test('send refuses without --approved, before reading the token', () => {
  const r = cli('send', '--file', draft('Question?'));
  assert.equal(r.status, 1);
  assert.match(r.stderr, /refusing to send without --approved/);
});

test('send with --approved gets past the guard, and a missing token leaves no stub', () => {
  const home = newHome();
  const r = cliIn(home, 'send', '--file', draft('Question?'), '--approved');
  assert.equal(r.status, 1);
  assert.match(r.stderr, /bot-token is missing/);
  assert.doesNotMatch(r.stderr, /may have posted/);
  assert.ok(!existsSync(join(stateDir(home, 'pending'), 'no-show-fee.json')));
});

test('cancel refuses without --approved', () => {
  const r = cli('cancel', 'no-show-fee');
  assert.equal(r.status, 1);
  assert.match(r.stderr, /refusing to delete/);
});

test('send rejects an empty draft', () => {
  const r = cli('send', '--file', draft('  \n'), '--dry-run');
  assert.equal(r.status, 1);
  assert.match(r.stderr, /empty/);
});

test('answers are Rob and Caden replies only, not the bot, the parent or others', () => {
  const answers = answersIn(fixture.messages, PARENT);
  assert.deepEqual(answers.map((x) => [x.who, x.text]), [
    ['Rob', 'Yes, but waive it for the first rebook.'],
    ['Caden', 'Noted, going with that.'],
  ]);
  const out = formatAnswers(answers);
  assert.match(out, /--- Rob \(2026-10-26 07:36 UTC, ts 1793000180\.000400\)\nYes, but waive/);
  assert.match(out, /\[1 attachment\(s\)/);
});

function poller(pages) {
  let calls = 0;
  const fetch = async () => pages[Math.min(calls++, pages.length - 1)];
  return { fetch, calls: () => calls };
}

const clock = () => {
  let t = 0;
  return { now: () => t, sleep: async (ms) => { t += ms; } };
};

test('wait keeps polling past bot-only threads and returns on Rob\'s reply', async () => {
  const rob = fixture.messages[3];
  const p = poller([[parent], [parent, botFollowUp, steve], [parent, botFollowUp, steve, rob]]);
  const answers = await waitForAnswers(p.fetch, PARENT, { timeoutMs: 3_600_000, intervalMs: 60_000, ...clock() });
  assert.equal(p.calls(), 3);
  assert.deepEqual(answers.map((x) => x.who), ['Rob']);
});

test('wait returns on Caden\'s reply alone', async () => {
  const caden = fixture.messages[4];
  const answers = await waitForAnswers(poller([[parent, caden]]).fetch, PARENT, { timeoutMs: 60_000, intervalMs: 60_000, ...clock() });
  assert.deepEqual(answers.map((x) => x.who), ['Caden']);
});

test('wait times out with null when only the bot has spoken', async () => {
  const p = poller([[parent, botFollowUp]]);
  const answers = await waitForAnswers(p.fetch, PARENT, { timeoutMs: 300_000, intervalMs: 60_000, ...clock() });
  assert.equal(answers, null);
  assert.equal(p.calls(), 6);
});

test('wait retries transient errors and stops on fatal ones', async () => {
  const rob = fixture.messages[3];
  let n = 0;
  const flaky = async () => {
    if (n++ === 0) throw new SlackError('conversations.replies', 'HTTP 503', { http: true });
    return [parent, rob];
  };
  const errors = [];
  const answers = await waitForAnswers(flaky, PARENT, { timeoutMs: 600_000, intervalMs: 60_000, ...clock(), onError: (e) => errors.push(e.message) });
  assert.deepEqual(answers.map((x) => x.who), ['Rob']);
  assert.deepEqual(errors, ['conversations.replies: HTTP 503']);

  const fatal = async () => { throw Object.assign(new Error('missing_scope'), { fatal: true }); };
  await assert.rejects(waitForAnswers(fatal, PARENT, { timeoutMs: 600_000, intervalMs: 60_000, ...clock() }), /missing_scope/);
});

test('send refuses while a stub from an interrupted send exists', () => {
  const home = newHome();
  putState(home, 'pending', { ...sent('no-show-fee'), ts: null });
  const r = cliIn(home, 'send', '--file', draft('Question?'), '--approved');
  assert.equal(r.status, 1);
  assert.match(r.stderr, /may have posted.*Check #dev, then delete the stub/);
});

test('done moves a question to answered, and again is a no-op', () => {
  const home = newHome();
  putState(home, 'pending', sent('no-show-fee'));
  for (let i = 0; i < 2; i++) {
    const r = cliIn(home, 'done', 'no-show-fee');
    assert.equal(r.status, 0, r.stderr);
  }
  assert.ok(!existsSync(join(stateDir(home, 'pending'), 'no-show-fee.json')));
  assert.ok(existsSync(join(stateDir(home, 'answered'), 'no-show-fee.json')));
});

test('check reports each question\'s error and carries on', () => {
  const home = newHome();
  putState(home, 'pending', { ...sent('a-stub'), ts: null });
  putState(home, 'pending', sent('b-real'));
  const r = cliIn(home, 'check');
  assert.equal(r.status, 1);
  assert.match(r.stdout, /== a-stub\nerror: a-stub may have posted/);
  assert.match(r.stdout, /== b-real\nerror: .*bot-token is missing/);
  assert.match(r.stderr, /2 of 2 question\(s\) could not be checked/);
});

test('wait --since ignores replies already seen', async () => {
  const [, , , rob, caden] = fixture.messages;
  const answers = await waitForAnswers(poller([[parent, rob, caden]]).fetch, PARENT, { since: rob.ts, timeoutMs: 60_000, intervalMs: 60_000, ...clock() });
  assert.deepEqual(answers.map((x) => x.who), ['Caden']);
  const none = await waitForAnswers(poller([[parent, rob, caden]]).fetch, PARENT, { since: caden.ts, timeoutMs: 60_000, intervalMs: 60_000, ...clock() });
  assert.equal(none, null);
});

test('wait retries Slack outages and rate limits, stops on permanent errors', async () => {
  const rob = fixture.messages[3];
  const outages = ['ratelimited', 'internal_error', 'service_unavailable', 'fatal_error'];
  let n = 0;
  const flaky = async () => {
    if (n < outages.length) throw new SlackError('conversations.replies', outages[n++]);
    return [parent, rob];
  };
  const answers = await waitForAnswers(flaky, PARENT, { timeoutMs: 3_600_000, intervalMs: 60_000, ...clock() });
  assert.deepEqual(answers.map((x) => x.who), ['Rob']);

  for (const code of ['thread_not_found', 'not_in_channel', 'missing_scope']) {
    const gone = async () => { throw new SlackError('conversations.replies', code); };
    await assert.rejects(waitForAnswers(gone, PARENT, { timeoutMs: 600_000, intervalMs: 60_000, ...clock() }), new RegExp(code));
  }
});

test('wait exits 1 at once on a missing token, not 2 after the timeout', () => {
  const home = newHome();
  putState(home, 'pending', sent('no-show-fee'));
  const r = cliIn(home, 'wait', 'no-show-fee', '--timeout', '30s', '--interval', '10s');
  assert.equal(r.status, 1);
  assert.match(r.stderr, /bot-token is missing/);
});

test('wait rejects a malformed --since before polling', () => {
  const home = newHome();
  putState(home, 'pending', sent('no-show-fee'));
  for (const since of ['yesterday', '1793000180.0004x', '']) {
    const r = cliIn(home, 'wait', 'no-show-fee', '--since', since, '--timeout', '30s', '--interval', '10s');
    assert.equal(r.status, 1, since);
    assert.match(r.stderr, /is not a Slack ts/);
  }
});

test('wait stops on an error that is not a Slack outage', async () => {
  const bug = async () => { throw new TypeError('x is undefined'); };
  await assert.rejects(waitForAnswers(bug, PARENT, { timeoutMs: 600_000, intervalMs: 60_000, ...clock() }), TypeError);
});
