# セキュリティと法務 — 式神鑑定

> 本書はセキュリティ運用ルールと法令遵守を扱う。  
> 技術的な認証 / 認可は [architecture.md](./architecture.md) と [design.md](./design.md) を参照。

## 1. シークレット管理

### 1.1 ルール

- API キー・署名情報はリポジトリにコミットしない
- ローカル: `.env.local` / Xcode `xcconfig`（gitignore 済み）
- CI/CD: GitHub Secrets
- クライアントから Claude API を直接叩かない（Edge Functions 経由）

### 1.2 必要なシークレット

| キー | 用途 | 配置先 |
|---|---|---|
| `ANTHROPIC_API_KEY` | Claude API | Supabase Edge Functions |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | クライアント接続 | iOS（公開可） |
| `SUPABASE_SERVICE_ROLE_KEY` | サーバ書き込み | Edge Functions のみ |
| `REVENUECAT_PUBLIC_API_KEY` | サブスク取得 | iOS（公開可） |
| `REVENUECAT_WEBHOOK_AUTH` | Webhook 検証 | Edge Functions |
| `APPLE_TEAM_ID` / `MATCH_PASSWORD` | 署名 | GitHub Secrets |
| `GITHUB_TOKEN` | `push_shikigami_full.py` 実行 | ローカルのみ |

### 1.3 ローテーション

- 鍵漏洩疑い時は **30 分以内** に該当キーを失効
- Anthropic Console / Supabase Dashboard の Usage を週次確認
- 退職者発生時はその週のうちに全 PAT / シークレットをローテーション

## 2. 認証 / 認可

- Apple Sign In のみ（メール / パスワード不要）
- Supabase Auth が JWT を発行・Keychain に保存
- DB: Row Level Security を全テーブルで有効化（`auth.uid() = user_id`）
- Edge Functions: 認証必須エンドポイントは JWT を検証してから処理

詳細スキーマは [design.md §1.2](./design.md#12-row-level-securityrls) 参照。

## 3. プライバシー

### 3.1 取扱データ

| データ | 保管 | 第三者提供 |
|---|---|---|
| 生年月日 | Supabase | なし |
| 性別（陰/陽/未回答） | Supabase | なし |
| 鑑定履歴 | Supabase | なし |
| 顔写真（観相） | **端末のみ・解析後即破棄** | なし |
| 手の写真（手相） | **端末のみ・解析後即破棄** | なし |
| 課金情報 | Apple / RevenueCat | RevenueCat（決済委託） |
| 端末識別子 | PostHog | PostHog（分析委託） |

### 3.2 プライバシーポリシー

- 初版を法務レビュー後、ルートと App Store Connect の両方に掲載
- 顔写真がデバイス外に出ない旨を明記
- 第三者提供（Apple / Anthropic / Supabase / RevenueCat / PostHog）を列挙

### 3.3 App Store プライバシーラベル

- 「ユーザーに関連付けられたデータ」: 購入履歴・診断データ
- 「ユーザーに関連付けられていないデータ」: 製品操作・パフォーマンス
- 「収集していない」: 健康とフィットネス・連絡先情報・正確な位置情報

## 4. 法令遵守

### 4.1 景品表示法

- 「必ず当たる」「絶対」「100%」などの断定表現を禁止
- プロンプトの役割定義にも「断定禁止」を明記し、UI 側でも NG ワードフィルタを実装
- ストア表記でも誇大表現を使わない

### 4.2 特定商取引法

- 事業者名・所在地・連絡先・代金支払方法・解約方法をアプリ内 / 設定画面 / ストア説明文に明示
- 自動更新の条件・課金タイミングをペイウォール直近に明示

### 4.3 薬機法

- 健康・医療的効能効果を謳わない（観相 / 節食の文言に注意）
- 「食を慎むことで病気が治る」等の表現は **NG**
- 法務レビューで毎リリース確認

### 4.4 占いに関する自主規制

- 不安を煽る表現の禁止
- 鑑定結果のシェア時にも責任表記を含める

## 5. 依存パッケージ管理

- Dependabot を週次で実行
- 重大度 High 以上の脆弱性は 7 日以内にパッチ
- Swift Package Manager のロックファイル `Package.resolved` をコミットする

## 6. データ削除リクエスト

- アプリ内「アカウント削除」から完全削除可能
- バックエンドでは `users.id` を起点に `fortunes` `subscriptions` を CASCADE 削除
- RevenueCat 側のサブスクは継続するが、ユーザー紐付けは解除
- リクエストから 30 日以内に完了

## 7. ペネトレーションテスト / 脆弱性レポート

- 公開後 6 ヶ月以内に外部ペネトレーションテストを 1 回実施
- `security@shikigami.app`（仮）で脆弱性レポートを受け付ける
- 重大度 Critical は 7 日以内に対応開始

## 8. 関連ドキュメント

- 認可スキーマ: [design.md §1.2](./design.md#12-row-level-securityrls)
- インシデント対応: [operations.md §4](./operations.md#4-インシデント対応)
- 要求仕様の制約: [requirements.md §6](./requirements.md#6-制約と前提)
