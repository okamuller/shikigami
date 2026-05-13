# アーキテクチャ — 式神鑑定

> 本書は「全体構造」「技術選定の理由」「重要な設計判断（ADR）」を扱う。  
> 具体的なテーブル定義や API シグネチャは [design.md](./design.md) を参照。

## 1. システム全体図

```
┌──────────────────────────────────────────────────┐
│  iOS App (SwiftUI / iOS 17+)                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│  │  Features  │  │   Engines  │  │   Models   │ │
│  │ (Onboard,  │  │   A: 六壬   │  │  User,     │ │
│  │  Home,     │  │   B: 観相   │  │  Fortune,  │ │
│  │  Fortune)  │  │            │  │  Receipt)  │ │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘ │
│        └────────┬──────┴────────┬──────┘        │
│                 ▼               ▼               │
│  ┌─────────────────────┐  ┌─────────────────┐  │
│  │  Network Layer      │  │ RevenueCat SDK  │  │
│  └─────────┬───────────┘  └─────────┬───────┘  │
└────────────┼──────────────────────────┼─────────┘
             │ HTTPS                    │
             ▼                          ▼
   ┌─────────────────────┐    ┌──────────────────┐
   │ Supabase Edge Func  │    │   App Store      │
   │  - claude-proxy     │    │   In-App Purchase│
   │  - fortune-cache    │    └──────────────────┘
   └──────┬──────────────┘
          │
          ├──→ Anthropic Messages API (Claude)
          └──→ Supabase Postgres (履歴 / キャッシュ)
```

## 2. 設計原則

1. **占術計算は完全クライアント / 純粋関数**  
   `Engines/` 配下に副作用なしの Swift で実装。同じ入力に必ず同じ出力。
2. **AI 文章生成のみサーバ経由**  
   Claude API キーをクライアントに持たせない（漏洩リスク回避）。
3. **オフライン耐性**  
   Claude API 障害時もテンプレ + ENGINE A で鑑定を返す（NFR-OF-01）。
4. **状態はサーバが正**  
   ローカルキャッシュは速度のためだけ。
5. **顔・手の画像は端末外に出さない**  
   Vision Framework によるオンデバイス解析（NFR-PR-01）。

## 3. 技術スタック

| レイヤー | 採用技術 | 主な代替 | 採用理由 |
|---|---|---|---|
| iOS UI | SwiftUI | UIKit | Apple 推奨・宣言的・iOS 17 機能を活用 |
| 占術計算 | Swift（純粋関数） | サーバ計算 | オフライン・低レイテンシ・テスト容易 |
| AI 生成 | Claude API (Sonnet 4.6) | GPT-4o, Gemini | 日本語文語表現の品質・Prompt Caching |
| 観相 AI | Vision Framework | Mediapipe | オンデバイス・プライバシー・依存少 |
| バックエンド | Supabase Edge Functions | AWS Lambda | 認証 + DB + Functions が一体・低コスト |
| DB | Supabase Postgres | Firestore | SQL・RLS で行レベル権限制御が容易 |
| 課金 | RevenueCat | StoreKit 直 | サブスク状態同期・解約分析・$10K まで無料 |
| エラー監視 | Sentry | Crashlytics | Edge Functions も合わせて監視可能 |
| アナリティクス | PostHog | Firebase | OSS / セルフホスト可・PII 配慮しやすい |

## 4. レイヤー分け

```
┌─────────────────────────────────┐
│ Feature Layer (Views + VM)      │  ←  SwiftUI / @Observable
├─────────────────────────────────┤
│ Domain Layer (Engines + Models) │  ←  純粋ロジック / DTO
├─────────────────────────────────┤
│ Infrastructure Layer            │  ←  Claude / Supabase / RevenueCat
│  (Network / Persistence / SDK)  │
└─────────────────────────────────┘
```

- **Feature** は Domain と Infrastructure を **プロトコル経由** で利用する。
- Domain は他のどの層にも依存しない。テストで FQ できる。
- Infrastructure 実装はテスト時にスタブに差し替える。

## 5. データフロー（鑑定生成）

```
[ユーザー入力]
   │
   ▼
[ViewModel] ─── ENGINE A 呼び出し（同期・純粋）
   │             │
   │             ▼
   │           [Meishiki]
   │
   ▼
[ClaudeClient.generate(meishiki, topic, question)]
   │
   ▼
[Supabase Edge Function: claude-proxy]
   │  ① キャッシュキー (input_hash) で fortune-cache を確認
   │  ② ヒットすれば DB から返却
   │  ③ ミスなら Claude API 呼び出し
   │  ④ 応答を fortunes テーブルへ保存
   │
   ▼
[Anthropic Messages API]
   │
   ▼
[iOS] ─── 鑑定文を表示・履歴に追加
```

