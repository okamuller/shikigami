import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getUserClient, getServiceClient } from "../_shared/supabaseClients.ts";

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: corsHeaders });
  }

  // JWT からユーザー検証
  const userClient = getUserClient(jwt);
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return Response.json({ error: "unauthorized" }, { status: 401, headers: corsHeaders });
  }

  // RevenueCat: 顧客データ削除（GDPR / security.md §4.4 best-effort）
  const rcKey = Deno.env.get("REVENUECAT_SECRET_KEY");
  if (rcKey) {
    try {
      await fetch(`https://api.revenuecat.com/v1/subscribers/${user.id}`, {
        method: "DELETE",
        headers: { "Authorization": `Bearer ${rcKey}` },
      });
    } catch {
      console.warn("RevenueCat deletion skipped (non-fatal)");
    }
  }

  // Supabase auth.users から削除 → CASCADE: users / fortunes / subscriptions
  const service = getServiceClient();
  const { error: deleteError } = await service.auth.admin.deleteUser(user.id);
  if (deleteError) {
    return Response.json(
      { error: deleteError.message },
      { status: 500, headers: corsHeaders }
    );
  }

  return Response.json({ success: true }, { headers: corsHeaders });
});
