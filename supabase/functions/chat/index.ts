// WorkNest AI HR assistant — Supabase Edge Function
//
// The mobile app calls this with the signed-in user's session token
// (supabase.functions.invoke('chat')). The Groq API key is stored as a
// Supabase secret and never leaves the server, so it can't be extracted
// from the APK.
//
// Deploy:
//   supabase secrets set GROQ_API_KEY=gsk_...   --project-ref <ref>
//   supabase functions deploy chat              --project-ref <ref>

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const ANSWER_MODEL = "openai/gpt-oss-120b";
const KEYWORD_MODEL = "openai/gpt-oss-20b";

// Groq's free tier allows ~8,000 tokens per minute per model, so each request
// must stay well under that (policy excerpts + history + reply budget).
const MAX_CONTEXT_CHARS = 6000; // ≈ 1.8k tokens of policy excerpts
const MAX_HISTORY_MESSAGES = 6;
const MAX_MESSAGE_CHARS = 2000;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// ┌──────────────────────────────────────────────────────────────────────────┐
// │ GROQ API KEY                                                             │
// │ Either paste your key in place of the placeholder — ONLY in the Supabase │
// │ dashboard code editor, never in a file committed to GitHub (Groq         │
// │ automatically revokes keys that appear in public repos) — or set a       │
// │ Supabase secret named GROQ_API_KEY. A pasted key takes priority.         │
// └──────────────────────────────────────────────────────────────────────────┘
const GROQ_KEY_PLACEHOLDER = "gsk_PASTE_YOUR_GROQ_API_KEY_HERE";
const GROQ_API_KEY = (GROQ_KEY_PLACEHOLDER.includes("PASTE_YOUR")
  ? Deno.env.get("GROQ_API_KEY") ?? ""
  : GROQ_KEY_PLACEHOLDER).trim();

const BASE_SYSTEM_PROMPT =
  "You are an HR assistant for WorkNest, a Malaysian HR system. " +
  "Be concise and helpful. Reply in English only. " +
  "Base every factual answer strictly on the COMPANY POLICY DOCUMENT EXCERPTS provided " +
  "below, when present — they are this company's actual policy and always take priority " +
  "over any general assumption you might otherwise make about typical Malaysian HR rules " +
  "(leave entitlements, EPF/SOCSO/EIS rates, claim amounts, etc. vary by company). " +
  "If the excerpts do not contain the answer, say so explicitly and advise the employee " +
  "to check with HR directly — do not guess or invent a number or policy detail.";

const KEYWORD_PROMPT =
  "You extract search keywords for an HR policy document written in Bahasa Melayu. " +
  "Given an employee question in any language, reply with ONLY a comma-separated list " +
  "of 6-12 short keywords: the key terms in English AND their Bahasa Melayu equivalents, " +
  "including common synonyms. No explanations.";

const STOP_WORDS = new Set([
  "what", "the", "how", "many", "can", "for", "and", "does", "are", "was", "will",
  "about", "this", "that", "with", "have", "has", "ada", "yang", "dan", "dari",
  "untuk", "pada", "ini", "itu", "tidak", "boleh", "dengan", "policy", "dasar", "polisi",
]);

type Chunk = { content: string; page: number | null };
type HistoryItem = { role: string; text: string };

// Needed when the app runs in a browser (Flutter web). Any origin is fine because
// access is controlled by the user's bearer token, not by cookies.
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS_HEADERS });
  if (req.method !== "POST") return json({ ok: false, reply: "Method not allowed." }, 405);

  // Only signed-in users. (The gateway's JWT check alone would also accept the
  // public anon key, so confirm the token belongs to a real user.)
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!(await isSignedInUser(authHeader))) {
    return json({ ok: false, reply: "Your session has expired. Please log in again." }, 401);
  }

  let message = "";
  let history: HistoryItem[] = [];
  try {
    const body = await req.json();
    message = String(body.message ?? "").trim();
    history = Array.isArray(body.history) ? body.history : [];
  } catch {
    return json({ ok: false, reply: "Invalid request." }, 400);
  }
  if (!message || message.length > MAX_MESSAGE_CHARS) {
    return json({ ok: false, reply: `Message must be 1–${MAX_MESSAGE_CHARS} characters.` }, 400);
  }
  if (!GROQ_API_KEY) return json({ ok: false, reply: "AI assistant is not configured." });

  try {
    // 1. Relevant policy excerpts (best-effort)
    let policyContext = "";
    try {
      policyContext = await loadRelevantChunks(message);
    } catch { /* non-fatal */ }

    // 2. System prompt
    const systemPrompt = policyContext
      ? `${BASE_SYSTEM_PROMPT}

=== COMPANY POLICY DOCUMENT EXCERPTS ===
Each excerpt below is labeled with its source page number. When your answer
relies on one of these excerpts, mention the page it came from
(e.g. "see page 5 of the policy document"). Only cite a page when the
excerpt actually informed your answer — do not invent page numbers.

${policyContext}
=== END OF POLICY DOCUMENT EXCERPTS ===
`
      : BASE_SYSTEM_PROMPT;

    // 3. Messages — only the most recent turns, to stay inside the token limit
    const messages = [
      { role: "system", content: systemPrompt },
      ...history.slice(-MAX_HISTORY_MESSAGES).map((m) => ({
        role: m.role === "model" ? "assistant" : m.role === "assistant" ? "assistant" : "user",
        content: String(m.text ?? ""),
      })),
      { role: "user", content: message },
    ];

    // 4. Call Groq — on a free-tier rate limit, wait as long as Groq asks (if short) and retry once
    const body = JSON.stringify({
      model: ANSWER_MODEL,
      messages,
      max_tokens: 1024,
      temperature: 0.2,
      reasoning_effort: "low",
    });

    let res: Response;
    for (let attempt = 0; ; attempt++) {
      res = await callGroq(body);
      if (res.status !== 429) break;
      const wait = Number(res.headers.get("retry-after") ?? "10");
      if (attempt >= 1 || wait > 20) {
        return json({ ok: false, reply: "The AI assistant is busy right now. Please wait a few seconds and try again." });
      }
      await new Promise((r) => setTimeout(r, wait * 1000 + 500));
    }

    // 5. Parse
    const data = await res.json();
    if (data.error) return json({ ok: false, reply: `AI error: ${data.error.message ?? "Unknown error."}` });

    const reply = data.choices?.[0]?.message?.content ?? "Sorry, I could not generate a response.";
    return json({ ok: true, reply });
  } catch (e) {
    return json({ ok: false, reply: `Request failed: ${(e as Error).message}` });
  }
});

