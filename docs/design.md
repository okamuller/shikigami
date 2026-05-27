# 詳細設計 — 式神鑑定

## Phase 1 MVP

Phase 1 は local-first 構成を採用する。

- Claude API 不使用
- Supabase 不使用
- SwiftData によるローカル保存
- テンプレートベースの鑑定生成
- Vision Framework によるオンデバイス解析

## データモデル

### SwiftData

```swift
@Model
final class UserProfile {
    var localUserId: UUID
    var birthDate: Date
    var gender: String
    var shikigamiId: Int
}

@Model
final class FortuneRecord {
    var id: UUID
    var engine: String
    var topic: String
    var inputHash: String
    var response: String
    var createdAt: Date
}

@Model
final class SubscriptionSnapshot {
    var tier: String
    var expiresAt: Date?
}
```

## キャッシュ

`LocalFortuneGenerator` はプロフィール要素と履歴補正を利用して文章を生成するため、キャッシュキーにも同一入力を含める。

```text
SHA256(
  localUserId +
  engine +
  topic +
  normalize(question) +
  shikigamiId +
  gogyo +
  scoreBand +
  historySummaryHash +
  dateJst
)
```

### キャッシュキー要素

| 要素 | 理由 |
|---|---|
| shikigamiId | 式神別文が変化するため |
| gogyo | 五行別補正文が変化するため |
| scoreBand | スコア帯別文が変化するため |
| historySummaryHash | 履歴補正文が変化するため |
| dateJst | 今日の運勢を日次更新するため |

同一キーが存在する場合のみローカルキャッシュを返す。
履歴追加によって `historySummaryHash` が変化した場合は再生成される。

## 鑑定生成

```swift
protocol FortuneTextGenerator {
    func generate(request: FortuneRequest) async throws -> FortuneResponse
}
```

`LocalFortuneGenerator` が以下を組み合わせて文章生成する。

- 式神別文
- 五行別文
- スコア帯別文
- 悩みカテゴリ別文
- 履歴補正文

## ENGINE A

六壬神課ロジックは従来通り Swift 純粋関数で維持する。

## ENGINE B

Vision Framework を用いた観相分析を維持する。

- 画像保存禁止
- ネットワーク送信禁止
- メモリ上のみ解析

## 課金

RevenueCat は Phase 1 では使用しない。

StoreKit 2 の `Transaction.currentEntitlements` を参照し、ローカルで課金状態を判定する。

## エラー処理

| 状態 | 処理 |
|---|---|
| 通常 | LocalFortuneGenerator |
| オフライン | 通常動作 |
| キャッシュヒット | ローカルDB返却 |
| 生成失敗 | フォールバックテンプレ |

## 将来拡張

クラウド導入時も以下の抽象境界を維持する。

- FortuneTextGenerator
- FortuneRepository
- EntitlementProvider
