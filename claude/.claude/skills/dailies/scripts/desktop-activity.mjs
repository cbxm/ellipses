#!/usr/bin/env node
// Condense synced desktop Claude Code sessions into what was asked and what was
// reported back, for the dailies skill. Tool calls, tool output, and thinking are
// dropped; only human prompts, assistant prose, session titles, and PR/MR links
// remain.
//
//   desktop-activity.mjs --since 2026-11-02T00:00:00-07:00 [--dir ~/desktop-sessions]
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => (a.startsWith("--") ? [...acc, [a.slice(2), all[i + 1]]] : acc), []),
);
const since = new Date(args.since ?? new Date().toISOString().slice(0, 10));
const dir = args.dir ?? join(homedir(), "desktop-sessions");
const USER_MAX = 400;
const ASSISTANT_MAX = 700;

function clip(text, max) {
  const flat = text.replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, "").replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max)}…` : flat;
}

function* sessionFiles(root) {
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    const path = join(root, entry.name);
    if (entry.isDirectory()) yield* sessionFiles(path);
    else if (entry.name.endsWith(".jsonl") && statSync(path).mtime >= since) yield path;
  }
}

let any = false;
for (const file of sessionFiles(dir)) {
  let title = null;
  const lines = [];
  const links = new Set();
  for (const raw of readFileSync(file, "utf8").split("\n")) {
    if (!raw) continue;
    let e;
    try { e = JSON.parse(raw); } catch { continue; }
    if (e.type === "ai-title") title = e.aiTitle ?? title;
    if (e.type === "pr-link" && e.prUrl && (!e.timestamp || new Date(e.timestamp) >= since)) links.add(e.prUrl);
    if (!e.timestamp || new Date(e.timestamp) < since || e.isSidechain || e.isMeta) continue;
    const time = new Date(e.timestamp).toLocaleTimeString("en-US", { timeZone: "America/Denver", hour: "2-digit", minute: "2-digit", hour12: false });
    if (e.type === "user" && typeof e.message?.content === "string") {
      const text = clip(e.message.content, USER_MAX);
      if (text && !text.startsWith("<")) lines.push(`${time} USER: ${text}`);
    } else if (e.type === "assistant" && Array.isArray(e.message?.content)) {
      for (const block of e.message.content) {
        if (block.type === "text" && block.text.trim()) lines.push(`${time} CLAUDE: ${clip(block.text, ASSISTANT_MAX)}`);
      }
    }
  }
  if (!lines.length) continue;
  any = true;
  console.log(`\n=== ${title ?? "untitled"} (${file.split("/").at(-2)})`);
  if (links.size) console.log(`links: ${[...links].join(" ")}`);
  console.log(lines.join("\n"));
}
if (!any) console.log(`no desktop session activity since ${since.toISOString()} in ${dir}`);
