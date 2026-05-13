# 詳細設計 — 式神鑑定

> 本書は「データモデル」「API」「占術エンジン」「プロンプト」の具体仕様を扱う。  
> 全体構造の判断理由は [architecture.md](./architecture.md) を参照。  
> 要求仕様は [requirements.md](./requirements.md) を参照。

## 1. データモデル

### 1.1 Supabase Postgres スキーマ（初期案）

```sql
-- ユーザー
create table users (
  id            uuid primary key default gen_random_uuid(),
  apple_user_id text unique not null,
  birth_date    date,
  gender        text check (gender in ('yin','yang','none')),
  shikigami_id  smallint,             -- 0〜11
  created_at    timestamptz default now()
);

-- 鑑定履歴
create table fortunes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references users(id) on delete cascade,
  engine      text check (engine in ('seimei','nanboku','palm')),
  topic       text,                   -- love/work/money/...
  input_hash  text not null,          -- 入力の SHA256（キャッシュキー）
  prompt      text,
  response    text not null,
  tokens_in   int,
  tokens_out  int,
  created_at  timestamptz default now()
);
create index on fortunes (user_id, created_at desc);
create index on fortunes (input_hash);

-- 課金状態（RevenueCat と同期）
create table subscriptions (
  user_id     uuid primary key references users(id) on delete cascade,
  tier        text check (tier in ('free','premium','divine')) default 'free',
  expires_at  timestamptz,
  updated_at  timestamptz default now()
);
```

### 1.2 Row Level Security（RLS）

全テーブルで RLS を有効化し、最低限以下のポリシーを設定する。

```sql
alter table users         enable row level security;
alter table fortunes      enable row level security;
alter table subscriptions enable row level security;

-- users
create policy "users_self_read"
  on users for select using (auth.uid() = id);
create policy "users_self_write"
  on users for update using (auth.uid() = id);

-- fortunes
create policy "fortunes_self"
  on fortunes for all using (auth.uid() = user_id);

-- subscriptions
create policy "subscriptions_self_read"
  on subscriptions for select using (auth.uid() = user_id);
-- 書き込みは Edge Function (service role) のみ
```

### 1.3 キャッシュキー

```
input_hash = SHA256(engine || birth_date || topic || date_jst)
```

- 同一ユーザーが同日に同じ悩みカテゴリで鑑定 → キャッシュヒット
- 日付（JST）を含めるため「今日の運勢」は日次で更新

## 2. API 設計（Supabase Edge Functions）

### 2.1 `POST /functions/v1/claude-proxy`

鑑定文生成のメインエンドポイント。

**Request**
```json
{
  "engine": "seimei",
  "topic": "love",
  "question": "彼との関係はどうなりますか",
  "meishiki": {
    "kan_index": 3,
    "shi_index": 7,
    "shikigami_index": 5,
    "gogyo": "wood",
    "score": 78
  }
}
```

**Response (200)**
```json
{
  "id": "fortune_xxx",
  "text": "汝の式神は青龍。木の気が強く...",
  "cached": false,
  "tokens": { "input": 320, "output": 180 }
}
```

**エラー**
| HTTP | code | 意味 |
|---|---|---|
| 401 | `unauthorized` | JWT 不正 |
| 402 | `quota_exceeded` | 当日呼び出し上限超過（FREE 5 回） |
| 429 | `rate_limited` | Anthropic 側のレート制限 |
| 503 | `claude_unavailable` | フォールバック文を `text` に含む |

### 2.2 `POST /functions/v1/fortune-cache`

`input_hash` を渡してキャッシュヒットを確認する軽量エンドポイント。
（claude-proxy 内部でも使用するが、フロント側からプリフェッチ用に開放）

### 2.3 `POST /functions/v1/revenuecat-webhook`

RevenueCat からの Webhook を受け、`subscriptions` テーブルを更新する。
Webhook 検証ヘッダ `Authorization: Bearer <RC_WEBHOOK_KEY>` を必須とする。

## 3. 占術エンジン

### 3.1 ENGINE A — 六壬神課（Swift）

`.claude/B_logic.md` の JS 実装を Swift に移植。**純粋関数として実装**し、テスト容易性を確保。

```swift
struct Meishiki: Equatable {
    let kanIndex: Int       // 0..<10
    let shiIndex: Int       // 0..<12
    let shikigamiIndex: Int // 0..<12
    let getsushoIndex: Int  // 0..<12
    let gogyo: Gogyo
    let score: Int          // 60..<100
}

enum Gogyo { case wood, fire, earth, metal, water }

enum SeimeiEngine {
    static func calc(year: Int, month: Int, day: Int) -> Meishiki {
        let kan = ((year - 4) % 10 + 10) % 10
        let shi = ((year - 4) % 12 + 12) % 12
        let shikigami = ((month + day - 2) % 12 + 12) % 12
        let getsusho = ((month - 1) % 12 + 12) % 12
        let gogyoTable: [Gogyo] = [.wood, .wood, .fire, .fire, .earth,
                                   .earth, .metal, .metal, .water, .water]
        let score = ((year * 7 + month * 31 + day * 13) % 40) + 60
        return Meishiki(kanIndex: kan, shiIndex: shi,
                        shikigamiIndex: shikigami, getsushoIndex: getsusho,
                        gogyo: gogyoTable[kan], score: score)
    }
}
```

#### 十二天将テーブル