## 6. 認証

- Apple Sign In のみ（メール / パスワード不要・離脱率低減）
- Supabase Auth が `apple_user_id` を保持
- 端末ローカルにはセッショントークンを Keychain で保存

## 7. キャッシング戦略

| キャッシュ | 場所 | TTL | キー |
|---|---|---|---|
| 鑑定文 | Supabase Postgres | 24 時間 | `SHA256(engine, birth_date, topic, date_jst)` |
| Claude プロンプト | Anthropic Prompt Caching | 24 時間 | システムプロンプトに `cache_control` 付与 |
| ユーザー命式 | iOS UserDefaults | 永続（生年月日変更時に無効化） | `user_id` |
| サブスク状態 | RevenueCat | アプリ起動時更新 | `apple_user_id` |

## 8. 課金フロー

1. iOS が RevenueCat SDK で `presentPaywall()` を表示
2. 購入完了で RevenueCat が領収書を Apple に検証
3. Webhook で Supabase の `subscriptions` テーブルを更新
4. iOS は `Customer.entitlements` を購読し、UI を即座に解放

詳細なペイウォール UI は `.claude/D_screens.md` Flow 3 を参照。

## 9. アーキテクチャ判断記録（ADR）

ADR は重大な設計判断を時系列で残す。新規追加時は番号をインクリメント。

### ADR-001: Claude API はサーバ経由で呼ぶ

- **判断**: クライアントから Anthropic API を直接呼ばず、Supabase Edge Function `claude-proxy` を経由する。
- **背景**: API キーをクライアントにバンドルすると、IPA 解凍で抜き取れる。
- **結果**: わずかなレイテンシ増加と引き換えに、キー漏洩リスクをゼロに。

### ADR-002: 占術計算はクライアントで完結

- **判断**: 六壬神課の計算は Swift の純粋関数として実装し、サーバを介さない。
- **背景**: 純粋計算でありオフライン動作が魅力 / サーバコストもかからない。
- **結果**: 「式神決定」演出を即座に表示できる。テストも容易。

### ADR-003: バックエンドは Supabase を採用

- **判断**: Auth + Postgres + Edge Functions + Storage を Supabase に統一。
- **背景**: AWS フルスタックは小規模初期では過剰。Firebase は SQL を捨てたくない。
- **結果**: 初期コスト ¥0〜数千円 / 月。RLS で権限管理が宣言的に書ける。

### ADR-004: 課金は RevenueCat 経由

- **判断**: StoreKit を直接扱わず、RevenueCat の SDK を採用。
- **背景**: 領収書検証・サブスク状態同期・チャーン分析を自作するコストが高い。
- **結果**: MRR $10K までは無料。サブスク KPI が即見える。

### ADR-005: 画像はオンデバイス処理

- **判断**: 顔・手の画像を Vision Framework でローカル解析し、サーバには送らない。
- **背景**: プライバシー訴求（NFR-PR-01）と、画像転送コスト削減。
- **結果**: App Store プライバシーラベル簡素化。差別化ポイント。

### ADR-006: ペイウォールはぼかし方式

- **判断**: 鑑定文の冒頭は無料で見せ、後半をぼかして「続きを見る」誘導。
- **背景**: 完全ロックよりも転換率が高い実績（業界標準）。
- **結果**: CV +15〜25% を目標。

## 10. 非機能要求とアーキテクチャの対応

| NFR | 実現手段 |
|---|---|
| NFR-PF-01（鑑定 p95 3 秒） | Prompt Caching + キャッシュ DB ヒット時は Claude 呼ばない |
| NFR-OF-01（API 障害耐性） | Edge Function でタイムアウト時テンプレ文を返す |
| NFR-PR-01（画像端末外送信なし） | Vision Framework オンデバイス |
| NFR-AV-01（稼働率 99.9%） | Supabase / Anthropic の SLA に依存 + Sentry 監視 |
| NFR-CO-01（1 鑑定 1 円未満） | Sonnet + Prompt Caching + キャッシュ DB |

## 11. 関連ドキュメント

- 詳細設計: [design.md](./design.md)
- 開発環境: [development.md](./development.md)
- セキュリティ: [security.md](./security.md)
