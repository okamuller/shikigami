# 運用 — 式神鑑定

> 本書は CI/CD・リリース・監視・障害対応を扱う。  
> セキュリティ運用は [security.md](./security.md) に分離されている。

## 1. CI / CD

### 1.1 `.github/workflows/ios.yml`（雛形）

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

### 1.2 Lint

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

### 1.3 TestFlight 配布

- `main` への push をトリガに、fastlane で `match` → `gym` → `pilot` を実行
- 内部テスター（チーム）には即配布、外部テスターは手動承認
- ビルド番号は CI が `yyyyMMddHHmm` で自動採番

## 2. リリースプロセス

### 2.1 バージョニング

- Marketing Version: SemVer ライク `<Major>.<Minor>.<Patch>` 例 `1.2.3`
- Build Number: `yyyyMMddHHmm`

### 2.2 リリース手順

1. `main` で `chore(release): v1.2.0` コミット
2. タグ `v1.2.0` を打って push
3. GitHub Releases にノート自動生成（Conventional Commits から）
4. fastlane が TestFlight へアップロード
5. QA 通過 → App Store Connect で本番審査提出
6. 審査通過後、段階的リリース（10% → 50% → 100%）

### 2.3 App Store 審査チェックリスト

- [ ] 解約導線が「設定 > サブスクリプション」へのリンク付きで明示
- [ ] 「無料」表記の使い方が EULA に沿っている（自動更新条件・解約方法を直近に明示）
- [ ] 占い結果に医療・投資のアドバイスを含めない（ガイドライン 1.4.1）
- [ ] プライバシーラベル（顔写真の扱い・ローカル処理である旨）が正確
- [ ] 14 日以内に再審査用ビルドを返せるよう審査担当を 1 名アサイン

## 3. 監視 / アラート

| 対象 | 監視ツール | 通知先 | しきい値 |
|---|---|---|---|
| iOS クラッシュ | Sentry | Slack #alerts | クラッシュ率 > 0.5% / 24h |
| Edge Functions エラー | Sentry | Slack #alerts | エラー率 > 1% / 5min |
| Anthropic API 5xx | Sentry | Slack #alerts | 連続 3 回失敗 |
| Supabase DB | Supabase Dashboard | メール | CPU > 80% / 10min 連続 |
| 課金イベント | RevenueCat | Slack #revenue | 解約スパイク（前日比 +50%） |
| コスト | 月次手動レビュー | Notion | Claude API > 月 ¥30,000 |

## 4. インシデント対応

### 4.1 重大度

| Sev | 定義 | 初動目標 |
|---|---|---|
| Sev 1 | アプリ起動不可・課金停止 | 15 分以内に対応開始 |
| Sev 2 | 鑑定生成が大量に失敗 | 1 時間以内 |
| Sev 3 | 一部機能不具合・KPI 異常 | 当日中 |

### 4.2 流れ

1. 検知（Sentry / ユーザー報告）
2. Slack `#incidents` にスレッド起票
3. インシデントコマンダーを 1 名指名
4. ロールバック / ホットフィックスを判断
5. 復旧後、ポストモーテムを 48 時間以内に作成（Notion テンプレ）

### 4.3 ロールバック

- TestFlight: 直前のビルドを再配布
- 本番 App Store: Phased Release を停止 + 旧バージョン互換のため Edge Function 側で API バージョン互換を保つ
- DB マイグレーション: `supabase db reset` は本番では禁止。必ず逆向きマイグレーションを用意

## 5. トラブルシューティング（FAQ）

| 症状 | 原因 | 対処 |
|---|---|---|
| `xcodebuild` でコード署名失敗 | プロビジョニング未取得 | `fastlane match development` を再実行 |
| Claude API が 401 | Edge Function 内のキー未設定 | `supabase secrets set ANTHROPIC_API_KEY=...` |
| RLS で SELECT が空配列 | ポリシー未設定 | `auth.uid() = user_id` ポリシーを追加 |
| プッシュ通知が届かない | APNs 証明書失効 | Apple Developer Portal で再生成 |
| `push_shikigami_full.py` が 403 | PAT スコープ不足 | `repo` を付け直すか Fine-grained PAT の Contents 権限を確認 |
| Vision のランドマークが取れない | 顔が小さい / 暗い | ガイド枠表示と最低輝度判定で再撮影を促す |
| 鑑定文に断定表現が出る | プロンプト準拠不足 | 役割プロンプトに「断定禁止」ルールを再注入・テンプレートで補完 |

## 6. コストガード

- 1 ユーザー / 1 日あたり Claude 呼び出し上限: 無料 5 / Premium 50 / Divine 無制限
- Edge Function で `users.tier` をチェックして 402 を返す
- Anthropic Console の Usage を週次で確認、月 ¥30,000 を超えそうならアラート

## 7. 関連ドキュメント

- リリース判定基準: [requirements.md §7](./requirements.md#7-受け入れ基準acceptance-criteria)
- テスト戦略: [testing.md](./testing.md)
- セキュリティ: [security.md](./security.md)
