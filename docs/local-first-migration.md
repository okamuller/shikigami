# Local-first 移行方針 — 式神鑑定

## 目的

Phase 1 MVP では Claude API / Supabase / RevenueCat への依存を外し、iOS アプリ単体で鑑定生成・履歴保存・キャッシュ・課金判定を完結させる。

主目的は以下の通り。

- 月額運用コストを極小化する
- バックエンド運用、API キー管理、障害対応を削減する
- オフラインでも主要体験を成立させる
- App Store 審査時のデータ取扱い説明を簡素化する

## 移行後アーキテクチャ

```text
SwiftUI App
 ├─ Engines
 │   ├─ SeimeiEngine
 │   ├─ PhysiognomyEngine
 │   └─ LocalFortuneGenerator
 ├─ Persistence
 │   └─ SwiftData / SQLite
 ├─ Vision Framework
 └─ StoreKit 2
```

## LocalFortuneGenerator

```swift
protocol FortuneTextGenerator {
    func generate(request: FortuneRequest) async throws -> FortuneResponse
}
```

テンプレート生成は以下を組み合わせる。

- 式神別ベース文
- 五行別補正文
- 悩みカテゴリ別文
- スコア帯別文
- 日付 seed による表現ゆらぎ
- 履歴要約による軽量パーソナライズ

## ローカル保存

SwiftData に以下を保持する。

- UserProfile
- FortuneRecord
- SubscriptionSnapshot

キャッシュキーは SHA256(localUserId, engine, topic, normalizedQuestion, dateJst) を使用する。

## 将来のクラウド復帰条件

以下が必要になった場合のみクラウド機能を追加する。

- 複数端末同期
- AI 生成の有料化
- 高度な分析
- サーバ側課金検証
- コミュニティ機能
