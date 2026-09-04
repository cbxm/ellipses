---
name: debugging
description: Use when a bug, failing test, or unexpected behavior needs a root cause before a fix. Four-phase method, backward tracing through the call stack, and a repro-test loop for behavior with no stack trace.
---

# Debugging

Find the root cause before you change anything. A fix that makes the symptom go
away without explaining it is not a fix — it hides the bug somewhere else.

Three rules hold throughout:

- Never fix the symptom. Fix where the bad value or bad decision originates.
- Never ship a workaround in place of an explanation.
- If you cannot find the cause, stop. Write up what you learned — what you
  ruled out, what evidence you have, where the trail went cold — and hand it over.

## The four phases

### 1. Investigate the root cause

Read the error and the whole stack trace, including line numbers and error
codes; they frequently contain the answer outright. Reproduce it reliably — if
you can't trigger it on demand, gather more data rather than guessing. Check
what changed recently: diffs, new dependencies, config, environment.

In a multi-component system (CI → build → sign, API → service → database), don't
guess which layer breaks. Add diagnostic output at each boundary — what data
enters, what exits, whether env and config actually propagated — then run once
and read the evidence to find the failing layer. Only then dig into that layer.

### 2. Pattern analysis

Find working code that resembles the broken code, in this codebase or in the
reference implementation you're following. Read it completely rather than
skimming. List every difference between working and broken, however trivial —
"that can't matter" is usually where the bug is. Understand what the code
depends on: other components, config, environment, unstated assumptions.

### 3. Hypothesis and test

State one hypothesis plainly: "X is the root cause because Y." Test it with the
smallest change that can confirm or refute it, one variable at a time. If it
holds, move on. If it doesn't, form a new hypothesis — don't stack another fix
on top of the failed one. If you don't understand something, say so instead of
proceeding on a guess.

### 4. Implement

Write a failing test that reproduces the bug first — an automated test if the
project has a framework, a one-off script if not. Then make one change that
addresses the root cause. No bundled refactoring or "while I'm here" edits.
Verify the test passes and nothing else broke.

If a fix doesn't work, return to phase 1 with what you just learned. After three
failed fixes, stop fixing and question the design. The signature of an
architectural problem is that each fix reveals a new problem somewhere else, or
demands a large refactor to land. That's not a failed hypothesis, it's the wrong
structure — raise it with your human partner before attempting a fourth fix.

## Tracing backward through the stack

When the error surfaces deep in execution, the place it appears is rarely the
place it comes from. Work backward:

1. What code directly caused the error?
2. What called that, and what value did it pass?
3. Repeat up the chain until you find where the bad value was created.
4. Fix there.

Example: `git init` fails in the source directory. It ran with an empty `cwd`,
which resolves to `process.cwd()`. The empty string came from `WorktreeManager`,
which got it from `Session.create()`, which got it from a test reading
`context.tempDir` before `beforeEach` had set it. The root cause is the
top-level access to an uninitialized value; the fix is a getter that throws when
read too early — not a guard around `git init`. (Defense at intermediate layers
is still worth adding, but it is not the fix.)

When you can't trace by reading, add instrumentation before the dangerous
operation — not after it fails:

```typescript
async function gitInit(directory: string) {
  console.error('DEBUG git init:', {
    directory,
    cwd: process.cwd(),
    stack: new Error().stack,
  });
  await execFileAsync('git', ['init'], { cwd: directory });
}
```

Use `console.error` in tests; a logger may be suppressed. Include directory,
cwd, relevant env vars, and `new Error().stack` for the full call chain. Then
run and filter: `npm test 2>&1 | grep 'DEBUG git init'`. Read the stack traces
for test file names and line numbers, and look for a pattern — same test, same
parameter. If you need to find which test pollutes shared state, bisect by
running test files one at a time until the artifact appears.

## When there is no stack trace

For behavior you can't observe from the inside — a bug that only shows up
through the real interface — build a reproduction and iterate on it.

Write a script that drives the application **from the outside**, through its
real external interface: the CLI binary, an HTTP request against a running
server, the actual UI. Don't call internals, don't use mock mode, don't run it
through a test harness. If it needs credentials, ask for them.

Then loop until the behavior is explained:

1. Add generous logging to the application — every pass through the loop.
2. Run the script.
3. Read the output and the logs, identify what's off.
4. Adjust the script and go again.

Ignore the existing test suite while you're in this loop; it hasn't caught this
bug and running it repeatedly is a way of avoiding the work. If you're stuck,
the answer is almost always more logs. Once the cause is clear, fix it, then
clean up: kill background jobs, remove the scratch logging, and confirm the
rest of the suite still passes.

## When investigation says there's no root cause

Occasionally an issue really is environmental, timing-dependent, or external.
If you've genuinely completed the investigation: document what you looked at,
implement appropriate handling (retry, timeout, a clear error message), and add
logging so the next occurrence is diagnosable. Be suspicious of this conclusion
— most of the time it means the investigation stopped early.
