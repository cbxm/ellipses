// Message building and reply parsing for ask-rob.mjs, kept free of I/O.

export const ROB = 'U0ARUPH3T2M';
export const CADEN = 'U0ARKEKJBLL';
export const DEV = 'C0ASA6TH7QQ';
export const ANSWERERS = { [ROB]: 'Rob', [CADEN]: 'Caden' };

const MAX_BODY = 3000;

// The question as posted: a mention of Rob, who is asking, the body, and how to answer.
export function questionPayload(body, channel = DEV) {
  const question = body.trim();
  if (!question) throw new Error('the draft is empty');
  if (question.length > MAX_BODY) {
    throw new Error(`the draft is ${question.length} chars; keep it under ${MAX_BODY}`);
  }
  const text = [
    `<@${ROB}> Claude here, asking on Caden's behalf.`,
    question,
    '_Reply in thread._',
  ].join('\n\n');
  return { channel, text, unfurl_links: false, unfurl_media: false };
}

// Replies in a conversations.replies message list that answer the question:
// messages from Rob or Caden other than the thread parent. The bot's own
// messages, and anyone else's, are not answers.
export function answersIn(messages, threadTs) {
  return messages
    .filter((m) => m.ts !== threadTs && !m.bot_id && ANSWERERS[m.user])
    .map((m) => ({
      who: ANSWERERS[m.user],
      user: m.user,
      ts: m.ts,
      text: m.text ?? '',
      files: m.files?.length ?? 0,
    }));
}

export function formatAnswers(answers) {
  return answers
    .map((a) => {
      const when = new Date(Number(a.ts) * 1000).toISOString().replace('T', ' ').slice(0, 16);
      const files = a.files ? `\n[${a.files} attachment(s); open the thread to see them]` : '';
      return `--- ${a.who} (${when} UTC, ts ${a.ts})\n${a.text}${files}`;
    })
    .join('\n\n');
}

// "90s", "15m", "4h", or bare seconds -> milliseconds.
export function parseDuration(s) {
  const m = /^(\d+(?:\.\d+)?)([smh]?)$/.exec(String(s).trim());
  if (!m) throw new Error(`bad duration ${JSON.stringify(s)}; use e.g. 90s, 15m, 4h`);
  return Number(m[1]) * { '': 1, s: 1, m: 60, h: 3600 }[m[2]] * 1000;
}

// Polls fetchMessages() until it yields an answer or timeoutMs passes.
// A fetch that throws with .fatal set stops the wait; other errors are
// reported through onError and retried on the next poll.
export async function waitForAnswers(fetchMessages, threadTs, { timeoutMs, intervalMs, sleep, now = Date.now, onError }) {
  const deadline = now() + timeoutMs;
  for (;;) {
    try {
      const answers = answersIn(await fetchMessages(), threadTs);
      if (answers.length) return answers;
    } catch (e) {
      if (e.fatal) throw e;
      onError?.(e);
    }
    const left = deadline - now();
    if (left <= 0) return null;
    await sleep(Math.min(intervalMs, left));
  }
}
