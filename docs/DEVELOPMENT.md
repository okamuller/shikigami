# 開発ドキュメント — 式神鑑定 / SHIKIGAMI FORTUNE

> 本書は実装担当者向けの **開発ガイド** である。
> 世界観・ロジック・グロース・画面・事業計画は `.claude/A_world_ui.md` 〜 `.claude/E_bizplan.md` を参照のこと。
> 本ドキュメントは「どう作るか」「どう運用するか」だけを扱う。

---

## 目次

1. [このドキュメントの位置づけ](#1-このドキュメントの位置づけ)
2. [リポジトリ構成](#2-リポジトリ構成)
3. [開発環境セットアップ](#3-開発環境セットアップ)
4. [シークレット / 環境変数](#4-シークレット--環境変数)
5. [全体アーキテクチャ](#5-全体アーキテクチャ)
6. [データモデル](#6-データモデル)
7. [占術エンジン実装ガイド](#7-占術エンジン実装ガイド)
8. [Claude API 統合](#8-claude-api-統合)
9. [モックアップ（JSX）の動かし方](#9-モックアップjsxの動かし方)
10. [push_shikigami_full.py の使い方](#10-push_shikigami_fullpy-の使い方)
11. [ブランチ運用 / コミット規約](#11-ブランチ運用--コミット規約)
12. [テスト戦略](#12-テスト戦略)
13. [CI / CD](#13-ci--cd)
14. [リリースプロセス](#14-リリースプロセス)
15. [コーディング規約](#15-コーディング規約)
16. [セキュリティと法務](#16-セキュリティと法務)
17. [実装ロードマップ（チケット粒度）](#17-実装ロードマップチケット粒度)
18. [トラブルシューティング](#18-トラブルシューティング)
19. [用語集](#19-用語集)
20. [参考リンク](#20-参考リンク)

---

## 1. このドキュメントの位置づけ

| ドキュメント | 役割 | 主読者 |
|---|---|---|
| `README.md` | プロジェクト入口・概要 | 全員 |
| `.claude/A_world_ui.md` | 世界観・UIコンセプト | デザイナー・PM |
| `.claude/B_logic.md` | 占術ロジック設計 | エンジニア・占術監修 |
| `.claude/C_growth.md` | グロース戦略 | マーケ・PM |
| `.claude/D_screens.md` | 画面 / フロー設計 | デザイナー・iOSエンジニア |
| `.claude/E_bizplan.md` | 事業計画サマリー | 経営・投資家 |
| `docs/business_plan.docx` | 事業計画書（フル版） | 投資家・経営 |
| **`docs/DEVELOPMENT.md`** | **開発ガイド（本書）** | **エンジニア** |

> 設計と実装の境界を明確にするため、本書には「何を作るか（What）」は最小限しか書かない。
> 設計に踏み込む場合は `.claude/` 側を更新し、本書は実装方法に絞ること。

---

## 2. リポジトリ構成

```
shikigami/
├── README.md
├── .claude/
│   ├── A_world_ui.md
│   ├── B_logic.md
│   ├── C_growth.md
│   ├── D_screens.md
│   └── E_bizplan.md
├── docs/
│   ├── business_plan.docx
│   └── DEVELOPMENT.md           ← 本書
├── mockups/
│   ├── 01_world_ui.jsx
│   ├── 02_logic_engine.jsx
│   ├── 03_growth_dashboard.jsx
│   └── 04_additional_screens.jsx
├── ios/                         ← Phase 1 で作成（SwiftUI プロジェクト）
│   ├── Shikigami.xcodeproj
│   ├── Shikigami/
│   │   ├── App/
│   │   ├── Features/
│   │   │   ├── Onboarding/
│   │   │   ├── Home/
│   │   │   ├── Fortune/
│   │   │   ├── Palmistry/
│   │   │   └── Paywall/
│   │   ├── Engines/             ← ENGINE A/B（純粋ロジック）
│   │   ├── Network/             ← Claude / Supabase クライアント
│   │   ├── Models/
│   │   ├── DesignSystem/        ← カラー・フォント・五芒星等
│   │   └── Resources/
│   └── ShikigamiTests/
├── backend/                     ← Phase 1 で作成（Supabase Edge Functions）
│   ├── supabase/
│   │   ├── functions/
│   │   │   ├── claude-proxy/    ← APIキーをクライアントから隠す
│   │   │   └── fortune-cache/
│   │   └── migrations/
│   └── README.md
├── scripts/
│   └── push_shikigami_full.py   ← ドキュメント一括 push スクリプト
└── .github/
    └── workflows/
        ├── ios.yml              ← Build / Test / TestFlight
        └── lint.yml             ← Swift / Markdown
```

> `ios/` `backend/` `.github/` は本書執筆時点（ドキュメント整備フェーズ）では未作成。
> Phase 1 着手時に上記構造で雛形を切ること。

---

## 3. 開発環境セットアップ

### 3.1 必須ツール

| ツール | バージョン | 用途 |
|---|---|---|
| macOS | 14 (Sonoma) 以降 | iOS 開発の前提 |
| Xcode | 15.4 以降 | SwiftUI / Vision |
| Swift | 5.10 以降 | 同梱 |
| Node.js | 20 LTS | モックアップ・Supabase CLI |
| Python | 3.10 以降 | push スクリプト |
| Git | 2.40 以降 | バージョン管理 |
| Supabase CLI | 1.150 以降 | DB マイグレーション |
| RevenueCat CLI | 任意 | サブスク検証 |

### 3.2 アカウント

- Apple Developer Program（有料・¥12,800/年）
- Anthropic Console（Claude API キー）
- Supabase（Hobby tier から開始可）
- RevenueCat（Free tier で MRR $10K まで）
- App Store Connect

### 3.3 初回チェックアウト

```bash
git clone git@github.com:okamuller/shikigami.git
cd shikigami

# iOS（Phase 1 以降）
cd ios
open Shikigami.xcodeproj
# Signing & Capabilities でチーム選択

# バックエンド（Phase 1 以降）
cd ../backend
supabase login
supabase link --project-ref <PROJECT_REF>
supabase db push
```

---

## 4. シークレット / 環境変数

### 4.1 取り扱いルール

- API キーや署名情報は **絶対にリポジトリにコミットしない**。
- ローカルは `.env.local` または Xcode の `xcconfig`（gitignore 済み）。
- CI/CD は **GitHub Secrets** に登録。
- 端末から Claude API を直接叩かない。**Supabase Edge Functions 経由**でプロキシし、キーをサーバ側に閉じ込める。

### 4.2 必要なシークレット

| キー | 用途 | 配置先 |
|---|---|---|
| `ANTHROPIC_API_KEY` | Claude API | Supabase Edge Functions |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | クライアント接続 | iOS（公開可） |
| `SUPABASE_SERVICE_ROLE_KEY` | サーバ側書き込み | Edge Functions のみ |
| `REVENUECAT_PUBLIC_API_KEY` | サブスク状態取得 | iOS（公開可） |
| `APPLE_TEAM_ID` / `MATCH_PASSWORD` | 署名 | GitHub Secrets |
| `GITHUB_TOKEN` | `push_shikigami_full.py` 実行用 | ローカルのみ |

### 4.3 ローテーション

- 鍵漏洩疑い時は **30 分以内** に該当キーを失効。
- Anthropic Console / Supabase Dashboard の Usage を週次確認。

---

## 5. 全体アーキテクチャ

```
┌──────────────────────────────────────────────────┐
│  iOS App (SwiftUI)                               │
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
          ├──→ Claude API (Sonnet)
          └──→ Supabase Postgres (履歴・キャッシュ)
```

### 5.1 設計原則

- **占術計算は完全クライアント / 純粋関数**。`Engines/` 配下に副作用なしの Swift で実装。同じ入力には必ず同じ出力（テストしやすさのため）。
- **AI 文章生成のみサーバ経由**。クライアントが Claude API キーを持たない。
- **オフライン耐性**: Claude API が落ちてもエンジンA + テンプレート文で最低限の鑑定は返す（`.claude/B_logic.md` のフォールバック設計）。
- **状態はサーバが正**。ローカルキャッシュは速度のためだけに持つ。

---

## 6. データモデル

### 6.1 Supabase Postgres スキーマ（初期案）

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

-- Row Level Security
alter table users enable row level security;
alter table fortunes enable row level security;
alter table subscriptions enable row level security;
-- 各テーブルで auth.uid() = user_id ポリシーを必ず設定
```

### 6.2 キャッシュキー設計

`input_hash = SHA256(engine || birth_date || topic || date_jst)`

- 同じユーザーが同日に同じ悩みカテゴリで鑑定 → キャッシュヒット
- 日付を含めるので「今日の運勢」は日次で新鮮

---

## 7. 占術エンジン実装ガイド

### 7.1 ENGINE A — 六壬神課（Swift）

`.claude/B_logic.md` の JS 実装を Swift に移植。**純粋関数として実装**し、`Date` をそのまま渡さず引数で年月日を受ける（テスト容易性）。

```swift
struct Meishiki: Equatable {
    let kanIndex: Int       // 0..<10
    let shiIndex: Int       // 0..<12
    let shikigamiIndex: Int // 0..<12
    let getsushoIndex: Int  // 0..<12
    let gogyo: Gogyo        // .wood / .fire / .earth / .metal / .water
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

#### テスト観点
- 既知の生年月日（例: 安倍晴明の伝承上の誕生日 921-02-21）に対し固定値を返す。
- 月日境界（1/1, 12/31, うるう年 2/29）。
- スコアは 60〜99 の範囲。

### 7.2 ENGINE B — 観相エンジン

- **Phase 1**: スライダー入力（眉/目/鼻/口/耳/顎）→ 各 0〜100 → 重み付け合計でテンプレ選択。
- **Phase 2**: `VNDetectFaceLandmarksRequest` で 68 点ランドマーク取得 → 距離比をスコア化。
- 解析はオンデバイス完結。**画像をサーバに送らない**（プライバシー訴求）。

### 7.3 ENGINE C — Claude API

7. [Claude API 統合](#8-claude-api-統合) を参照。

### 7.4 ENGINE D — パーソナル記憶層

- `fortunes` テーブルから直近 N 件のサマリを取り、システムプロンプトに `<context>` として注入。
- N=5 を初期値とし、トークン上限（1,000 トークン）を超えない範囲で要約。
- 「以前『仕事の悩み』で鑑定したな」というニュアンスを Claude に持たせるため。

---

## 8. Claude API 統合

### 8.1 呼び出し経路

```
iOS → Supabase Edge Function `claude-proxy`
     → Anthropic Messages API (claude-sonnet-4-6)
```

クライアントから直接 `api.anthropic.com` を叩くことは **禁止**（APIキー漏洩のため）。

### 8.2 モデル選択

- 既定: `claude-sonnet-4-6`（コストと品質のバランス）
- 高級プラン詳細鑑定: `claude-opus-4-7`（必要時のみ・コスト2倍を許容）
- 軽量バナー文言: `claude-haiku-4-5`（毎朝のプッシュ通知文など）

### 8.3 プロンプト構造

`.claude/B_logic.md` のシステムプロンプトを基本とし、以下を変数化：

```
<system>
{役割定義: 晴明 or 南北}
{口調ルール}
{出力上限: 200文字}
</system>

<user>
<profile>
生年月日: {YYYY-MM-DD}
干支: {十干}{十二支}
式神: {名称}
五行: {木火土金水}
スコア: {0-100}
</profile>
<topic>{love/work/money/...}</topic>
<question>{ユーザー入力テキスト}</question>
<history>{直近の鑑定要約 0..N 件}</history>
</user>
```

### 8.4 プロンプトキャッシュ

Anthropic の Prompt Caching を有効化：
- システムプロンプト（晴明用 / 南北用）を `cache_control: ephemeral` でマーク。
- 24 時間のキャッシュヒットで入力トークン費用を 90% 削減。

### 8.5 エラー処理

| エラー | 対応 |
|---|---|
| 4xx（リクエスト不正） | ログして開発者に通知。ユーザーには「式神の声が届かぬ。今しばし待たれよ」とテンプレ表示 |
| 429（レート制限） | Exponential backoff（1s, 2s, 4s, 8s。最大4回） |
| 5xx / タイムアウト | ENGINE A のテンプレート文へフォールバック |
| ネット不通 | オフラインモードへ。最終結果のみキャッシュから表示 |

### 8.6 コストガード

- 1 ユーザー / 1 日あたり Claude 呼び出し上限: 無料 5 回 / Premium 50 回 / Divine 無制限。
- Edge Function で `users.tier` を見て弾く。

---

## 9. モックアップ（JSX）の動かし方

### 9.1 claude.ai の Artifact で確認（最速）

1. `mockups/0X_*.jsx` をエディタで開く
2. 全文コピー → claude.ai のチャットに貼って「これを Artifact で表示して」
3. インタラクティブにレビュー可能

### 9.2 ローカル React で確認

```bash
npx create-react-app shikigami-demo
cd shikigami-demo
npm install lucide-react

# 1 ファイルずつ確認
cp ../shikigami/mockups/01_world_ui.jsx src/App.jsx
npm start
```

> Tailwind を使う JSX の場合は `tailwindcss` の追加導入が必要。
> 詳細はモックアップ冒頭のコメントを参照。

---

## 10. push_shikigami_full.py の使い方

### 10.1 用途

`.claude/` 配下の Markdown と `mockups/` の JSX、`docs/business_plan.docx`、`README.md` を GitHub Contents API 経由で一括 push するための **ドキュメント整備用スクリプト**。コードベース本体には触れない。

### 10.2 実行手順

```bash
# 必要: Python 3.10+ のみ（追加パッケージなし）
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxx
cd scripts
python3 push_shikigami_full.py
```

### 10.3 トークン権限

Personal Access Token（classic）の場合、`repo` スコープが必要。
Fine-grained PAT の場合は `okamuller/shikigami` への `Contents: Read and write`。

### 10.4 バイナリ参照

スクリプト内の `FILES` リストで `(repo_path, None, local_name)` 形式の行は、`local_name` を **スクリプトと同じディレクトリ** に置く必要がある（例: `shikigami_business_plan.docx`）。見つからなければ `⚠️ skip` 表示で続行する。

### 10.5 注意

- 既存ファイルがある場合は `sha` を取得して上書きコミットされる（履歴は残る）。
- main ブランチに直 push するので、レビューを通したい場合は `BRANCH` 定数を作業ブランチに変更すること。

---

## 11. ブランチ運用 / コミット規約

### 11.1 ブランチ

```
main              ← 常にデプロイ可能（保護ブランチ・直 push 禁止）
└─ feature/<topic>     ← 機能開発
└─ fix/<topic>         ← バグ修正
└─ docs/<topic>        ← ドキュメントのみ
└─ claude/<topic>      ← Claude による自動生成 PR
```

- すべて PR 経由で main へマージ。
- レビュー 1 名以上 + CI green が必須。
- スカッシュマージを既定とする。

### 11.2 コミットメッセージ（Conventional Commits）

```
<type>(<scope>): <subject>

<body>
```

| type | 用途 |
|---|---|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみ |
| `style` | フォーマット |
| `refactor` | 機能変更を伴わない整理 |
| `test` | テスト追加 / 修正 |
| `chore` | ビルド / 設定 / 依存更新 |

例:
```
feat(engine-a): 六壬神課の月将計算を実装
fix(paywall): 年額プランの価格表示が月額になっていた問題
docs(dev): DEVELOPMENT.md に CI 章を追加
```

---

## 12. テスト戦略

### 12.1 テストピラミッド

| 層 | フレームワーク | 対象 | カバレッジ目標 |
|---|---|---|---|
| Unit | XCTest | Engines/, Models/ | 90% |
| Snapshot | swift-snapshot-testing | DesignSystem, 主要画面 | 主要画面 100% |
| UI / E2E | XCUITest | オンボーディング・課金 | クリティカルパス 100% |
| バックエンド | Deno test | Edge Functions | 80% |

### 12.2 占術エンジンは決定論テスト必須

`SeimeiEngine.calc(year:1990, month:5, day:15)` のような **既知入力 → 期待値** のテーブルを `EngineGoldenTests.swift` に固定値で並べる。ロジック改修時のリグレッションを確実に検知する。

### 12.3 Claude API はモック

`ClaudeClient` をプロトコル化し、テストでは固定文字列を返すスタブを注入。実 API はステージング用の `INTEGRATION_TEST=1` 環境変数下でのみ叩く。

---

## 13. CI / CD

### 13.1 `.github/workflows/ios.yml`（雛形）

```yaml
name: iOS
on:
  push:
    branches: [main, "feature/**", "fix/**"]
  pull_request:

jobs:
  build-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "15.4"
      - run: |
          cd ios
          xcodebuild -scheme Shikigami \
            -destination "platform=iOS Simulator,name=iPhone 15" \
            clean test
```

### 13.2 TestFlight 配布

- `main` への push で fastlane `match` → `gym` → `pilot` を自動実行。
- 内部テスター（チーム）は即配布、外部テスターは手動承認。

### 13.3 Markdown / Swift Lint

```yaml
name: Lint
on: [pull_request]
jobs:
  markdown:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DavidAnson/markdownlint-cli2-action@v15
  swift:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: brew install swiftlint && swiftlint --strict
```

---

## 14. リリースプロセス

### 14.1 バージョニング

- SemVer ライク: `<Marketing>.<Minor>.<Patch>` 例 `1.2.3`
- ビルド番号は CI が自動採番（`yyyyMMddHHmm`）

### 14.2 リリース手順

1. `main` に release commit（`chore(release): v1.2.0`）
2. Git タグ `v1.2.0` を打つ
3. GitHub Releases にリリースノート生成（Conventional Commits から自動生成）
4. fastlane が TestFlight へアップロード
5. QA OK → App Store Connect で本番審査提出
6. 審査通過後、段階的リリース（10% → 50% → 100%）

### 14.3 App Store 審査チェックリスト

- 解約導線が「設定 > サブスクリプション」へのリンク付きで明示されている
- 「無料」表記の使い方が EULA に沿っている
- 占い結果に医療・投資のアドバイスを含めない（ガイドライン 1.4.1）
- プライバシーラベル（顔写真の扱い・ローカル処理である旨）が正確
- 14 日以内に再審査用ビルドを返せるよう審査担当を 1 名アサイン

---

## 15. コーディング規約

### 15.1 Swift

- SwiftLint 既定 + 以下を追加:
  - 行幅 120 まで
  - `force_unwrapping` は `// swiftlint:disable:next force_unwrapping` のコメント付き理由必須
- View / ViewModel / Model の三層を `Features/<画面>/` 配下に集約
- `@Observable` を採用（iOS 17 以降前提）

### 15.2 JavaScript (mockups)

- 関数コンポーネント + Hooks のみ
- インラインスタイル可（モックなので Tailwind 不要のものもある）
- 1 ファイル 1 体験。再利用は意図せず、見せる/いじることを優先

### 15.3 Markdown

- markdownlint デフォルトに準拠
- 表は GitHub Flavored Markdown
- 絵文字は装飾目的の使用を避け、UI ラベルや状態表示にのみ使う

---

## 16. セキュリティと法務

### 16.1 セキュリティ

- API キーは Edge Functions に閉じ込め、クライアントにバンドルしない
- Supabase は **RLS を必ず有効化**。`auth.uid() = user_id` ポリシーを全テーブルに
- 顔画像はデバイス外に出さない（Vision はオンデバイス）
- 依存パッケージは Dependabot で週次更新

### 16.2 法務

- **景品表示法**: 「必ず当たる」「確実に」等の断定表現は禁止。`.claude/E_bizplan.md` 7. リスクの「景表法・特商法」を遵守
- **特定商取引法**: アプリ内で事業者表記・解約方法・自動更新条件を明示
- **薬機法**: 健康・医療領域での効能効果の謳いを避ける
- **プライバシーポリシー**: 顔写真の処理がオンデバイスである旨を明記
- リリース前に必ず弁護士レビューを通す（初版・規約改訂時）

---

## 17. 実装ロードマップ（チケット粒度）

### Phase 1: MVP（Month 1〜3 / DL 1,000）

- [ ] `ios/` Xcode プロジェクト雛形（SwiftUI / iOS 17 ターゲット）
- [ ] DesignSystem（カラー・タイポ・五芒星 SVG コンポーネント）
- [ ] オンボーディング 5 ステップ（`.claude/D_screens.md` Flow 1）
- [ ] ENGINE A 実装 + ユニットテスト
- [ ] Supabase スキーマ初版 + RLS
- [ ] Edge Function `claude-proxy`（晴明プロンプトのみ）
- [ ] ホーム画面・鑑定画面・結果画面
- [ ] RevenueCat 統合（Premium のみ）
- [ ] ペイウォール（`.claude/D_screens.md` Flow 3）
- [ ] TestFlight 配布
- [ ] App Store 申請

### Phase 2: 拡張（Month 4〜9 / DL 10,000・MRR ¥50万）

- [ ] 水野南北キャラ追加（プロンプト + UI 切替）
- [ ] ENGINE B Phase 1（スライダー入力）
- [ ] パーソナル記憶層（`fortunes` 履歴サマリ）
- [ ] 年額プラン
- [ ] プッシュ通知（毎朝の式神ひとこと）
- [ ] Apple Search Ads 出稿
- [ ] シェア用 OGP 画像自動生成（鑑定結果スクショ）

### Phase 3: スケール（Month 10〜18 / DL 50,000・MRR ¥300万）

- [ ] ENGINE B Phase 2（Vision Framework 観相）
- [ ] 手相 AI カメラ（Divine プラン）
- [ ] Android 版（Kotlin Multiplatform 検討）
- [ ] 友達招待 / K-Factor 施策
- [ ] PR / インフルエンサー施策

---

## 18. トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `xcodebuild` でコード署名失敗 | プロビジョニング未取得 | `fastlane match development` を再実行 |
| Claude API が 401 | Edge Function 内のキー未設定 | `supabase secrets set ANTHROPIC_API_KEY=...` |
| RLS で SELECT が空配列 | ポリシー未設定 | `auth.uid() = user_id` ポリシーを追加 |
| プッシュ通知が届かない | APNs 証明書失効 | Apple Developer Portal で再生成 |
| `push_shikigami_full.py` が 403 | PAT スコープ不足 | `repo` を付け直すか Fine-grained PAT の Contents 権限を確認 |
| Vision のランドマークが取れない | 顔が小さい / 暗い | ガイド枠表示と最低輝度判定でユーザーに再撮影を促す |

---

## 19. 用語集

| 用語 | 意味 |
|---|---|
| 六壬神課（りくじんしんか） | 中国・日本で発達した占術。式神（十二天将）を盤上に配置して占う |
| 十二天将 | 貴人 / 騰蛇 / 朱雀 / 六合 / 勾陳 / 青龍 / 天空 / 白虎 / 太常 / 玄武 / 太陰 / 天后 |
| 五行 | 木・火・土・金・水 |
| 観相学 | 顔や手の相から運命・性格を読み解く学問。水野南北が大成 |
| 節食開運 | 食を慎むことで運を開くという南北の中心思想 |
| 命式（めいしき） | 生年月日から導かれた占い盤の構成 |
| ペイウォール | 課金しないと閲覧できない有料エリア |
| K-Factor | 1 ユーザーが連れてくる平均ユーザー数。1 を超えると指数的に成長 |

---

## 20. 参考リンク

### 公式ドキュメント
- Apple — [SwiftUI](https://developer.apple.com/documentation/swiftui) / [Vision](https://developer.apple.com/documentation/vision)
- Anthropic — [Messages API](https://docs.anthropic.com/en/api/messages) / [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- Supabase — [Edge Functions](https://supabase.com/docs/guides/functions) / [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- RevenueCat — [iOS SDK](https://www.revenuecat.com/docs/getting-started/installation/ios)

### 占術監修参考
- 阿部泰山『六壬占法』
- 水野南北『相法修身録』
- 安倍泰親『占事略決』

---

> 本書は実装の進捗に合わせて随時更新する。設計仕様の変更は `.claude/` 側を更新し、実装手順の変更は本書を更新すること。  
> 不明点や追加すべき章があれば PR で `docs/DEVELOPMENT.md` を編集して提案してほしい。