`.claude/B_logic.md` の表をそのまま `static let table = [(name, gogyo, kichi, meaning), ...]` で持つ。
ローカライズは `Localizable.strings` の `shikigami.0.name` 〜 `shikigami.11.name` で参照。

#### テスト観点

- 既知の生年月日（例: 1990-05-15）→ 固定値
- 月日境界（1/1, 12/31, うるう年 2/29）
- スコアは 60〜99 の範囲（プロパティテスト）

### 3.2 ENGINE B — 観相エンジン

| Phase | 入力 | 出力 |
|---|---|---|
| 1 | 6 パーツのスライダー値（0〜100） | 重み付け合計 + テンプレ ID |
| 2 | カメラ画像 | Vision Framework 68 点 → 距離比 → スコア |

**Phase 1 のスコア合成（参考）**
```
total = 0.20 * eyebrow + 0.20 * eye + 0.18 * nose
      + 0.16 * mouth   + 0.14 * ear + 0.12 * chin
```

**Phase 2 の実装メモ**
- `VNDetectFaceLandmarksRequest` を使用
- 解析は `Engines/PhysiognomyAnalyzer.swift` に閉じ込め、`UIImage` を引数に取らず正規化済みポイント配列を受ける（テスト性のため）

### 3.3 ENGINE C — Claude API（クライアント側）

`ClaudeClient` プロトコルで抽象化。テスト時はスタブ注入。

```swift
protocol ClaudeClient {
    func generate(request: FortuneRequest) async throws -> FortuneResponse
}
```

実装は `SupabaseClaudeClient` が `claude-proxy` Edge Function を呼ぶだけ。
リトライ（指数バックオフ 1/2/4/8 秒・最大 4 回）は実装側で行う。

### 3.4 ENGINE D — パーソナル記憶層

```
recent_summaries = fortunes
                     .filter(user_id = current)
                     .order_by(created_at desc)
                     .limit(5)
                     .map { "\(topic): \(first 40 chars)" }
                     .join("\n")
```

これを Claude プロンプトの `<history>` セクションに注入する。

## 4. プロンプト設計

### 4.1 共通テンプレ

```
<system>
{ROLE}                    -- 晴明 / 南北 の人格定義
{TONE_RULES}              -- 口調ルール（文語 / 江戸口語）
{LENGTH_LIMIT: 200文字}
</system>

<user>
<profile>
生年月日: {YYYY-MM-DD}
干支: {十干}{十二支}
式神: {名称}
五行: {木火土金水}
スコア: {0-100}
</profile>
<topic>{love/work/money/health/family/destiny}</topic>
<question>{自由テキスト・80 字以内}</question>
<history>{過去 N 件のサマリ}</history>
</user>
```

### 4.2 役割定義（晴明）

```
あなたは平安時代の陰陽師・安倍晴明である。
- 文語体（〜なり、〜べし、〜おろう、汝、式神）を用いる
- 神秘的で詩的、簡潔
- 200 文字以内・段落 2 つ（運命の告知 / 行動の教え）
- 占いの言葉として断定表現「必ず」「絶対」は禁止
```

### 4.3 役割定義（南北）

```
あなたは江戸後期の観相家・水野南北である。
- 江戸口語（〜じゃ、〜なるぞ、〜であろう）を用いる
- 人相・食・節制の教えを織り込む
- 厳しくも温かみのある口調
- 200 文字以内・段落 2 つ
- 医療・健康効果の断定表現は禁止
```

### 4.4 Prompt Caching

- システムプロンプト（役割定義 + 口調ルール）の末尾に `cache_control: { type: "ephemeral" }` を付与
- 24 時間のキャッシュヒットで入力トークン費用を約 90% 削減
- 1 鑑定あたりコスト試算は `.claude/B_logic.md` の表を参照

### 4.5 モデル選択

| 用途 | モデル | 理由 |
|---|---|---|
| 通常鑑定 | `claude-sonnet-4-6` | 品質 / コストバランス |
| Divine 詳細鑑定 | `claude-opus-4-7` | 文章の深さを優先 |
| 毎朝のひとこと | `claude-haiku-4-5` | 大量・短文・低コスト |

## 5. エラー処理 / フォールバック

| 状態 | 表示 | 内部処理 |
|---|---|---|
| 通常 | Claude 生成文 | キャッシュ → 生成 → 保存 |
| API 障害 | テンプレ文 + 「式神の声が今しばし届かぬ」 | Edge Function でテンプレートを選択して返す |
| オフライン | ENGINE A の式神のみ表示 | 端末キャッシュから表示・後で再試行 |
| 上限超過 | ペイウォール訴求 | 402 を返し UI で課金導線 |

## 6. ユースケースから設計へのトレース

| ユースケース | 関連設計 |
|---|---|
| UC-1 新規鑑定 | 2.1 claude-proxy / 3.1 SeimeiEngine / 4.2 晴明プロンプト |
| UC-2 詳細鑑定購入 | 2.3 revenuecat-webhook / 1.1 subscriptions テーブル |
| UC-3 手相 AI | 3.2 ENGINE B Phase 2 / 4.3 南北プロンプト |
| UC-4 API 障害 | 5. フォールバック |

## 7. 関連ドキュメント

- アーキテクチャ判断: [architecture.md](./architecture.md)
- セキュリティ要件: [security.md](./security.md)
- テスト方針: [testing.md](./testing.md)
