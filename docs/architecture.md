# アーキテクチャ — 式神鑑定

> 本書は「全体構造」「技術選定の理由」「重要な設計判断（ADR）」を扱う。

## Phase 1 方針

Phase 1 MVP は local-first 構成を採用する。

- Claude API は使用しない
- Supabase は使用しない
- 鑑定文はローカルテンプレート生成
- 履歴・キャッシュは SwiftData に保存
- 画像解析は Vision Framework によるオンデバイス処理
- 必要最小限の課金のみ StoreKit 2 で処理

詳細は `local-first-migration.md` を参照。

## システム全体図

```text
SwiftUI App
 ├─ Feature Layer
 ├─ Domain Layer
 │   ├─ SeimeiEngine
 │   ├─ PhysiognomyEngine
 │   └─ LocalFortuneGenerator
 ├─ Persistence Layer
 │   └─ SwiftData / SQLite
 ├─ Vision Framework
 └─ StoreKit 2
```

## 設計原則

1. 占術計算は純粋関数で実装
2. 鑑定生成は端末内で完結
3. ネットワーク未接続でも主要機能を維持
4. 個人情報と画像は端末外へ送信しない
5. クラウド依存は将来拡張時のみ導入

## 技術スタック

| レイヤー | 採用技術 | 理由 |
|---|---|---|
| UI | SwiftUI | iOS ネイティブ構成 |
| 占術計算 | Swift 純粋関数 | テスト容易性 |
| 鑑定生成 | LocalFortuneGenerator | コストゼロ運用 |
| 永続化 | SwiftData | ローカル完結 |
| 画像解析 | Vision Framework | オンデバイス処理 |
| 課金 | StoreKit 2 | 外部SaaS削減 |

## ADR-001: Local-first MVP を採用

- 判断: Phase 1 はクラウド依存を持たない
- 背景: 小規模開発における運用コスト・障害対応を削減したい
- 結果: オフライン動作・低コスト・実装単純化を優先

## ADR-002: 鑑定文はテンプレート生成

- 判断: Claude API を使用せず、ローカルテンプレートで生成
- 背景: API コスト・キー管理・レスポンス変動を排除
- 結果: 品質上限は下がるが高速・安定・無料運用が可能

## ADR-003: SwiftData を正式採用

- 判断: 履歴・キャッシュ・設定を SwiftData に保存
- 背景: Phase 1 にサーバ同期要件が存在しない
- 結果: DB サーバ運用不要
