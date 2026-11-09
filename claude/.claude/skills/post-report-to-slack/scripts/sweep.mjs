#!/usr/bin/env node
// Devlog sweep: which merged x2u MRs still owe a #devlog post.
//
//   sweep.mjs [--dry-run]
//       Prints JSON {cutoff, pending, needs_screen, waiting, skipped}.
//       Read-only (it reads #devlog history with the bot).
//       pending: merged after CUTOFF, Screens set, deployed to prod, no
//                posted.json, no card in #devlog, fewer than MAX_FAILURES
//                failures. Post these.
//       needs_screen: the same, but the MR has no Screens line; the screen
//                (or a text-only post) has to come from the diff.
//       waiting: either kind, deploy not live yet. Try next sweep.
//       skipped: everything else after the cutoff, with the reason.
//
//   sweep.mjs fail <repo>-<iid> <reason> [--dry-run]
//       Records a failed post in <dir>/failed.md. The MAX_FAILURES-th failure
//       posts one line to #dev with the bot and stops further retries.
//       --dry-run prints what it would write and post, and does neither.
//
// The post itself is post.mjs, which writes <dir>/posted.json.

import { appendFile, mkdir, readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  DEV_CHANNEL,
  REPOS,
  botToken,
  cardsByMr,
  devlogDir,
  glabApi,
  glabList,
  mrUrl,
  parseScreens,
  project,
} from './lib.mjs';

// MRs merged before this are never swept (no backfill).
const CUTOFF = '2026-11-09T00:00:00-07:00';
const MAX_FAILURES = 3;

const { values: opts, positionals } = parseArgs({
  options: { 'dry-run': { type: 'boolean', default: false } },
  allowPositionals: true,
  strict: true,
});

function die(msg) {
  console.error(`sweep: ${msg}`);
  process.exit(1);
}

const exists = (p) => stat(p).then(() => true, () => false);

async function failures(dir) {
  const text = await readFile(join(dir, 'failed.md'), 'utf8').catch(() => '');
  return text.split('\n').filter((l) => l.startsWith('- ')).length;
}

// The commit main built for this MR: the merge or squash commit, or the MR
// head itself for a fast-forward merge (both shas are then null).
const mergedSha = (mr) => mr.merge_commit_sha ?? mr.squash_commit_sha ?? mr.sha;

// Jobs of a pipeline and of its child pipelines (admick deploys from a child).
async function allJobs(repo, pipelineId) {
  const jobs = await glabList(`${project(repo)}/pipelines/${pipelineId}/jobs?include_retried=false`);
  const bridges = await glabList(`${project(repo)}/pipelines/${pipelineId}/bridges`);
  for (const b of bridges) {
    const d = b.downstream_pipeline;
    if (!d) continue;
    const childProject = d.project_id === undefined ? project(repo) : `projects/${d.project_id}`;
    jobs.push(...(await glabList(`${childProject}/pipelines/${d.id}/jobs?include_retried=false`)));
  }
  return jobs;
}

const NOT_RUN = ['created', 'manual', 'skipped', 'scheduled'];
const IN_FLIGHT = ['created', 'waiting_for_resource', 'preparing', 'pending', 'running', 'scheduled'];

// deploy:production succeeded, smoke:production (where the repo has one)
// succeeded, and rollback:production did not run.
function pipelineState(jobs) {
  const job = (name) => jobs.filter((j) => j.name === name).sort((x, y) => y.id - x.id)[0];
  const deploy = job('deploy:production');
  const smoke = job('smoke:production');
  const rollback = job('rollback:production');
  if (rollback && !NOT_RUN.includes(rollback.status)) return { live: false, final: true, why: `rollback:production ${rollback.status}` };
  if (!deploy) return { live: false, final: true, why: 'no deploy:production job' };
  if (deploy.status !== 'success') {
    return { live: false, final: !IN_FLIGHT.includes(deploy.status), why: `deploy:production ${deploy.status}` };
  }
  if (smoke && smoke.status !== 'success') {
    return { live: false, final: !IN_FLIGHT.includes(smoke.status), why: `smoke:production ${smoke.status}` };
  }
  return { live: true };
}

// Whether the MR's merged commit is live in prod. When its own pipeline did
// not deploy (superseded, failed), a later main pipeline that did deploy also
// carries it, since main only moves forward.
async function deployState(repo, mr) {
  const sha = mergedSha(mr);
  const own = await glabApi(`${project(repo)}/pipelines?sha=${sha}&ref=main&per_page=20`);
  if (own.length === 0) return { live: false, why: `no main pipeline for ${sha.slice(0, 8)} yet` };
  const first = own.sort((x, y) => y.id - x.id)[0];
  const state = pipelineState(await allJobs(repo, first.id));
  if (state.live) return { live: true, pipeline: first.web_url };
  if (!state.final) return { live: false, why: state.why, pipeline: first.web_url };

  const later = (await glabApi(`${project(repo)}/pipelines?ref=main&order_by=id&sort=desc&per_page=20`)).filter(
    (p) => p.id > first.id,
  );
  let inFlight;
  for (const p of later) {
    const s = pipelineState(await allJobs(repo, p.id));
    if (s.live) return { live: true, pipeline: p.web_url, via_later_pipeline: true };
    if (!s.final) inFlight ??= { live: false, why: `own pipeline: ${state.why}; later pipeline ${p.id}: ${s.why}`, pipeline: p.web_url };
  }
  return inFlight ?? { live: false, why: state.why, pipeline: first.web_url };
}

