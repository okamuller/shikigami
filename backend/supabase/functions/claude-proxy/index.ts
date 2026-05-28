import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getUserClient, getServiceClient } from "../_shared/supabaseClients.ts";
import {
  buildHistorySummary,
  buildUserMessage,
  fallbackTextForEngine,
  selectSystemPrompt,
} from "./prompts.ts";

const MAX_FREE_FORTUNES = 5;
const MAX_PREMIUM_FORTUNES = 50;
const ANTHROPIC_TIMEOUT_MS = 25_000;

interface MeishikiPayload {
  kan_index: number;
  shi_index: number;
  shikigami_index: number;
  gogyo: string;
  score: number;
}

interface FortuneRequestBody {
  engine: string;
  topic: string;
  question: string;
  meishiki: MeishikiPayload;
}

// docs/design.md §4.1 キャッシュキー仕様準拠
// scoreBand: 60-69 → low, 70-84 → middle, 85-99 → high
function scoreBandFromScore(score: number): string {
  if (score <= 69) return "low";
  if (score <= 84) return "middle";
  return "high";
}

async function buildInputHash(
  userId: string,
  engine: string,
  topic: string,
  question: string,
  shikigamiIndex: number,
  gogyo: string,
  score: number,
  historySummary: string
): Promise<string> {
  const dateJst = new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Tokyo" });
  const normalized = question.trim().normalize("NFKC").replace(/\s+/g, " ");
  const scoreBand = scoreBandFromScore(score);
  const historySummaryHash = await sha256Hex(historySummary);
  const raw = [userId, engine, topic, normalized, String(shikigamiIndex), gogyo, scoreBand, historySummaryHash, dateJst].join("|");
  return sha256Hex(raw);
}

async function sha256Hex(raw: string): Promise<string> {
  const buffer = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(raw));
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // 1. Auth check
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: corsHeaders });
  }

  // 2. Parse and validate body
  let body: FortuneRequestBody;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400, headers: corsHeaders });
  }

  const { engine, topic, question, meishiki } = body;
  if (!engine || !topic || !question || !meishiki) {
    return Response.json({ error: "missing_fields" }, { status: 400, headers: corsHeaders });
  }
  if (!["seimei", "nanboku"].includes(engine)) {
    return Response.json({ error: "invalid_engine" }, { status: 400, headers: corsHeaders });
  }
  if (question.length > 80) {
    return Response.json({ error: "question_too_long" }, { status: 400, headers: corsHeaders });
  }

  const userClient = getUserClient(jwt);

  // 3. Resolve userId from session
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: corsHeaders });
  }
  const userId = user.id;

  const serviceClient = getServiceClient();

  // 4. Fetch user profile (birth_date from DB, not client-provided)
  const { data: userProfile } = await serviceClient
    .from("users")
    .select("birth_date")
    .eq("id", userId)
    .single();

  const birthDate = userProfile?.birth_date ?? "";

  // 5. Quota check
  const { data: quotaData } = await serviceClient.rpc("get_fortune_quota", {
    p_user_id: userId,
  });
  const todayCount = (quotaData as number) ?? 0;

  const { data: subData } = await serviceClient
    .from("subscriptions")
    .select("tier")
    .eq("user_id", userId)
    .maybeSingle();
  const tier = subData?.tier ?? "free";

  const maxFortunes =
    tier === "divine" ? Infinity : tier === "premium" ? MAX_PREMIUM_FORTUNES : MAX_FREE_FORTUNES;

  if (todayCount >= maxFortunes) {
    return Response.json({ error: "quota_exceeded" }, { status: 402, headers: corsHeaders });
  }

  // 6. Build cache key using only pre-today history (stable within a day)
  // Including today's results would change historySummaryHash after each generation,
  // causing cache misses for identical same-day repeated requests.
  const dateJst = new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Tokyo" });
  const todayJstIso = `${dateJst}T00:00:00+09:00`;

  const { data: stableHistory } = await serviceClient
    .from("fortunes")
    .select("topic, response")
    .eq("user_id", userId)
    .lt("created_at", todayJstIso)
    .order("created_at", { ascending: false })
    .limit(5);

  const stableHistorySummary = buildHistorySummary(stableHistory ?? []);
  const inputHash = await buildInputHash(userId, engine, topic, question, meishiki.shikigami_index, meishiki.gogyo, meishiki.score, stableHistorySummary);

  // Fetch all recent history (incl. today) for the AI prompt context
  const { data: recentFortunes } = await serviceClient
    .from("fortunes")
    .select("topic, response")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(5);

  const historySummary = buildHistorySummary(recentFortunes ?? []);

  const { data: cached } = await serviceClient
    .from("fortunes")
    .select("id, response, tokens_in, tokens_out")
    .eq("input_hash", inputHash)
    .eq("user_id", userId)
    .maybeSingle();

  if (cached) {
    return Response.json(
      {
        id: cached.id,
        text: cached.response,
        cached: true,
        tokens: { input: cached.tokens_in, output: cached.tokens_out },
      },
      { headers: corsHeaders }
    );
  }

  // 7. Build prompt
  const systemPrompt = selectSystemPrompt(engine);
  const userMessage = buildUserMessage(meishiki, birthDate, topic, question, historySummary);

  // 8. Call Anthropic API
  const modelId =
    tier === "divine"
      ? (Deno.env.get("CLAUDE_MODEL_PREMIUM") ?? "claude-opus-4-7")
      : (Deno.env.get("CLAUDE_MODEL_DEFAULT") ?? "claude-sonnet-4-6");

  let fortuneText: string;
  let tokensIn = 0;
  let tokensOut = 0;
  let isFallback = false;

  try {
    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: modelId,
        max_tokens: 512,
        system: [
          { type: "text", text: systemPrompt, cache_control: { type: "ephemeral" } },
        ],
        messages: [{ role: "user", content: userMessage }],
      }),
      signal: AbortSignal.timeout(ANTHROPIC_TIMEOUT_MS),
    });

    if (anthropicRes.status === 429) {
      return Response.json({ error: "rate_limited" }, { status: 429, headers: corsHeaders });
    }

    if (!anthropicRes.ok) {
      throw new Error(`Anthropic error: ${anthropicRes.status}`);
    }

    const anthropicData = await anthropicRes.json();
    fortuneText = anthropicData.content?.[0]?.text ?? "";
    tokensIn = anthropicData.usage?.input_tokens ?? 0;
    tokensOut = anthropicData.usage?.output_tokens ?? 0;
  } catch (_err) {
    isFallback = true;
    fortuneText = fallbackTextForEngine(engine, meishiki.shikigami_index);

    return Response.json(
      {
        error: "claude_unavailable",
        text: fortuneText,
        cached: false,
        is_fallback: true,
        tokens: { input: 0, output: 0 },
      },
      { status: 503, headers: corsHeaders }
    );
  }

  // 9. Persist
  const { data: inserted } = await serviceClient
    .from("fortunes")
    .insert({
      user_id: userId,
      engine,
      topic,
      input_hash: inputHash,
      prompt: userMessage,
      response: fortuneText,
      tokens_in: tokensIn,
      tokens_out: tokensOut,
    })
    .select("id")
    .single();

  return Response.json(
    {
      id: inserted?.id ?? crypto.randomUUID(),
      text: fortuneText,
      cached: false,
      is_fallback: isFallback,
      tokens: { input: tokensIn, output: tokensOut },
    },
    { headers: corsHeaders }
  );
});
