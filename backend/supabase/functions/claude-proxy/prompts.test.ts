// 外部依存ゼロのテスト用アサーション
function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) {
    throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}
function assertIncludes(actual: string, expected: string, msg?: string): void {
  if (!actual.includes(expected)) {
    throw new Error(msg ?? `Expected string to include "${expected}"\nActual: "${actual}"`);
  }
}
function assertGreater(actual: number, min: number, msg?: string): void {
  if (actual <= min) {
    throw new Error(msg ?? `Expected ${actual} > ${min}`);
  }
}

import {
  buildUserMessage,
  FALLBACK_TEXTS,
  fallbackTextForEngine,
  NANBOKU_FALLBACK_TEXTS,
  NANBOKU_SYSTEM_PROMPT,
  SEIMEI_SYSTEM_PROMPT,
  selectSystemPrompt,
} from "./prompts.ts";

Deno.test("FALLBACK_TEXTS: 12 件（十二天将分）存在する", () => {
  assertEquals(FALLBACK_TEXTS.length, 12);
});

Deno.test("NANBOKU_FALLBACK_TEXTS: 12 件（十二天将分）存在する", () => {
  assertEquals(NANBOKU_FALLBACK_TEXTS.length, 12);
});

Deno.test("FALLBACK_TEXTS: 全件が非空文字列", () => {
  for (let i = 0; i < FALLBACK_TEXTS.length; i++) {
    assertGreater(FALLBACK_TEXTS[i].length, 0, `FALLBACK_TEXTS[${i}] is empty`);
  }
});

Deno.test("SEIMEI_SYSTEM_PROMPT: 非空文字列かつ晴明の役割定義を含む", () => {
  assertGreater(SEIMEI_SYSTEM_PROMPT.length, 0);
  assertIncludes(SEIMEI_SYSTEM_PROMPT, "安倍晴明");
  assertIncludes(SEIMEI_SYSTEM_PROMPT, "200文字");
});

Deno.test("NANBOKU_SYSTEM_PROMPT: 非空文字列かつ南北の役割定義を含む", () => {
  assertGreater(NANBOKU_SYSTEM_PROMPT.length, 0);
  assertIncludes(NANBOKU_SYSTEM_PROMPT, "水野南北");
  assertIncludes(NANBOKU_SYSTEM_PROMPT, "江戸口語");
});

Deno.test("selectSystemPrompt: engine ごとに役割定義を選択する", () => {
  assertEquals(selectSystemPrompt("seimei"), SEIMEI_SYSTEM_PROMPT);
  assertEquals(selectSystemPrompt("nanboku"), NANBOKU_SYSTEM_PROMPT);
});

Deno.test("fallbackTextForEngine: engine ごとにフォールバック文を選択する", () => {
  assertEquals(fallbackTextForEngine("seimei", 0), FALLBACK_TEXTS[0]);
  assertEquals(fallbackTextForEngine("nanboku", 0), NANBOKU_FALLBACK_TEXTS[0]);
});

Deno.test("buildUserMessage: topic と question が含まれる", () => {
  const msg = buildUserMessage(
    { kan_index: 3, shi_index: 7, shikigami_index: 5, gogyo: "wood", score: 78 },
    "1990-05-15",
    "love",
    "彼との関係はどうなりますか"
  );
  assertIncludes(msg, "love");
  assertIncludes(msg, "彼との関係はどうなりますか");
  assertIncludes(msg, "1990-05-15");
});

Deno.test("buildUserMessage: 十干・十二支・式神名・五行が正しくマップされる", () => {
  const msg = buildUserMessage(
    { kan_index: 0, shi_index: 0, shikigami_index: 0, gogyo: "wood", score: 60 },
    "2000-01-01",
    "work",
    "仕事の運勢は"
  );
  assertIncludes(msg, "貴人");  // shikigami_index=0
  assertIncludes(msg, "木");    // gogyo=wood
  assertIncludes(msg, "甲");    // kan_index=0
  assertIncludes(msg, "子");    // shi_index=0
});

Deno.test("buildUserMessage: historySummary 未指定時は history タグなし", () => {
  const msg = buildUserMessage(
    { kan_index: 5, shi_index: 5, shikigami_index: 5, gogyo: "wood", score: 75 },
    "1985-03-20",
    "money",
    "金運は"
  );
  assertEquals(msg.includes("<history>"), false);
});

Deno.test("buildUserMessage: historySummary 指定時は history タグあり", () => {
  const summary = "love: 良縁あり\nwork: 昇進の兆し";
  const msg = buildUserMessage(
    { kan_index: 5, shi_index: 5, shikigami_index: 5, gogyo: "wood", score: 75 },
    "1985-03-20",
    "money",
    "金運は",
    summary
  );
  assertIncludes(msg, "<history>");
  assertIncludes(msg, "良縁あり");
});

Deno.test("buildUserMessage: 全 gogyo が正しくマップされる", () => {
  const cases: [string, string][] = [
    ["wood", "木"], ["fire", "火"], ["earth", "土"], ["metal", "金"], ["water", "水"],
  ];
  for (const [gogyo, expected] of cases) {
    const msg = buildUserMessage(
      { kan_index: 0, shi_index: 0, shikigami_index: 0, gogyo, score: 70 },
      "2000-01-01", "destiny", "運命は"
    );
    assertIncludes(msg, expected, `gogyo=${gogyo} should map to ${expected}`);
  }
});