async function list() {
  const cutoff = new Date(CUTOFF);
  const out = { cutoff: cutoff.toISOString(), pending: [], needs_screen: [], waiting: [], skipped: [] };
  let cards = new Map();
  try {
    cards = await cardsByMr(await botToken());
  } catch (e) {
    out.warning = `could not read #devlog history (${e.message}); post.mjs still refuses to post a second card`;
  }
  for (const repo of REPOS) {
    const mrs = await glabList(
      `${project(repo)}/merge_requests?state=merged&target_branch=main&updated_after=${encodeURIComponent(cutoff.toISOString())}`,
    );
    for (const mr of mrs) {
      if (!mr.merged_at || new Date(mr.merged_at) < cutoff) continue;
      const dir = devlogDir(repo, mr.iid);
      const base = { repo, iid: mr.iid, url: mrUrl(repo, mr.iid), title: mr.title };
      const screens = parseScreens(mr.description);
      if (screens.state === 'none') {
        out.skipped.push({ ...base, reason: 'Screens: none' });
        continue;
      }
      if (await exists(join(dir, 'posted.json'))) {
        out.skipped.push({ ...base, reason: 'posted' });
        continue;
      }
      if (cards.has(base.url)) {
        out.skipped.push({ ...base, reason: `already in #devlog (ts ${cards.get(base.url)}); post.mjs records it if run` });
        continue;
      }
      const failed = await failures(dir);
      if (failed >= MAX_FAILURES) {
        out.skipped.push({ ...base, reason: `gave up after ${failed} failures (${join(dir, 'failed.md')})` });
        continue;
      }
      const deploy = await deployState(repo, mr);
      const entry = {
        ...base,
        screens: screens.value ?? null,
        dir,
        merged_at: mr.merged_at,
        author: mr.author?.name,
        has_old: await exists(join(dir, 'old-annotated.png')),
        has_recipe: await exists(join(dir, 'recipe.md')),
        failures: failed,
        deploy: deploy.pipeline,
      };
      if (!deploy.live) out.waiting.push({ ...base, dir, reason: deploy.why, deploy: deploy.pipeline });
      else if (screens.state === 'missing') out.needs_screen.push(entry);
      else out.pending.push(entry);
    }
  }
  console.log(JSON.stringify(out, null, 2));
}

async function postToDev(text) {
  const token = await botToken().catch((e) => die(e.message));
  const res = await fetch('https://slack.com/api/chat.postMessage', {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify({ channel: DEV_CHANNEL, text, unfurl_links: false }),
  });
  const json = await res.json();
  if (!json.ok) die(`chat.postMessage to #dev failed: ${json.error}`);
}

async function fail(key, reason) {
  const m = /^([\w-]+?)-(\d+)$/.exec(key ?? '');
  if (!m || !REPOS.includes(m[1])) die(`fail needs <repo>-<iid> with repo one of ${REPOS.join(', ')}`);
  if (!reason) die('fail needs a reason');
  const [, repo, iid] = m;
  const dir = devlogDir(repo, iid);
  const line = `- ${new Date().toISOString()}: ${reason.replace(/\s+/g, ' ').trim()}\n`;
  const count = (await failures(dir)) + 1;
  const giveUp = count === MAX_FAILURES;
  const notice = `Devlog sweep gave up on <${mrUrl(repo, iid)}|${repo} !${iid}> after ${count} failed posts; last: ${reason.replace(/\s+/g, ' ').trim()}. Details in \`${join(dir, 'failed.md')}\`.`;

  if (opts['dry-run']) {
    console.log(JSON.stringify({ append: join(dir, 'failed.md'), line: line.trim(), failures: count, post_to_dev: giveUp ? notice : null }, null, 2));
    return;
  }
  await mkdir(dir, { recursive: true });
  await appendFile(join(dir, 'failed.md'), line);
  if (giveUp) await postToDev(notice);
  console.log(JSON.stringify({ failures: count, gave_up: count >= MAX_FAILURES, posted_to_dev: giveUp }));
}

const [cmd, ...rest] = positionals;
if (!cmd) await list();
else if (cmd === 'fail') await fail(rest[0], rest.slice(1).join(' '));
else die(`unknown command ${cmd}`);
