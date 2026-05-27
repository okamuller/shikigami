# テスト戦略 — 式神鑑定

> 本書はテストの方針と粒度を扱う。  
> 受け入れ基準のチェックリストは [requirements.md §7](./requirements.md#7-受け入れ基準acceptance-criteria) に分離されている。

## 1. テストピラミッド

| 層 | フレームワーク | 対象 | カバレッジ目標 |
|---|---|---|---|
| Unit | XCTest | `Engines/`, `Models/` | 90% |
| Snapshot | swift-snapshot-testing | `DesignSystem/`, 主要画面 | 主要画面 100% |
| UI / E2E | XCUITest | オンボーディング・課金 | クリティカルパス 100% |
| バックエンド | Deno test | Edge Functions | 80% |

## 2. 占術エンジンは決定論テスト必須

`SeimeiEngine.calc(year: 1990, month: 5, day: 15)` のような **既知入力 → 期待値** のテーブルを `EngineGoldenTests.swift` に固定値で並べる。ロジック改修時のリグレッションを確実に検知する。

```swift
final class EngineGoldenTests: XCTestCase {
    func test_known_dates() {
        let cases: [(Int, Int, Int, Meishiki)] = [
            (1990, 5, 15, .init(...)),
            (2000, 2, 29, .init(...)),
            (1921, 2, 21, .init(...)),  // 安倍晴明の伝承上の誕生日
        ]
        for (y, m, d, expected) in cases {
            XCTAssertEqual(SeimeiEngine.calc(year: y, month: m, day: d), expected)
        }
    }
}
```

### プロパティテスト

スコアが常に `60..<100` に収まることを `XCTAssert` でランダム入力検証（year 1900〜2100、month 1〜12、day 1〜28）。

## 3. Claude API はモック

`ClaudeClient` をプロトコル化し、テストでは固定文字列を返すスタブを注入。

```swift
struct StubClaudeClient: ClaudeClient {
    let canned: String
    func generate(request: FortuneRequest) async throws -> FortuneResponse {
        .init(text: canned, cached: false, tokens: .init(input: 0, output: 0))
    }
}
```

実 API はステージング用の `INTEGRATION_TEST=1` 環境変数下でのみ叩く。

## 4. スナップショットテスト

- DesignSystem の主要ビュー（五芒星・キャラカード・ペイウォール）について明るさ/ダークの 2 パターンを保存
- 仕様変更時はスナップショットを再生成し、PR レビューで差分確認

## 5. UI / E2E テスト

最低限カバーする「クリティカルパス」:

1. **オンボーディング完走**: 起動 → 5 ステップ完了 → ホーム到達
2. **無料鑑定 → ペイウォール表示**: ホーム → 鑑定 → ペイウォール
3. **課金成功**: ペイウォール → サンドボックス購入 → 機能解放
4. **オフライン挙動**: 機内モードで起動 → ENGINE A 結果が見える

## 6. バックエンドテスト

```bash
cd backend/supabase/functions
deno test --allow-env --allow-net
```

- `claude-proxy` のキャッシュ分岐
- レート制限の挙動
- RevenueCat Webhook 署名検証

## 7. 受け入れテスト（QA）

`requirements.md` の各 MUST 要求について、テスト ID を 1 件以上紐付ける。
QA はリリースごとに以下のスプレッドシートを更新する（テンプレは別途）。

| 要求 ID | テスト ID | 自動 / 手動 | 状態 |
|---|---|---|---|
| FR-ON-01 | E2E-01 | 自動 | passed |
| FR-FT-01 | UT-engineA-01 | 自動 | passed |
| FR-PY-04 | E2E-02 | 自動 | passed |
| FR-NT-01 | UT-dailyNotification-01 | 自動 | passed |
| NFR-PR-01 | MAN-01 | 手動 | passed |
| ... | ... | ... | ... |

## 8. パフォーマンステスト

- 鑑定 API の p95 レイテンシを Sentry Performance で計測
- リリース前に `xcrun xctest -benchmark` で `SeimeiEngine.calc` が 1µs オーダーであることを確認

## 9. 関連ドキュメント

- 要求仕様: [requirements.md](./requirements.md)
- 詳細設計: [design.md](./design.md)
- CI 設定: [operations.md](./operations.md)
