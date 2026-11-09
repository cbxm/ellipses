// Shared by hook-gate.mjs, sweep.mjs and post.mjs.

import { execFile } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { promisify } from 'node:util';

export const GROUP = 'x2u';
export const REPOS = ['ai7', 'salon', 'admick', 'gcal'];
export const DEVLOG_CHANNEL = 'C0CCSDAS7NG';
export const DEV_CHANNEL = 'C0ASA6TH7QQ';
export const TOKEN_FILE = join(homedir(), '.config/x2u-devlog/bot-token');

const DEVLOG_ROOT = process.env.DEVLOG_ROOT || join(homedir(), 'src/x2u/.work/devlog');

export function devlogDir(repo, iid) {
  return join(DEVLOG_ROOT, `${repo}-${iid}`);
}

// The x2u repo named by a remote, -R value or MR url: `x2u/ai7`,
// `https://gitlab.com/x2u/ai7`, `git@gitlab.com:x2u/ai7.git`. Null otherwise,
// and null for a repo outside REPOS unless `any` is set.
export function x2uRepo(ref, { any = false } = {}) {
  const m = /(?:^|[/:])x2u\/([\w.-]+?)(?:\.git)?(?:\/|$)/.exec(ref ?? '');
  return m && (any || REPOS.includes(m[1])) ? m[1] : null;
}

// {repo, iid} from an x2u MR url, or from `!iid` / `iid` plus a repo ref.
export function mrRef(mr, repoRef, opts) {
  const url = /^https?:\/\/[^/]+\/(.+?)\/-\/merge_requests\/(\d+)/.exec(mr ?? '');
  if (url) return x2uRepo(url[1], opts) ? { repo: x2uRepo(url[1], opts), iid: url[2] } : null;
  const n = /^!?(\d+)$/.exec(mr ?? '');
  const repo = repoRef && x2uRepo(repoRef, opts);
  return n && repo ? { repo, iid: n[1] } : null;
}

export function mrUrl(repo, iid) {
  return `https://gitlab.com/${GROUP}/${repo}/-/merge_requests/${iid}`;
}

const NONE = /^[`*_]*(none|n\/a|no user[- ]visible changes?)(?![\w/])/i;

// The `Screens:` value of an MR description. The value is the rest of the
// line, or, when that is empty, the lines after it up to the next blank line.
//   { state: 'missing' }            no Screens line
//   { state: 'none', value }        Screens: none (or n/a, no user-visible change)
//   { state: 'set', value }         anything else
export function parseScreens(description) {
  const lines = (description ?? '').split(/\r?\n/);
  const i = lines.findIndex((l) => /^[\s>*_-]*Screens[*_]*\s*:/i.test(l));
  if (i < 0) return { state: 'missing' };
  let value = lines[i].replace(/^[\s>*_-]*Screens[*_]*\s*:[*_]*\s*/i, '').trim();
  if (!value) {
    const rest = [];
    for (const l of lines.slice(i + 1)) {
      if (!l.trim()) {
        if (rest.length) break;
        continue;
      }
      rest.push(l.trim());
    }
    value = rest.join('\n');
  }
  if (!value) return { state: 'missing' };
  return { state: NONE.test(value) ? 'none' : 'set', value };
}

const run = promisify(execFile);

export async function glabApi(path, { timeout = 30000 } = {}) {
  const { stdout } = await run('glab', ['api', path], { timeout, maxBuffer: 64 * 1024 * 1024 });
  return JSON.parse(stdout);
}

// Every page of a list endpoint.
export async function glabList(path) {
  const all = [];
  for (let page = 1; ; page++) {
    const rows = await glabApi(`${path}${path.includes('?') ? '&' : '?'}per_page=100&page=${page}`);
    all.push(...rows);
    if (rows.length < 100) return all;
  }
}

export function project(repo) {
  return `projects/${encodeURIComponent(`${GROUP}/${repo}`)}`;
}

export async function botToken() {
  let token;
  try {
    token = (await readFile(TOKEN_FILE, 'utf8')).trim();
  } catch {
    throw new Error(`${TOKEN_FILE} is missing; paste the bot's xoxb- token into it (chmod 600)`);
  }
  if (!token.startsWith('xoxb-')) throw new Error(`${TOKEN_FILE} does not hold a bot (xoxb-) token`);
  return token;
}

// MR url -> ts of the newest card in the channel whose buttons link that MR,
// over the channel's last 1000 messages.
export async function cardsByMr(token, channel = DEVLOG_CHANNEL) {
  const cards = new Map();
  let cursor;
  for (let page = 0; page < 5; page++) {
    const body = new URLSearchParams({ channel, limit: '200', ...(cursor ? { cursor } : {}) });
    const res = await fetch('https://slack.com/api/conversations.history', {
      method: 'POST',
      headers: { authorization: `Bearer ${token}` },
      body,
    });
    const json = await res.json();
    if (!json.ok) throw new Error(`conversations.history: ${json.error}`);
    for (const m of json.messages) {
      for (const b of m.blocks ?? []) {
        if (b.type !== 'actions') continue;
        for (const e of b.elements ?? []) {
          if (/\/-\/merge_requests\/\d+$/.test(e.url ?? '') && !cards.has(e.url)) cards.set(e.url, m.ts);
        }
      }
    }
    cursor = json.response_metadata?.next_cursor;
    if (!json.has_more || !cursor) break;
  }
  return cards;
}
