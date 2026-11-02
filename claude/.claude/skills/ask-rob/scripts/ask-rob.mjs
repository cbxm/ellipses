#!/usr/bin/env node
// Ask Rob a question in #dev through Caden's Slack bot and collect his answer.
//
//   ask-rob.mjs send --file <draft.md> --approved [--context <slug>] [--dry-run]
//   ask-rob.mjs wait <id> [--timeout 4h] [--interval 60s]
//   ask-rob.mjs check [<id>]
//   ask-rob.mjs cancel <id> --approved
//
// <id> is the draft's basename without .md. State lives in
// ~/src/x2u/.work/ask-rob/{pending,answered,cancelled}/<id>.json.
//
// wait exits 0 printing Rob's (and Caden's) thread replies once any exist,
// 2 on timeout, 1 on error. check lists pending questions with any replies and
// moves answered ones to answered/.

import { mkdir, readFile, readdir, rename, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { basename, join } from 'node:path';
import { parseArgs } from 'node:util';
import { DEV, answersIn, formatAnswers, parseDuration, questionPayload, waitForAnswers } from './lib.mjs';

const TOKEN_FILE = join(homedir(), '.config/x2u-devlog/bot-token');
const STATE = join(homedir(), 'src/x2u/.work/ask-rob');
const MANIFEST = '~/.claude/skills/post-report-to-slack/slack-app-manifest.yaml';

function die(msg, code = 1) {
  console.error(`ask-rob: ${msg}`);
  process.exit(code);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const [cmd, ...rest] = process.argv.slice(2);
const { values: a, positionals } = (() => {
  try {
    return parseArgs({
      args: rest,
      allowPositionals: true,
      strict: true,
      options: {
        file: { type: 'string' },
        context: { type: 'string' },
        approved: { type: 'boolean', default: false },
        'dry-run': { type: 'boolean', default: false },
        timeout: { type: 'string', default: '4h' },
        interval: { type: 'string', default: '60s' },
      },
    });
  } catch (e) {
    die(e.message);
  }
})();

// --- Slack -----------------------------------------------------------------

class SlackError extends Error {
  constructor(method, code, extra = {}) {
    super(`${method}: ${code}`);
    this.code = code;
    // ok:false answers are permanent (bad scope, channel, ts); HTTP and
    // network failures are worth retrying.
    this.fatal = extra.fatal ?? true;
    this.needed = extra.needed;
  }
}

let token;
async function api(method, params) {
  token ??= await readToken();
  const body = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined) body.set(k, typeof v === 'string' ? v : JSON.stringify(v));
  }
  const res = await fetch(`https://slack.com/api/${method}`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}` },
    body,
  });
  if (!res.ok) throw new SlackError(method, `HTTP ${res.status}`, { fatal: false });
  const json = await res.json();
  if (!json.ok) throw new SlackError(method, json.error, { needed: json.needed });
  return json;
}

async function readToken() {
  let t;
  try {
    t = (await readFile(TOKEN_FILE, 'utf8')).trim();
  } catch {
    die(`${TOKEN_FILE} is missing; paste the bot's xoxb- token into it (chmod 600)`);
  }
  if (!t.startsWith('xoxb-')) die(`${TOKEN_FILE} does not hold a bot (xoxb-) token`);
  return t;
}

function explain(e) {
  if (e.code === 'missing_scope') {
    // Slack lists every history scope for conversations.replies; #dev is public,
    // so channels:history is the one that matters.
    const scope = e.message.startsWith('conversations.replies') ? 'channels:history' : (e.needed ?? 'a scope the bot lacks');
    return `${e.message}: the bot token lacks ${scope}. Add it to the bot scopes in ${MANIFEST}, ` +
      'update the app at api.slack.com/apps from that manifest, reinstall it to the workspace, and ' +
      `paste the token into ${TOKEN_FILE} if it changed`;
  }
  if (e.code === 'not_in_channel' || e.code === 'channel_not_found') {
    return `${e.message}. Invite the bot to #dev: /invite @Caden Devlog`;
  }
  return e.message;
}

async function threadMessages(channel, ts) {
  const messages = [];
  let cursor;
  do {
    const page = await api('conversations.replies', { channel, ts, limit: '200', cursor });
    messages.push(...page.messages);
    cursor = page.response_metadata?.next_cursor || undefined;
  } while (cursor);
  return messages;
}

// --- State -----------------------------------------------------------------

const statePath = (dir, id) => join(STATE, dir, `${id}.json`);

