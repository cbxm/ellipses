#!/usr/bin/env node
// Post a devlog card to Slack: header, optional tag, paragraph 1, optional
// table and charts, link buttons, a muted meta line and the NEW image in the
// channel; technical paragraphs and the OLD image in a thread reply (or, with
// --collapse, in a collapsed container on the card).
//
//   post.mjs --title <text> --body <file>
//            [--task <url>] [--mr <url> | --mr !<iid> -R x2u/<repo>] [--deploy <url>]
//            [--author <name>] [--shipped <YYYY-MM-DD | ISO 8601 time>]
//            [--new <png> --new-alt <text>] [--old <png> --old-alt <text>]
//            [--table <tsv file>] [--chart <json file>] [--tag "<text>[:<color>]"]
//            [--collapse] [--channel C0CCSDAS7NG] [--thread-ts <ts>] [--dry-run]
//
// The body is Slack mrkdwn, paragraphs separated by blank lines: the first
// goes on the card, up to two more go in the thread. --table is tab-separated,
// first line the header row. --chart is a data_visualization block (or an
// array of up to two) as JSON. Author and ship date default to the MR's, read
// with glab. --dry-run prints the payloads and posts nothing. A real post
// prints the card's permalink. --thread-ts posts only the thread reply under
// an existing card, for when the card went up but its reply failed.
// A #devlog post needs an x2u --mr. Before posting it looks for a card in
// #devlog that already links that MR (posted from another host, say); if
// there is one it posts nothing and records that card instead. The card's
// {ts, permalink} go to <MR devlog dir>/posted.json, which the sweep reads
// as done.

import { execFileSync } from 'node:child_process';
import { mkdir, readFile, stat, writeFile } from 'node:fs/promises';
import { basename, dirname, join } from 'node:path';
import { parseArgs } from 'node:util';
import { DEVLOG_CHANNEL as DEVLOG, botToken, cardsByMr, devlogDir, mrRef, mrUrl } from './lib.mjs';
const LINKS = [
  ['task', 'See Task'],
  ['mr', 'See MR'],
  ['deploy', 'See Deployment'],
];
const TAG_COLORS = ['gray', 'brown', 'purple', 'indigo', 'blue', 'green', 'yellow', 'orange', 'red'];
const UPLOAD_ALT_MAX = 1000;
const BLOCK_ALT_MAX = 2000;

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
    repo: { type: 'string', short: 'R' },
    deploy: { type: 'string' },
    author: { type: 'string' },
    shipped: { type: 'string' },
    new: { type: 'string' },
    'new-alt': { type: 'string' },
    old: { type: 'string' },
    'old-alt': { type: 'string' },
    table: { type: 'string' },
    chart: { type: 'string' },
    tag: { type: 'string', multiple: true },
    collapse: { type: 'boolean', default: false },
    channel: { type: 'string', default: DEVLOG },
    'thread-ts': { type: 'string' },
    'dry-run': { type: 'boolean', default: false },
  },
  strict: true,
});

if (!a.title) die('--title is required');
if (a.tag?.length > 1) die('--tag given more than once; a card carries at most one tag');
const tag = a.tag?.[0];
if (!a.body) die('--body is required');
if (a.title.length > 150) die(`--title is ${a.title.length} chars; Slack headers allow 150`);

const paragraphs = (await readFile(a.body, 'utf8'))
  .split(/\n\s*\n/)
  .map((p) => p.trim())
  .filter(Boolean);
if (paragraphs.length === 0) die(`${a.body} is empty`);
if (paragraphs.length > 3) die(`${a.body} has ${paragraphs.length} paragraphs; the ceiling is 3`);
const [lead, ...technical] = paragraphs;
for (const p of paragraphs) if (p.length > 3000) die("a paragraph is over Slack's 3000-char section limit");

