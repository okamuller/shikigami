import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getUserClient } from "../_shared/supabaseClients.ts";

interface CacheRequest {
  input_hash: string;
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: corsHeaders });
  }

  let body: CacheRequest;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400, headers: corsHeaders });
  }

  if (!body.input_hash) {
    return Response.json({ error: "missing_input_hash" }, { status: 400, headers: corsHeaders });
  }

  const supabase = getUserClient(jwt);

  const todayJst = new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Tokyo" });

  const { data, error } = await supabase
    .from("fortunes")
    .select("id, response, tokens_in, tokens_out")
    .eq("input_hash", body.input_hash)
    .gte("created_at", `${todayJst}T00:00:00+09:00`)
    .lt("created_at", `${todayJst}T24:00:00+09:00`)
    .maybeSingle();

  if (error) {
    return Response.json({ error: "db_error" }, { status: 500, headers: corsHeaders });
  }

  if (!data) {
    return Response.json({ hit: false }, { headers: corsHeaders });
  }

  return Response.json(
    {
      hit: true,
      fortune: {
        id: data.id,
        text: data.response,
        tokens_in: data.tokens_in,
        tokens_out: data.tokens_out,
      },
    },
    { headers: corsHeaders }
  );
});
