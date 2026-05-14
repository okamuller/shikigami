// 外部依存ゼロのテスト用アサーション
function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) {
    throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

import { corsHeaders, handleCors } from "./cors.ts";

Deno.test("handleCors: OPTIONS リクエストに 204 を返す", () => {
  const req = new Request("http://localhost/test", { method: "OPTIONS" });
  const res = handleCors(req);
  assertEquals(res?.status, 204);
});

Deno.test("handleCors: OPTIONS 以外は null を返す", () => {
  for (const method of ["POST", "GET", "PUT", "DELETE"]) {
    const req = new Request("http://localhost/test", { method });
    const res = handleCors(req);
    assertEquals(res, null, `Expected null for ${method}`);
  }
});

Deno.test("corsHeaders: 必須 3 ヘッダーを持つ", () => {
  assertEquals(typeof corsHeaders["Access-Control-Allow-Origin"], "string");
  assertEquals(typeof corsHeaders["Access-Control-Allow-Headers"], "string");
  assertEquals(typeof corsHeaders["Access-Control-Allow-Methods"], "string");
});

Deno.test("handleCors OPTIONS: CORS ヘッダーが含まれる", () => {
  const req = new Request("http://localhost", { method: "OPTIONS" });
  const res = handleCors(req);
  assertEquals(res?.headers.get("Access-Control-Allow-Origin"), corsHeaders["Access-Control-Allow-Origin"]);
});
