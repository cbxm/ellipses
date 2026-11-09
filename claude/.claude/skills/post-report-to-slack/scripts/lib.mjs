// Shared by hook-gate.mjs, sweep.mjs and post.mjs.

import { execFile } from 'node:child_process';
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
// `https://gitlab.com/x2u/ai7`, `git@gitlab.com:x2u/ai7.git`. Null otherwise.
export function x2uRepo(ref) {
  const m = /(?:^|[/:])x2u\/([\w.-]+?)(?:\.git)?(?:\/|$)/.exec(ref ?? '');
  return m && REPOS.includes(m[1]) ? m[1] : null;
}

export function mrUrl(repo, iid) {
  return `https://gitlab.com/${GROUP}/${repo}/-/merge_requests/${iid}`;
}

// The `Screens:` value of an MR description. The value is the rest of the
// line, or, when that is empty, the lines after it up to the next blank line.
//   { state: 'missing' }            no Screens line
//   { state: 'none', value }        Screens: none
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
  return { state: /^[`*_]*none\b/i.test(value) ? 'none' : 'set', value };
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