async function load(id) {
  for (const dir of ['pending', 'answered']) {
    try {
      return { dir, q: JSON.parse(await readFile(statePath(dir, id), 'utf8')) };
    } catch (e) {
      if (e.code !== 'ENOENT') throw e;
    }
  }
  die(`no pending or answered question ${id} in ${STATE}`);
}

async function move(id, from, to) {
  if (from === to) return;
  await mkdir(join(STATE, to), { recursive: true });
  await rename(statePath(from, id), statePath(to, id));
}

async function exists(path) {
  return readFile(path).then(() => true, (e) => (e.code === 'ENOENT' ? false : Promise.reject(e)));
}

// --- Commands --------------------------------------------------------------

async function send() {
  if (!a.file) die('send needs --file <draft.md>');
  const id = basename(a.file).replace(/\.md$/, '');
  let payload;
  try {
    payload = questionPayload(await readFile(a.file, 'utf8'));
  } catch (e) {
    die(`${a.file}: ${e.message}`);
  }
  if (a['dry-run']) {
    console.log(JSON.stringify(payload, null, 2));
    return;
  }
  if (!a.approved) {
    die('refusing to send without --approved: show the user the exact draft and get an explicit OK first');
  }
  for (const dir of ['pending', 'answered', 'cancelled']) {
    if (await exists(statePath(dir, id))) die(`${id} was already sent (${dir}/${id}.json); rename the draft`);
  }

  const posted = await api('chat.postMessage', payload);
  const { permalink } = await api('chat.getPermalink', { channel: posted.channel, message_ts: posted.ts })
    .catch(() => ({ permalink: null }));
  const q = {
    id,
    ts: posted.ts,
    channel: posted.channel,
    permalink,
    sent_at: new Date().toISOString(),
    context: a.context ?? null,
    question: payload.text,
  };
  await mkdir(join(STATE, 'pending'), { recursive: true });
  await writeFile(statePath('pending', id), JSON.stringify(q, null, 2) + '\n');
  console.log(`sent ${id} ts ${posted.ts}`);
  if (permalink) console.log(permalink);
}

async function wait() {
  const [id] = positionals;
  if (!id) die('wait needs <id>');
  let timeoutMs, intervalMs;
  try {
    timeoutMs = parseDuration(a.timeout);
    intervalMs = parseDuration(a.interval);
  } catch (e) {
    die(e.message);
  }
  if (intervalMs < 10_000) die('--interval under 10s would hit Slack rate limits');
  const { dir, q } = await load(id);

  const answers = await waitForAnswers(() => threadMessages(q.channel, q.ts), q.ts, {
    timeoutMs,
    intervalMs,
    sleep,
    onError: (e) => console.error(`ask-rob: ${e.message}; retrying`),
  });
  if (!answers) die(`no reply to ${id} after ${a.timeout}; ${q.permalink ?? q.ts}`, 2);
  await move(id, dir, 'answered');
  console.log(`${id}: ${q.permalink ?? q.ts}\n`);
  console.log(formatAnswers(answers));
}

async function check() {
  const [only] = positionals;
  let ids;
  if (only) {
    ids = [only];
  } else {
    ids = (await readdir(join(STATE, 'pending')).catch(() => []))
      .filter((f) => f.endsWith('.json'))
      .map((f) => f.slice(0, -5));
    if (!ids.length) {
      console.log('no pending questions');
      return;
    }
  }
  for (const id of ids) {
    const { dir, q } = await load(id);
    const answers = answersIn(await threadMessages(q.channel, q.ts), q.ts);
    const ctx = q.context ? ` [${q.context}]` : '';
    console.log(`== ${id}${ctx} sent ${q.sent_at} ${q.permalink ?? q.ts}`);
    if (answers.length) {
      await move(id, dir, 'answered');
      console.log(formatAnswers(answers));
    } else {
      console.log('no reply yet');
    }
    console.log();
  }
}

async function cancel() {
  const [id] = positionals;
  if (!id) die('cancel needs <id>');
  if (!a.approved) die('refusing to delete the question without --approved: get the user\'s OK first');
  const { dir, q } = await load(id);
  await api('chat.delete', { channel: q.channel, ts: q.ts });
  await move(id, dir, 'cancelled');
  console.log(`deleted ${id} (ts ${q.ts}) from ${q.channel === DEV ? '#dev' : q.channel}`);
}

const commands = { send, wait, check, cancel };
if (!commands[cmd]) die(`usage: ask-rob.mjs send|wait|check|cancel ... (got ${cmd ?? 'nothing'})`);
try {
  await commands[cmd]();
} catch (e) {
  die(e instanceof SlackError ? explain(e) : e.message);
}
