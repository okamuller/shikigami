import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabaseClients.ts";

// Divine プラン用プロダクト ID プレフィックス（環境変数で上書き可能）
const DIVINE_PRODUCT_PREFIX = Deno.env.get("REVENUECAT_DIVINE_PRODUCT_PREFIX") ?? "divine";

// RevenueCat イベント種別 → tier マッピング
const PURCHASE_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
]);
const EXPIRY_EVENTS = new Set([
  "CANCELLATION",
  "EXPIRATION",
  "BILLING_ISSUE",
  "SUBSCRIBER_ALIAS",
]);

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // 1. Webhook 認証（constant-time 比較）
  const authHeader = req.headers.get("Authorization") ?? "";
  const expectedKey = `Bearer ${Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? ""}`;
  if (!constantTimeEqual(authHeader, expectedKey)) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: corsHeaders });
  }

  // 2. ボディ解析
  let payload: { event?: Record<string, unknown> };
  try {
    payload = await req.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400, headers: corsHeaders });
  }

  const event = payload.event;
  if (!event) {
    return Response.json({ ok: true, message: "no_event" }, { headers: corsHeaders });
  }

  const eventType = String(event.type ?? "");
  const appUserId = String(event.app_user_id ?? "");
  const productId = String(event.product_id ?? "");
  const expirationMs = event.expiration_at_ms as number | undefined;

  if (!appUserId) {
    return Response.json({ error: "missing_app_user_id" }, { status: 400, headers: corsHeaders });
  }

  // 3. Tier 判定
  let newTier: string | null = null;

  if (PURCHASE_EVENTS.has(eventType)) {
    // Divine プランの場合は product_id で判定
    newTier = productId.startsWith(DIVINE_PRODUCT_PREFIX) ? "divine" : "premium";
  } else if (EXPIRY_EVENTS.has(eventType)) {
    newTier = "free";
  } else {
    // 未知のイベント種別は無視
    return Response.json({ ok: true, message: "ignored" }, { headers: corsHeaders });
  }

  // 4. subscriptions テーブルを upsert（service role でRLSをバイパス）
  const supabase = getServiceClient();
  const { error } = await supabase.from("subscriptions").upsert(
    {
      user_id: appUserId,
      tier: newTier,
      expires_at: expirationMs ? new Date(expirationMs).toISOString() : null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" }
  );

  if (error) {
    console.error("subscriptions upsert error:", error);
    return Response.json({ error: "db_error" }, { status: 500, headers: corsHeaders });
  }

  return Response.json({ ok: true }, { headers: corsHeaders });
});
