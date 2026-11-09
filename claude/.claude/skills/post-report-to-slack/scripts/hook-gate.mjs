#!/usr/bin/env node
// Devlog gates for x2u MRs, run from hook-gate.sh on PreToolUse(Bash).
//
// `glab mr create` must carry a `Screens:` line in its description.
// `glab mr merge` of an MR whose Screens is not `none` needs
// <devlog dir>/old.png first, because prod serves OLD only until the merge.
//
// A `DEVLOG_SKIP=1` assignment before the glab call (or in the environment)
// waives both. Anything this script cannot work out is allowed with a warning.

import { execFile } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { promisify } from 'node:util';
import { devlogDir, glabApi, mrUrl, parseScreens, project, x2uRepo } from './lib.mjs';

const run = promisify(execFile);
const SCREENS_HINT = '`Screens: <https://app.x2u.ai/... url> — <element that shows the change>` or `Screens: none`';

function emit(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
  process.exit(0);
}

function deny(reason) {
  emit({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason } });
}

function warn(msg) {
  const text = `devlog gate could not check this command (${msg}); allowed. Check the devlog step by hand.`;
  process.stderr.write(`hook-gate: ${text}\n`);
  emit({ systemMessage: text, hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: text } });
}

// Splits a shell command into words and control operators. Quotes, `$(...)`
// and heredoc bodies stay inside the word they belong to (raw, quotes kept),
// which is enough to find glab calls and read their arguments.
function tokenize(src) {
  const out = [];
  let i = 0;
  let word = '';
  let heredocs = [];
  const flush = () => {
    if (word) out.push({ word });
    word = '';
  };

  function readHeredocMarker() {
    const m = /^<<(-?)\s*(['"]?)([\w.-]+)\2/.exec(src.slice(i));
    if (!m) return false;
    heredocs.push({ tag: m[3], strip: m[1] === '-' });
    word += m[0];
    i += m[0].length;
    return true;
  }

  function readHeredocBodies() {
    for (const { tag, strip } of heredocs) {
      while (i < src.length) {
        const nl = src.indexOf('\n', i);
        const end = nl < 0 ? src.length : nl;
        const line = src.slice(i, end);
        word += line + '\n';
        i = end + 1;
        if ((strip ? line.replace(/^\t+/, '') : line) === tag) break;
      }
    }
    heredocs = [];
  }

  // Raw text up to the `)` closing a `$(` that starts at i.
  function readSubst() {
    let depth = 0;
    const start = i;
    const saved = heredocs;
    heredocs = [];
    while (i < src.length) {
      const c = src[i];
      if (c === "'") {
        const j = src.indexOf("'", i + 1);
        i = j < 0 ? src.length : j + 1;
      } else if (c === '"') {
        i++;
        while (i < src.length && src[i] !== '"') i += src[i] === '\\' ? 2 : 1;
        i++;
      } else if (c === '\\') {
        i += 2;
      } else if (src.startsWith('<<', i) && !src.startsWith('<<<', i)) {
        const before = word;
        word = '';
        if (!readHeredocMarker()) i += 2;
        word = before;
      } else if (c === '\n' && heredocs.length) {
        i++;
        const before = word;
        word = '';
        readHeredocBodies();
        word = before;
      } else if (c === '(') {
        depth++;
        i++;
      } else if (c === ')') {
        depth--;
        i++;
        if (depth === 0) break;
      } else {
        i++;
      }
    }
    heredocs = saved;
    return src.slice(start, i);
  }

  while (i < src.length) {
    const c = src[i];
    if (c === "'") {
      const j = src.indexOf("'", i + 1);
      const end = j < 0 ? src.length : j + 1;
      word += src.slice(i, end);
      i = end;
    } else if (c === '"') {
      let j = i + 1;
      let raw = '"';
      while (j < src.length && src[j] !== '"') {
        if (src[j] === '\\') {
          raw += src.slice(j, j + 2);
          j += 2;
        } else if (src.startsWith('$(', j)) {
          const save = i;
          i = j + 1;
          raw += '$' + readSubst();
          j = i;
          i = save;
        } else {
          raw += src[j++];
        }
      }
      word += raw + '"';
      i = j + 1;
    } else if (c === '\\') {
      word += src.slice(i, i + 2);
      i += 2;
    } else if (src.startsWith('$(', i)) {
      i++;
      word += '$' + readSubst();
    } else if (src.startsWith('<<', i) && !src.startsWith('<<<', i)) {
      flush();
      if (!readHeredocMarker()) {
        word += '<<';
        i += 2;
      }
      flush();
    } else if (c === '\n') {
      flush();
      i++;
      if (heredocs.length) {
        readHeredocBodies();
        flush();
      }
      out.push({ op: ';' });
    } else if (/\s/.test(c)) {
      flush();
      i++;
    } else if (/[;&|()]/.test(c)) {
      flush();
      const op = /^(&&|\|\||;;|[;&|()])/.exec(src.slice(i))[0];
      out.push({ op });
      i += op.length;
    } else if (c === '#' && !word) {
      const nl = src.indexOf('\n', i);
      i = nl < 0 ? src.length : nl;
    } else {
      word += c;
      i++;
    }
  }
  flush();
  return out;
}

// Removes one layer of quoting from a word whose value is plain text.
function unquote(w) {
  if (/^'.*'$/s.test(w)) return w.slice(1, -1);
  if (/^".*"$/s.test(w)) return w.slice(1, -1).replace(/\\(["\\$`])/g, '$1');
  return w.replace(/\\(.)/g, '$1');
}

function expandHome(p) {
  return p === '~' ? homedir() : p.startsWith('~/') ? join(homedir(), p.slice(2)) : p;
}

// Commands as word lists, each with the directory it runs in and whether a
// DEVLOG_SKIP=1 assignment came before it.
function commands(src, cwd) {
  const cmds = [];
  let dir = cwd;
  let skip = process.env.DEVLOG_SKIP === '1';
  let cur = [];
  const end = () => {
    if (cur.length) {
      if (cur[0] === 'cd' && cur[1]) dir = resolve(dir, expandHome(unquote(cur[1])));
      if (cur.some((w) => /^DEVLOG_SKIP=['"]?1['"]?$/.test(w))) skip = true;
      cmds.push({ words: cur, dir, skip });
    }
    cur = [];
  };
  for (const t of tokenize(src)) {
    if (t.op) end();
    else cur.push(t.word);
  }
  end();
  return cmds;
}

// Splits `glab [globals] mr <sub> args...`. Null if it is not that.
function glabMr(words) {
  let k = 0;
  while (k < words.length && (/^\w+=/.test(words[k]) || ['env', 'command', 'exec'].includes(words[k]))) k++;
  if (!/(^|\/)glab$/.test(words[k] ?? '')) return null;
  if (words[k + 1] !== 'mr') return null;
  const sub = { new: 'create', accept: 'merge' }[words[k + 2]] ?? words[k + 2];
  if (sub !== 'create' && sub !== 'merge') return null;
  return { sub, args: words.slice(k + 3) };
}

const VALUE_FLAGS = {
  create: ['-a', '--assignee', '--attach', '-d', '--description', '--description-file', '-H', '--head', '-l', '--label', '-m', '--milestone', '-i', '--related-issue', '-R', '--repo', '--reviewer', '-s', '--source-branch', '-b', '--target-branch', '--template', '-t', '--title'],
  merge: ['-m', '--message', '-R', '--repo', '--sha', '--squash-message'],
};

function parseArgs(sub, args) {
  const flags = {};
  const positional = [];
  for (let k = 0; k < args.length; k++) {
    const a = args[k];
    if (a === '--') {
      positional.push(...args.slice(k + 1));
      break;
    }
    const eq = /^(--[\w-]+)=(.*)$/s.exec(a);
    if (eq) flags[eq[1]] = eq[2];
    else if (VALUE_FLAGS[sub].includes(a)) flags[a] = args[++k] ?? '';
    else if (a.startsWith('-')) flags[a] = true;
    else positional.push(a);
  }
  const get = (...names) => names.map((n) => flags[n]).find((v) => v !== undefined);
  return { get, positional };
}

async function originRepo(dir) {
  try {
    const { stdout } = await run('git', ['-C', dir, 'remote', 'get-url', 'origin'], { timeout: 5000 });
    return x2uRepo(stdout.trim());
  } catch {
    return null;
  }
}

async function repoFor(get, dir) {
  const r = get('-R', '--repo');
  if (r !== undefined) return x2uRepo(unquote(r));
  return originRepo(dir);
}

async function checkCreate({ args, dir }) {
  const { get } = parseArgs('create', args);
  const repo = await repoFor(get, dir);
  if (!repo) return;

  let text;
  const file = get('--description-file');
  const desc = get('-d', '--description');
  if (typeof file === 'string' && file !== '-') {
    try {
      text = readFileSync(resolve(dir, expandHome(unquote(file))), 'utf8');
    } catch (e) {
      return warn(`cannot read --description-file ${file}: ${e.code ?? e.message}`);
    }
  } else if (typeof desc === 'string' && desc !== '-') {
    text = unquote(desc);
  }
  if (text === undefined) {
    return deny(`x2u/${repo} MR needs a description with a Screens line: pass --description containing ${SCREENS_HINT}. (--fill, --template and the editor are not checked, so write the description explicitly.)`);
  }
  const screens = parseScreens(text);
  if (screens.state === 'missing') {
    return deny(`x2u/${repo} MR description has no Screens line. Add ${SCREENS_HINT} on its own line, written from the diff.`);
  }
  const auto = get('--auto-merge');
  if (screens.state === 'set' && auto !== undefined && auto !== 'false') {
    return deny(`x2u/${repo} MR has Screens set, and --auto-merge would merge it before /post-report-to-slack old captures the OLD screen. Create it without --auto-merge, run old, then merge.`);
  }
}

async function checkMerge({ args, dir }) {
  const { get, positional } = parseArgs('merge', args);
  const target = positional[0] ? unquote(positional[0]) : undefined;

  let repo;
  let iid;
  const url = target && /^https?:\/\/[^/]+\/(.+?)\/-\/merge_requests\/(\d+)/.exec(target);
  if (url) {
    repo = x2uRepo(url[1]);
    iid = url[2];
  } else {
    repo = await repoFor(get, dir);
    const n = target && /^!?(\d+)$/.exec(target);
    if (n) iid = n[1];
  }
  if (!repo) return;

  let mr;
  try {
    if (iid) {
      mr = await glabApi(`${project(repo)}/merge_requests/${iid}`, { timeout: 15000 });
    } else {
      const viewArgs = ['mr', 'view', ...(target ? [target] : []), '-R', `x2u/${repo}`, '-F', 'json'];
      const { stdout } = await run('glab', viewArgs, { cwd: dir, timeout: 15000 });
      mr = JSON.parse(stdout);
    }
  } catch (e) {
    return warn(`glab could not read the MR${iid ? ` !${iid}` : ''} in x2u/${repo}: ${(e.stderr || e.message || '').toString().replace(/\s+/g, ' ').trim().slice(0, 200)}`);
  }
  iid = mr.iid;

  const screens = parseScreens(mr.description);
  if (screens.state === 'none') return;
  if (screens.state === 'missing') {
    return deny(`x2u/${repo} !${iid} has no Screens line. Add ${SCREENS_HINT} to its description (glab mr update ${iid} -R x2u/${repo} --description ...), then merge; if Screens is not none, run /post-report-to-slack old !${iid} first.`);
  }
  const dirPath = devlogDir(repo, iid);
  if (existsSync(join(dirPath, 'old.png'))) return;
  deny(`x2u/${repo} !${iid} has Screens set but ${dirPath}/old.png is missing. Run \`/post-report-to-slack old ${mrUrl(repo, iid)}\` first: prod still serves OLD only until this merge. If the user waived the devlog for this MR, prefix the merge with DEVLOG_SKIP=1.`);
}

let input;
try {
  input = JSON.parse(readFileSync(0, 'utf8'));
} catch {
  process.exit(0);
}
const src = input?.tool_input?.command;
if (typeof src !== 'string') process.exit(0);

try {
  for (const cmd of commands(src, input.cwd || process.cwd())) {
    const g = glabMr(cmd.words);
    if (!g || cmd.skip) continue;
    const ctx = { args: g.args, dir: cmd.dir };
    if (g.sub === 'create') await checkCreate(ctx);
    else await checkMerge(ctx);
  }
} catch (e) {
  warn(e.message);
}
process.exit(0);