const mr = a.mr ? mrRef(a.mr, a.repo) : null;
if (a.mr && !mr && !/^https?:\/\//.test(a.mr)) die(`--mr ${a.mr} needs -R x2u/<repo> (one of ai7, salon, admick, gcal), or pass the MR url`);
if (mr) a.mr = mrUrl(mr.repo, mr.iid);
if (a.channel === DEVLOG && !mr) {
  die('a #devlog post needs --mr with an x2u MR (url, or !iid with -R x2u/<repo>); its posted.json is what marks the MR done');
}
const postedFile = mr && join(devlogDir(mr.repo, mr.iid), 'posted.json');

const replyOnly = a['thread-ts'];
if (replyOnly && a.collapse) die('--thread-ts and --collapse conflict: a collapsed card has no thread reply');
if (replyOnly && technical.length === 0 && !a.old) die('--thread-ts given but there is no thread reply to post');
if (a.collapse && technical.length === 0 && !a.old) die('--collapse given but there is nothing to collapse');

for (const key of ['new', 'old']) {
  if (!a[key] || (key === 'new' && replyOnly)) continue;
  const s = await stat(a[key]).catch(() => null);
  if (!s?.isFile()) die(`--${key} ${a[key]} is not a file`);
  if (a[`${key}-alt`] !== undefined && !a[`${key}-alt`].trim()) die(`--${key}-alt is empty`);
  if (!a[`${key}-alt`]) {
    console.error(`post: warning: no --${key}-alt; screen readers get only "${altFallback(key)}"`);
  }
}

function altFallback(key) {
  return `${key === 'new' ? 'After' : 'Before'}: ${a.title}`;
}

function alt(key) {
  return (a[`${key}-alt`] ?? altFallback(key)).trim();
}

// Plain-text rendering of Slack mrkdwn, for the notification/screen-reader
// fallback in the top-level `text` field.
function plain(mrkdwn) {
  return mrkdwn
    .replace(/<!date\^\d+\^[^|>]*\|([^>]*)>/g, '$1')
    .replace(/<([^|>]+)\|([^>]+)>/g, '$2')
    .replace(/<([^>]+)>/g, '$1')
    .replace(/(^|[\s(])[*_~]+(?=\S)|(?<=\S)[*_~]+(?=[\s.,;:!?)]|$)/gm, '$1')
    .replace(/`/g, '');
}

// "<text>:<color>" when the part after the last colon is a tag color;
// otherwise the whole string is the text.
function parseTag(spec) {
  const i = spec.lastIndexOf(':');
  const color = i > 0 ? spec.slice(i + 1).trim() : '';
  if (TAG_COLORS.includes(color)) return { text: spec.slice(0, i).trim(), color };
  return { text: spec.trim() };
}

async function readTable(path) {
  let raw;
  try {
    raw = await readFile(path, 'utf8');
  } catch (e) {
    die(`--table ${path}: ${e.message}`);
  }
  const lines = raw.split('\n').filter((l) => l.trim());
  if (lines.length < 2) die(`--table ${path} needs a header row and at least one data row`);
  if (lines.length > 100) die(`--table has ${lines.length} rows; Slack allows 100`);
  const rows = lines.map((l) => l.split('\t').map((c) => c.trim()));
  const width = rows[0].length;
  if (width < 2) die('--table header has one column; columns are tab-separated');
  if (width > 20) die(`--table has ${width} columns; Slack allows 20`);
  rows.forEach((r, i) => {
    if (r.length !== width) die(`--table row ${i + 1} has ${r.length} cells, the header has ${width}`);
  });
  const chars = rows.flat().reduce((n, c) => n + c.length, 0);
  if (chars > 10000) die(`--table has ${chars} characters of cell text; Slack allows 10000`);
  const cell = (text, bold) =>
    bold
      ? {
          type: 'rich_text',
          elements: [{ type: 'rich_text_section', elements: [{ type: 'text', text, style: { bold: true } }] }],
        }
      : { type: 'raw_text', text: text || '—' };
  return {
    type: 'table',
    column_settings: rows[0].map(() => ({ is_wrapped: true })),
    rows: rows.map((r, i) => r.map((c) => cell(c || '—', i === 0))),
  };
}

async function readCharts(path) {
  let parsed;
  try {
    parsed = JSON.parse(await readFile(path, 'utf8'));
  } catch (e) {
    die(`--chart ${path}: ${e.message}`);
  }
  const charts = Array.isArray(parsed) ? parsed : [parsed];
  if (charts.length === 0) die('--chart file is empty');
  if (charts.length > 2) die(`--chart has ${charts.length} charts; Slack allows 2 per message`);
  return charts.map((c, i) => {
    const where = `--chart[${i}]`;
    const fail = (msg) => die(`${where}: ${msg}`);
    const block = { type: 'data_visualization', ...c };
    if (block.type !== 'data_visualization') fail(`type is "${block.type}"`);
    if (!block.title || block.title.length > 50) fail('title is required, max 50 chars');
    const chart = block.chart;
    if (!chart) fail('chart is required');
    const label20 = (s, what) => {
      if (typeof s !== 'string' || !s || s.length > 20) fail(`${what} "${s}" must be 1-20 chars`);
    };
    if (chart.type === 'pie') {
      const segs = chart.segments ?? [];
      if (segs.length < 1 || segs.length > 12) fail('pie needs 1-12 segments');
      for (const s of segs) {
        label20(s.label, 'segment label');
        if (!(typeof s.value === 'number' && s.value > 0)) fail(`segment "${s.label}" value must be > 0`);
      }
      return block;
    }
    if (!['bar', 'area', 'line'].includes(chart.type)) fail(`chart.type "${chart.type}" is not pie, bar, area or line`);
    const ax = chart.axis_config;
    if (!ax?.categories?.length) fail('axis_config.categories is required');
    if (ax.categories.length > 20) fail('at most 20 categories (points per series)');
    ax.categories.forEach((c) => label20(c, 'category'));
    for (const k of ['x_label', 'y_label']) if (ax[k] && ax[k].length > 50) fail(`${k} is over 50 chars`);
    const series = chart.series ?? [];
    if (series.length < 1 || series.length > 12) fail('needs 1-12 series');
    const names = new Set();
    for (const s of series) {
      label20(s.name, 'series name');
      if (names.has(s.name)) fail(`series name "${s.name}" is repeated`);
      names.add(s.name);
      const labels = (s.data ?? []).map((d) => d.label);
      if (labels.length !== ax.categories.length || ax.categories.some((c) => !labels.includes(c))) {
        fail(`series "${s.name}" needs exactly one point per category`);
      }
      for (const d of s.data) if (typeof d.value !== 'number') fail(`series "${s.name}" point "${d.label}" is not a number`);
    }
    return block;
  });
}

// Repo, MR number, author and ship date for the meta line. glab fills in
// what the flags leave out; without glab or an MR url those parts are omitted.
function mrMeta() {
  const meta = { author: a.author, shipped: a.shipped };
  const m = a.mr && /^https:\/\/[^/]+\/(.+?)\/-\/merge_requests\/(\d+)/.exec(a.mr);
  if (m) {
    meta.repo = m[1].split('/').pop();
    meta.iid = m[2];
    if (!meta.author || !meta.shipped) {
      try {
        const mr = JSON.parse(
          execFileSync('glab', ['api', `projects/${encodeURIComponent(m[1])}/merge_requests/${m[2]}`], {
            encoding: 'utf8',
            stdio: ['ignore', 'pipe', 'pipe'],
          }),
        );
        meta.author ??= mr.author?.name;
        meta.shipped ??= mr.merged_at ?? undefined;
      } catch {
        console.error(`post: warning: could not read ${a.mr} with glab; pass --author and --shipped`);
      }
    }
  } else if (a.mr) {
    console.error('post: warning: --mr is not a GitLab merge request url; repo and MR number omitted');
  }
  if (meta.shipped) {
    // A bare date means local noon, so it renders as that day in any US zone.
    const bare = /^\d{4}-\d{2}-\d{2}$/.test(meta.shipped);
    const iso = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(meta.shipped);
    const t = bare ? Date.parse(`${meta.shipped}T12:00:00`) : iso ? Date.parse(meta.shipped) : NaN;
    if (Number.isNaN(t)) die(`--shipped "${meta.shipped}" is not YYYY-MM-DD or an ISO 8601 time`);
    const d = new Date(t);
    meta.unix = Math.floor(t / 1000);
    meta.fallback = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }
  return meta;
}

function escapeMrkdwn(text) {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function metaLine(meta) {
  const parts = [];
  if (meta.repo) parts.push(`${meta.repo} !${meta.iid}`);
  if (meta.unix) parts.push(`shipped <!date^${meta.unix}^{date_short_pretty}|${meta.fallback}>`);
  if (meta.author) parts.push(`by ${escapeMrkdwn(meta.author)}`);
  // Block Kit has no disabled button, so a missing link is listed as muted text.
  const missing = LINKS.filter(([k]) => !a[k]).map(([, label]) => label.replace(/^See /, ''));
  if (missing.length) parts.push(`${missing.join(', ')}: nothing linked`);
  return parts.join(' · ');
}

function imageBlock(id, key) {
  return {
    type: 'image',
    slack_file: { id },
    title: { type: 'plain_text', text: key === 'new' ? 'After' : 'Before' },
    alt_text: alt(key).slice(0, BLOCK_ALT_MAX),
  };
}

function detailBlocks(oldFileId) {
  const blocks = technical.map((p) => ({ type: 'section', text: { type: 'mrkdwn', text: p } }));
  if (oldFileId) blocks.push(imageBlock(oldFileId, 'old'));
  return blocks;
}

// Each card block is tagged with the flag that produced it, so a rejection
// pointing at /blocks/<n> can name the flag.
function cardBlocks({ newFileId, oldFileId, table, charts, meta }) {
  const out = [];
  const add = (from, block) => out.push({ from, block });
  add('--title', { type: 'header', text: { type: 'plain_text', text: a.title, emoji: true } });
  if (tag) {
    add('--tag', {
      type: 'rich_text',
      elements: [{ type: 'rich_text_section', elements: [{ type: 'tag', ...parseTag(tag) }] }],
    });
  }
  add('--body', { type: 'section', expand: true, text: { type: 'mrkdwn', text: lead } });
  if (table) add('--table', table);
  for (const c of charts ?? []) add('--chart', c);
  const buttons = LINKS.filter(([k]) => a[k]).map(([k, label]) => ({
    type: 'button',
    action_id: `devlog_${k}`,
    text: { type: 'plain_text', text: label },
    url: a[k],
  }));
  if (buttons.length) add('--task/--mr/--deploy', { type: 'actions', elements: buttons });
  const line = metaLine(meta);
  if (line) add('meta line', { type: 'context', elements: [{ type: 'mrkdwn', text: line }] });
  if (newFileId) add('--new', imageBlock(newFileId, 'new'));
  if (a.collapse) {
    add('--collapse', {
      type: 'container',
      title: { type: 'plain_text', text: 'How it works' },
      is_collapsible: true,
      default_collapsed: true,
      child_blocks: detailBlocks(oldFileId),
    });
  }
  return out;
}

function payloads(files, extras) {
  const tagged = cardBlocks({ ...files, ...extras });
  const fallback = [a.title, plain(lead)];
  if (a.collapse) fallback.push(...technical.map(plain));
  const card = {
    channel: a.channel,
    text: fallback.join('\n\n'),
    unfurl_links: false,
    unfurl_media: false,
    blocks: tagged.map((t) => t.block),
  };
  const details = a.collapse ? [] : detailBlocks(files.oldFileId);
  const thread = details.length
    ? {
        channel: a.channel,
        thread_ts: replyOnly ?? '<card ts>',
        text: technical.length ? technical.map(plain).join('\n\n') : alt('old'),
        unfurl_links: false,
        unfurl_media: false,
        blocks: details,
      }
    : null;
  return { card, thread, origins: tagged.map((t) => t.from) };
}

const extras = {
  table: a.table && !replyOnly ? await readTable(a.table) : null,
  charts: a.chart && !replyOnly ? await readCharts(a.chart) : null,
  meta: replyOnly ? {} : mrMeta(),
};

if (a['dry-run']) {
  const files = {
    newFileId: a.new && `<upload of ${a.new}>`,
    oldFileId: a.old && `<upload of ${a.old}>`,
  };
  const { card, thread } = payloads(files, extras);
  console.log(JSON.stringify(replyOnly ? { thread } : { card, thread }, null, 2));
  process.exit(0);
}

const token = await botToken().catch((e) => die(e.message));

class SlackError extends Error {
  constructor(method, code, details) {
    super(`${method}: ${code}${details?.length ? ` ${details.join('; ')}` : ''}`);
    this.code = code;
    this.details = details ?? [];
  }
}

// Marks the MR as posted for the sweep. Written as soon as the card is up,
// so a later failure (permalink, thread reply) never leads to a second card.
async function recordPosted(record) {
  if (!postedFile || a.channel !== DEVLOG) return;
  await mkdir(dirname(postedFile), { recursive: true });
  await writeFile(postedFile, JSON.stringify(record, null, 2) + '\n');
}


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

async function upload(path, key) {
  const bytes = await readFile(path);
  const { upload_url, file_id } = await api('files.getUploadURLExternal', {
    filename: basename(path),
    length: String(bytes.length),
    alt_txt: alt(key).slice(0, UPLOAD_ALT_MAX),
  });
  const res = await fetch(upload_url, { method: 'POST', body: bytes });
  if (!res.ok) throw new Error(`upload of ${path} failed: HTTP ${res.status}`);
  // No channel: the file stays private to the bot and is shown only through
  // the image block that references it.
  await api('files.completeUploadExternal', { files: [{ id: file_id, title: altFallback(key) }] });
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

// The blocks an invalid_blocks error points at, followed through
// child_blocks so an image inside the --collapse container resolves to the
// image. `top` is the index of the enclosing top-level block.
function rejectedBlocks(err, blocks) {
  return [...err.details.join(' ').matchAll(/\/blocks\/\d+(?:\/child_blocks\/\d+)*/g)].map((m) => {
    const [top, ...nested] = [...m[0].matchAll(/\d+/g)].map((n) => Number(n[0]));
    let block = blocks[top];
    for (const i of nested) block = block?.child_blocks?.[i];
    return { top, block, nested: nested.length > 0 };
  });
}

// Retries only rejections that can be a still-processing image; anything else
// is a payload Slack will never accept, reported with the flag behind it.
async function postWithRetry(payload, origins) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await api('chat.postMessage', payload);
    } catch (e) {
      if (e.code !== 'invalid_blocks') throw e;
      const rejected = rejectedBlocks(e, payload.blocks);
      const imageOnly = rejected.length > 0 && rejected.every((r) => r.block?.type === 'image');
      if (!imageOnly || attempt === 4) {
        // The only image nested in a container is OLD under --collapse.
        const blame = (r) => (r.nested && r.block?.type === 'image' ? '--old' : origins?.[r.top]);
        const flags = [...new Set(rejected.map(blame).filter(Boolean))];
        throw new Error(`${e.message}${flags.length ? `\nrejected block(s) come from ${flags.join(', ')}; drop or fix that flag` : ''}`);
      }
      await sleep(2000 * attempt);
    }
  }
}

try {
  if (!replyOnly && a.channel === DEVLOG) {
    const priorTs = (await cardsByMr(token, a.channel)).get(a.mr);
    if (priorTs) {
      const { permalink } = await api('chat.getPermalink', { channel: a.channel, message_ts: priorTs });
      await recordPosted({ permalink, ts: priorTs, found_existing: true });
      console.error(`post: #devlog already has a card for ${a.mr}; posted nothing and recorded it in ${postedFile}`);
      console.log(permalink);
      process.exit(0);
    }
  }

  const newId = a.new && !replyOnly ? await upload(a.new, 'new') : null;
  const oldId = a.old ? await upload(a.old, 'old') : null;
  for (const id of [newId, oldId]) if (id) await waitProcessed(id);

  const { card, thread, origins } = payloads({ newFileId: newId, oldFileId: oldId }, extras);
  const posted = replyOnly ? { channel: a.channel, ts: replyOnly } : await postWithRetry(card, origins);
  if (!replyOnly) {
    console.error(`post: card ts ${posted.ts}`);
    await recordPosted({ ts: posted.ts, ...(thread ? { thread_pending: true } : {}) });
  }
  const { permalink } = await api('chat.getPermalink', { channel: posted.channel, message_ts: posted.ts });
  if (thread) {
    try {
      await postWithRetry({ ...thread, thread_ts: posted.ts });
    } catch (e) {
      console.error(`post: card is up but the thread reply failed: ${e.message}`);
      console.error(`post: re-run with --thread-ts ${posted.ts} to post only the reply`);
      await recordPosted({ permalink, ts: posted.ts, thread_failed: true });
      console.log(permalink);
      process.exit(1);
    }
  }
  await recordPosted({ permalink, ts: posted.ts });
  console.log(permalink);
} catch (e) {
  die(e.message);
}
