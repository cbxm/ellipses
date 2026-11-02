#!/usr/bin/env node
// Screenshot a prod x2u page as the test account, with element boxes measured
// in the same viewport state as the screenshot.
//
//   capture.mjs --url /ai7/... [--viewport 800x900] [--dpr 2]
//               [--click <sel>]... [--wait <sel>]...   (run in the order given)
//               [--parent <sel>] [--target <sel>] [--out shot.png] [--aria]
//
// Selectors are Playwright locator strings: CSS, `role=tab[name="Settings"]`,
// `text=Save`. --aria prints an aria snapshot (of --parent, else the page).
// The last stdout line is {url, viewport, dpr, parentBox, targetBox} as JSON;
// with --out the same JSON is written to <out>.boxes.json for `annotate`.
// A --url under /auth/login is shown signed out, without signing in.

import { chromium } from 'playwright';
import { readFile, writeFile, mkdir, stat, chmod } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { parseArgs } from 'node:util';

const ORIGIN = 'https://app.x2u.ai';
const CREDS = join(homedir(), '.config/x2u-devlog/prod-test-account.json');
const STATE = join(homedir(), '.cache/x2u-devlog/state.json');

function die(msg) {
  console.error(`capture: ${msg}`);
  process.exit(1);
}

const steps = [];
const { values: a } = parseArgs({
  options: {
    url: { type: 'string' },
    viewport: { type: 'string', default: '800x900' },
    dpr: { type: 'string', default: '2' },
    click: { type: 'string', multiple: true },
    wait: { type: 'string', multiple: true },
    parent: { type: 'string' },
    target: { type: 'string' },
    out: { type: 'string' },
    aria: { type: 'boolean', default: false },
    timeout: { type: 'string', default: '15000' },
  },
  strict: true,
});
// parseArgs groups repeated options; recover the interleaved click/wait order.
for (let i = 2; i < process.argv.length; i++) {
  const flag = process.argv[i].split('=')[0];
  if (flag === '--click' || flag === '--wait') {
    const val = process.argv[i].includes('=') ? process.argv[i].slice(flag.length + 1) : process.argv[++i];
    steps.push([flag.slice(2), val]);
  }
}

if (!a.url) die('--url is required');
if (!a.out && !a.aria) die('nothing to do: pass --out and/or --aria');
const m = /^(\d+)x(\d+)$/.exec(a.viewport);
if (!m) die(`bad --viewport ${a.viewport}, want WIDTHxHEIGHT`);
const viewport = { width: +m[1], height: +m[2] };
const dpr = Number(a.dpr);
const timeout = Number(a.timeout);
const url = new URL(a.url, ORIGIN).href;

const isLogin = (u) => new URL(u).pathname.startsWith('/auth/login');

async function exists(p) {
  return stat(p).then(() => true, () => false);
}

async function readCreds() {
  let raw;
  try {
    raw = await readFile(CREDS, 'utf8');
  } catch {
    die(
      `prod sign-in needed but ${CREDS} is missing.\n` +
        `Create it (chmod 600) with the prod test account:\n` +
        `  {"email": "...", "password": "..."}`,
    );
  }
  const { mode } = await stat(CREDS);
  if (mode & 0o077) console.error(`capture: warning: ${CREDS} is readable by others; chmod 600 it`);
  let c;
  try {
    c = JSON.parse(raw);
  } catch {
    die(`${CREDS} is not valid JSON`);
  }
  if (!c.email || !c.password) die(`${CREDS} needs "email" and "password"`);
  return c;
}

async function signIn(page, context) {
  const { email, password } = await readCreds();
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.locator('form#f button[type=submit]').click();
  try {
    await page.waitForURL((u) => !isLogin(u.href), { timeout });
  } catch {
    const alert = (await page.getByRole('alert').textContent().catch(() => ''))?.trim();
    die(`sign-in did not leave /auth/login${alert ? `: ${alert}` : ''}`);
  }
  await mkdir(dirname(STATE), { recursive: true, mode: 0o700 });
  await context.storageState({ path: STATE });
  await chmod(STATE, 0o600);
}

async function settle(page) {
  await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
}

async function box(page, sel, name) {
  const loc = page.locator(sel);
  const n = await loc.count();
  if (n === 0) die(`--${name} ${sel} matched nothing`);
  if (n > 1) console.error(`capture: warning: --${name} ${sel} matched ${n} elements; using the first`);
  const b = await loc.first().boundingBox();
  if (!b) die(`--${name} ${sel} is not visible`);
  const out = { x: b.x, y: b.y, width: b.width, height: b.height };
  if (b.x < 0 || b.y < 0 || b.x + b.width > viewport.width || b.y + b.height > viewport.height) {
    console.error(`capture: warning: --${name} box ${JSON.stringify(out)} runs outside the ${a.viewport} viewport; try a taller --viewport`);
  }
  return out;
}

const browser = await chromium.launch();
try {
  const context = await browser.newContext({
    viewport,
    deviceScaleFactor: dpr,
    storageState: (await exists(STATE)) ? STATE : undefined,
  });
  context.setDefaultTimeout(timeout);
  const page = await context.newPage();

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  const wantLogin = isLogin(url);
  if (isLogin(page.url()) && !wantLogin) {
    await signIn(page, context);
    if (page.url() !== url) await page.goto(url, { waitUntil: 'domcontentloaded' });
  }
  if (isLogin(page.url()) && !wantLogin) die('still on /auth/login after signing in');
  await settle(page);

  for (const [kind, sel] of steps) {
    if (kind === 'click') {
      await page.locator(sel).first().click();
      await settle(page);
    } else {
      await page.locator(sel).first().waitFor({ state: 'visible' });
    }
  }

  if (a.parent) await page.locator(a.parent).first().scrollIntoViewIfNeeded();
  const result = {
    url: page.url(),
    viewport,
    dpr,
    parentBox: a.parent ? await box(page, a.parent, 'parent') : null,
    targetBox: a.target ? await box(page, a.target, 'target') : null,
  };

  if (a.aria) {
    const root = a.parent ? page.locator(a.parent).first() : page.locator('body');
    console.log(await root.ariaSnapshot());
  }
  if (a.out) {
    await page.screenshot({ path: a.out });
    await writeFile(`${a.out}.boxes.json`, JSON.stringify(result, null, 2) + '\n');
  }
  console.log(JSON.stringify(result));
} finally {
  await browser.close();
}