async function isSignedInUser(authHeader: string): Promise<boolean> {
  if (!authHeader.startsWith("Bearer ")) return false;
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: authHeader },
    });
    return res.ok;
  } catch {
    return false;
  }
}

function callGroq(body: string): Promise<Response> {
  return fetch(GROQ_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${GROQ_API_KEY}` },
    body,
  });
}

// ── Retrieval ────────────────────────────────────────────────────────────────

async function loadRelevantChunks(query: string): Promise<string> {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/policy_chunks?select=content,page_number&order=chunk_index.asc`,
    { headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` } },
  );
  const rows = await res.json();
  if (!Array.isArray(rows)) return "";

  const chunks: Chunk[] = rows
    .map((r) => ({ content: String(r.content ?? "").trim(), page: r.page_number ?? null }))
    .filter((c) => c.content.length > 0);
  if (chunks.length === 0) return "";

  // The policy document may be in Bahasa Melayu while the question is in
  // English, so plain keyword matching on the question would miss. A small,
  // fast model first expands the question into English + Malay keywords.
  const keywords = await extractKeywords(query);
  const selected = selectRelevantChunks(chunks, keywords, MAX_CONTEXT_CHARS);

  return selected
    .map((c) => `[${c.page != null ? `Page ${c.page}` : "Page unknown"}]\n${c.content}`)
    .join("\n\n");
}

async function extractKeywords(query: string): Promise<string[]> {
  const fallback = query.split(/[ ?.,!]+/).filter(Boolean);
  try {
    const res = await callGroq(JSON.stringify({
      model: KEYWORD_MODEL,
      max_tokens: 300,
      temperature: 0,
      reasoning_effort: "low",
      messages: [
        { role: "system", content: KEYWORD_PROMPT },
        { role: "user", content: query },
      ],
    }));
    if (!res.ok) return fallback;
    const data = await res.json();
    const text: string = data.choices?.[0]?.message?.content ?? "";
    const keywords = text.split(/[,\n]/).map((k) => k.trim()).filter(Boolean);
    return keywords.length > 0 ? [...keywords, ...fallback] : fallback;
  } catch {
    return fallback;
  }
}

// PDF text extraction sometimes drops spaces ("CUTITAHUNAN"), so compare
// with all whitespace removed on both sides
const squash = (s: string) => s.replace(/\s+/g, "").toLowerCase();

function countOccurrences(text: string, term: string): number {
  let count = 0;
  for (let i = text.indexOf(term); i >= 0; i = text.indexOf(term, i + term.length)) count++;
  return count;
}

function selectRelevantChunks(chunks: Chunk[], keywords: string[], maxChars: number): Chunk[] {
  // Match whole phrases ("cuti sakit") and their individual words ("sakit")
  const terms = [...new Set(
    [...keywords, ...keywords.flatMap((k) => k.split(" "))]
      .map(squash)
      .filter((t) => t.length > 2 && !STOP_WORDS.has(t)),
  )];

  const texts = chunks.map((c) => squash(c.content));

  // TF-IDF style weighting: terms found on few pages (e.g. "cutisakit") count far
  // more than generic ones found everywhere (e.g. "cuti"), and a page that repeats
  // a term often is more likely to be the section about it
  const idf = new Map(terms.map((t) => [
    t,
    Math.log((texts.length + 1) / (1 + texts.filter((x) => x.includes(t)).length)),
  ]));

  let ranked = chunks
    .map((chunk, idx) => {
      const score = terms.reduce((sum, t) => {
        const tf = countOccurrences(texts[idx], t);
        return tf === 0 ? sum : sum + idf.get(t)! * t.length * (1 + Math.log(tf));
      }, 0);
      return { chunk, idx, score };
    })
    .sort((a, b) => b.score - a.score || a.idx - b.idx);

  // Nothing matched (e.g. "summarise the policy") → fall back to document order
  ranked = ranked.every((x) => x.score === 0)
    ? ranked.sort((a, b) => a.idx - b.idx)
    : ranked.filter((x) => x.score > 0);

  // Take the best chunks until the character budget is used up
  const selected: { idx: number; chunk: Chunk }[] = [];
  let used = 0;
  for (const x of ranked) {
    if (used + x.chunk.content.length > maxChars) {
      if (selected.length === 0) {
        selected.push({ idx: x.idx, chunk: { ...x.chunk, content: x.chunk.content.slice(0, maxChars) + "…" } });
        used = maxChars;
      }
      continue;
    }
    selected.push(x);
    used += x.chunk.content.length;
  }

  // Present the excerpts in document order
  return selected.sort((a, b) => a.idx - b.idx).map((s) => s.chunk);
}
