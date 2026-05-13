# 開発ガイド — 式神鑑定

> 本書は環境構築・リポジトリ運用・コーディング規約を扱う。  
> アーキテクチャは [architecture.md](./architecture.md)、詳細設計は [design.md](./design.md)、テストは [testing.md](./testing.md)。

## 1. リポジトリ構成（実装後の目標）

```
shikigami/
├── README.md
├── .claude/                     # 設計コンセプト（A〜E）
├── docs/                        # 本書ほか開発ドキュメント
├── mockups/                     # JSX モックアップ
├── ios/                         # Phase 1 で作成
│   ├── Shikigami.xcodeproj
│   ├── Shikigami/
│   │   ├── App/
│   │   ├── Features/            # 画面単位
│   │   ├── Engines/             # 占術ロジック（純粋関数）
│   │   ├── Network/             # Claude / Supabase クライアント
│   │   ├── Models/
│   │   ├── DesignSystem/        # カラー・フォント・五芒星
│   │   └── Resources/
│   └── ShikigamiTests/
├── backend/                     # Phase 1 で作成
│   ├── supabase/
│   │   ├── functions/
│   │   │   ├── claude-proxy/
│   │   │   ├── fortune-cache/
│   │   │   └── revenuecat-webhook/
│   │   └── migrations/
│   └── README.md
├── scripts/
│   └── push_shikigami_full.py
└── .github/workflows/           # CI/CD（operations.md 参照）
```

`ios/` `backend/` `.github/` は本書執筆時点では未作成。Phase 1 着手時に上記構造で雛形を切ること。

## 2. 必須ツール

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

## 3. アカウント

- Apple Developer Program（有料・¥12,800/年）
- Anthropic Console（Claude API キー）
- Supabase（Hobby tier から開始可）
- RevenueCat（Free tier で MRR $10K まで）
- App Store Connect

## 4. 初回チェックアウト

```bash
git clone git@github.com:okamuller/shikigami.git
cd shikigami

# iOS（Phase 1 以降）
cd ios
open Shikigami.xcodeproj
# Xcode の Signing & Capabilities でチーム選択

# バックエンド（Phase 1 以降）
cd ../backend
supabase login
supabase link --project-ref <PROJECT_REF>
supabase db push
```

## 5. シークレット管理

詳細なルールは [security.md](./security.md) 参照。短いまとめ:

- ローカル: `.env.local` / `xcconfig`（gitignore 済み）
- CI/CD: **GitHub Secrets**
- Claude API キーは **Edge Functions のみ** に置く。クライアントにバンドルしない。

## 6. ブランチ運用

```
main              ← 常にデプロイ可能（保護ブランチ・直 push 禁止）
└─ feature/<topic>     ← 機能開発
└─ fix/<topic>         ← バグ修正
└─ docs/<topic>        ← ドキュメントのみ
└─ claude/<topic>      ← Claude による自動生成 PR
```

- すべて PR 経由で main へマージ
- レビュー 1 名以上 + CI green が必須
- スカッシュマージを既定とする

## 7. コミット規約（Conventional Commits）

```
<type>(<scope>): <subject>

<body>
```

| type | 用途 |
|---|---|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみ |
| `style` | フォーマットのみ |
| `refactor` | 機能変更を伴わない整理 |
| `test` | テスト追加 / 修正 |
| `chore` | ビルド / 設定 / 依存更新 |

例:
```
feat(engine-a): 六壬神課の月将計算を実装
fix(paywall): 年額プランの価格表示が月額になっていた問題
docs(dev): development.md にブランチ運用を追加
```

## 8. コーディング規約

### 8.1 Swift

- SwiftLint 既定 + 行幅 120
- `force_unwrapping` は `// swiftlint:disable:next force_unwrapping` のコメント付き理由必須
- View / ViewModel / Model の三層を `Features/<画面>/` 配下に集約
- `@Observable` を採用（iOS 17 以降前提）
- プロトコル経由のインジェクションで `Network/` の実装をテスト時に差し替える

### 8.2 JavaScript（mockups）

- 関数コンポーネント + Hooks のみ
- インラインスタイル可
- 1 ファイル 1 体験。再利用は意図しない（モック）

### 8.3 Markdown

- markdownlint デフォルトに準拠
- 表は GitHub Flavored Markdown
- 絵文字は UI ラベルや状態表示にのみ使用

## 9. モックアップの動かし方

### 9.1 claude.ai の Artifact（最速）

`mockups/0X_*.jsx` の全文をコピー → claude.ai に貼って「Artifact で表示して」。
インタラクティブにレビュー可能。

### 9.2 ローカル React

```bash
npx create-react-app shikigami-demo
cd shikigami-demo
npm install lucide-react
cp ../shikigami/mockups/01_world_ui.jsx src/App.jsx
npm start
```

Tailwind を使う JSX は別途 `tailwindcss` の導入が必要（ファイル冒頭コメント参照）。

## 10. `push_shikigami_full.py`

`.claude/` `mockups/` `docs/business_plan.docx` `README.md` を GitHub Contents API 経由で一括 push するためのドキュメント整備スクリプト。コードベース本体には触れない。

```bash
export GITHUB_TOKEN=ghp_xxxx
cd scripts
python3 push_shikigami_full.py
```

- PAT 権限: `repo` または Fine-grained PAT で `Contents: Read and write`
- バイナリ（`shikigami_business_plan.docx`）はスクリプトと同ディレクトリに配置
- 既存ファイルは `sha` を取得して上書きコミット（履歴は残る）
- main へ直 push なので、レビューを通したい場合は `BRANCH` 定数を変更

## 11. 関連ドキュメント

- 要求仕様: [requirements.md](./requirements.md)
- アーキテクチャ: [architecture.md](./architecture.md)
- 詳細設計: [design.md](./design.md)
- テスト: [testing.md](./testing.md)
- 運用: [operations.md](./operations.md)
- セキュリティ: [security.md](./security.md)
