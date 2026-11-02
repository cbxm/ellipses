#!/usr/bin/env node
// Post a devlog card to Slack: header, paragraph 1, link buttons and the NEW
// image in the channel; technical paragraphs and the OLD image in a thread.
//
//   post.mjs --title <text> --body <file> [--task <url>] [--mr <url>]
//            [--deploy <url>] [--new <png>] [--old <png>]
//            [--channel C0CCSDAS7NG] [--thread-ts <ts>] [--dry-run]
//
// The body is Slack mrkdwn, paragraphs separated by blank lines: the first
// goes in the channel, up to two more go in the thread. --dry-run prints both
// payloads and touches nothing. A real post prints the card's permalink.
// --thread-ts posts only the thread reply under an existing card, for when the
// card went up but its reply failed.

import { readFile, stat } from 'node:fs/promises';
import { homedir } from 'node:os';
import { basename, join } from 'node:path';
import { parseArgs } from 'node:util';

const TOKEN_FILE = join(homedir(), '.config/x2u-devlog/bot-token');
const DEVLOG = 'C0CCSDAS7NG';
const LINKS = [
  ['task', 'See Task'],
  ['mr', 'See MR'],
  ['deploy', 'See Deployment'],
];

function die(msg) {
  console.error(`post: ${msg}`);
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const { values: a } = parseArgs({
  options: {
    title: { type: 'string' },
    body: { type: 'string' },
    task: { type: 'string' },
    mr: { type: 'string' },
    deploy: { type: 'string' },
    new: { type: 'string' },
    old: { type: 'string' },
    channel: { type: 'string', default: DEVLOG },
    'thread-ts': { type: 'string' },
    'dry-run': { type: 'boolean', default: false },
  },
  strict: true,
});

if (!a.title) die('--title is required');
if (!a.body) die('--body is required');
if (a.title.length > 150) die(`--title is ${a.title.length} chars; Slack headers allow 150`);

const paragraphs = (await readFile(a.body, 'utf8'))
  .split(/\n\s*\n/)
  .map((p) => p.trim())
  .filter(Boolean);
if (paragraphs.length === 0) die(`${a.body} is empty`);
if (paragraphs.length > 3) die(`${a.body} has ${paragraphs.length} paragraphs; the ceiling is 3`);
const [lead, ...technical] = paragraphs;
for (const p of paragraphs) if (p.length > 3000) die('a paragraph is over Slack\'s 3000-char section limit');

const replyOnly = a['thread-ts'];
if (replyOnly && technical.length === 0 && !a.old) die('--thread-ts given but there is no thread reply to post');

for (const key of ['new', 'old']) {
  if (!a[key] || (key === 'new' && replyOnly)) continue;
  const s = await stat(a[key]).catch(() => null);
  if (!s?.isFile()) die(`--${key} ${a[key]} is not a file`);
}

function cardBlocks(newFileId) {
  const blocks = [
    { type: 'header', text: { type: 'plain_text', text: a.title, emoji: true } },
    { type: 'section', text: { type: 'mrkdwn', text: lead } },
  ];
  const buttons = LINKS.filter(([k]) => a[k]).map(([k, label]) => ({
    type: 'button',
    action_id: `devlog_${k}`,
    text: { type: 'plain_text', text: label },
    url: a[k],
  }));
  if (buttons.length) blocks.push({ type: 'actions', elements: buttons });
  // Block Kit has no disabled button, so a missing link is listed as muted text.
  const missing = LINKS.filter(([k]) => !a[k]).map(([, label]) => label.replace(/^See /, ''));
  if (missing.length) {
    blocks.push({
      type: 'context',
      elements: [{ type: 'mrkdwn', text: `${missing.join(' · ')}: nothing linked` }],
    });
  }
  if (newFileId) blocks.push(imageBlock(newFileId, 'After', `After: ${a.title}`));
  return blocks;
}

function threadBlocks(oldFileId) {
  const blocks = technical.map((p) => ({ type: 'section', text: { type: 'mrkdwn', text: p } }));
  if (oldFileId) blocks.push(imageBlock(oldFileId, 'Before', `Before: ${a.title}`));
  return blocks;
}

function imageBlock(id, caption, alt) {
  return {
    type: 'image',
    slack_file: { id },
    title: { type: 'plain_text', text: caption },
    alt_text: alt.slice(0, 2000),
  };
}

function payloads(newFileId, oldFileId) {
  const card = { channel: a.channel, text: a.title, unfurl_links: false, blocks: cardBlocks(newFileId) };
  const blocks = threadBlocks(oldFileId);
  const thread = blocks.length
    ? { channel: a.channel, thread_ts: a['thread-ts'] ?? '<card ts>', text: `${a.title}: details`, unfurl_links: false, blocks }
    : null;
  return { card, thread };
}

if (a['dry-run']) {
  const { card, thread } = payloads(a.new && `<upload of ${a.new}>`, a.old && `<upload of ${a.old}>`);
  console.log(JSON.stringify(replyOnly ? { thread } : { card, thread }, null, 2));
  process.exit(0);
}

let token;
try {
  token = (await readFile(TOKEN_FILE, 'utf8')).trim();
} catch {
  die(`${TOKEN_FILE} is missing; paste the bot's xoxb- token into it (chmod 600)`);
}
if (!token.startsWith('xoxb-')) die(`${TOKEN_FILE} does not hold a bot (xoxb-) token`);

async function api(method, params) {
  const body = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined) body.set(k, typeof v === 'string' ? v : JSON.stringify(v));
  }
  const res = await fetch(`https://slack.com/api/${method}`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}` },
    body,
  });
  if (!res.ok) throw new SlackError(method, `HTTP ${res.status}`);
  const json = await res.json();
  if (!json.ok) throw new SlackError(method, json.error, json.response_metadata?.messages);
  return json;
}

class SlackError extends Error {
  constructor(method, code, details) {
    super(`${method}: ${code}${details ? ` ${JSON.stringify(details)}` : ''}`);
    this.code = code;
  }
}

async function upload(path, title) {
  const bytes = await readFile(path);
  const { upload_url, file_id } = await api('files.getUploadURLExternal', {
    filename: basename(path),
    length: String(bytes.length),
    alt_txt: title,
  });
  const res = await fetch(upload_url, { method: 'POST', body: bytes });
  if (!res.ok) throw new Error(`upload of ${path} failed: HTTP ${res.status}`);
  // No channel: the file stays private to the bot and is shown only through
  // the image block that references it.
  await api('files.completeUploadExternal', { files: [{ id: file_id, title }] });
  return file_id;
}

// An image block naming a file Slack has not finished processing is rejected
// as invalid_blocks, so wait for the image dimensions to appear.
async function waitProcessed(id) {
  for (let i = 0; i < 20; i++) {
    const { file } = await api('files.info', { file: id });
    if (file.original_w) return;
    await sleep(1000);
  }
  console.error(`post: warning: file ${id} still processing after 20s; posting anyway`);
}

async function postWithRetry(payload) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await api('chat.postMessage', payload);
    } catch (e) {
      if (e.code !== 'invalid_blocks' || attempt === 4) throw e;
      await sleep(2000 * attempt);
    }
  }
}

try {
  const newId = a.new && !replyOnly ? await upload(a.new, `After: ${a.title}`) : null;
  const oldId = a.old ? await upload(a.old, `Before: ${a.title}`) : null;
  for (const id of [newId, oldId]) if (id) await waitProcessed(id);

  const { card, thread } = payloads(newId, oldId);
  const posted = replyOnly ? { channel: a.channel, ts: replyOnly } : await postWithRetry(card);
  const { permalink } = await api('chat.getPermalink', { channel: posted.channel, message_ts: posted.ts });
  if (thread) {
    try {
      await postWithRetry({ ...thread, thread_ts: posted.ts });
    } catch (e) {
      console.error(`post: card is up but the thread reply failed: ${e.message}`);
      console.error(`post: re-run with --thread-ts ${posted.ts} to post only the reply`);
      console.log(permalink);
      process.exit(1);
    }
  }
  console.log(permalink);
} catch (e) {
  die(e.message);
}
