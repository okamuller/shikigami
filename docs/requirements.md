# 要求仕様 — 式神鑑定

> 本書はプロダクトの「何を実現するか」を定義する。  
> 実装の「どう実現するか」は [design.md](./design.md) と [architecture.md](./architecture.md) に分離されている。

## 1. プロジェクト目的

平安時代の陰陽師・安倍晴明と江戸の観相家・水野南北をモチーフにした、
local-first な占いアプリを提供する。

- 「運命を知る（晴明）× 運命を変える（南北）」を体験価値の核とする
- Phase 1 MVP では外部バックエンド運用を持たず、月額運用コストを極小化する
- 詳細な local-first 移行方針は [local-first-migration.md](./local-first-migration.md) を参照

## 2. ステークホルダー

| 役割 | 関心事 |
|---|---|
| エンドユーザー | 当たる/刺さる占い結果、心地よい体験、オフラインでも動く安心感 |
| 開発チーム | 仕様の明確さ、保守性、テスト可能性、低運用コスト |
| 経営 / 投資家 | KPI（DL・DAU・MRR・課金転換率）、コスト |
| Apple 審査 | App Store ガイドライン適合、解約導線、表示の正確性 |
| 法務 | 景表法・特商法・薬機法・プライバシー |

## 3. 機能要求（FR）

各要求には ID と優先度（MUST / SHOULD / COULD）を付与する。  
既存 ID はロードマップ・受け入れ基準・テストトレースとの互換性のため、意味を変更しない。

### 3.1 オンボーディング

| ID | 要求 | 優先度 | 備考 |
|---|---|---|---|
| FR-ON-01 | 5 ステップで初期設定が完了する | MUST | `.claude/D_screens.md` Flow 1 |
| FR-ON-02 | 生年月日・性別（陰/陽/未回答）・悩みカテゴリを入力できる | MUST | ローカル `UserProfile` に保存 |
| FR-ON-03 | 最後に式神を即座に計算して提示する | MUST | 信頼感の演出として必須 |
| FR-ON-04 | 完了率 70% 以上を達成するフロー設計 | SHOULD | KPI |

### 3.2 鑑定機能

| ID | 要求 | 優先度 | 備考 |
|---|---|---|---|
| FR-FT-01 | 安倍晴明キャラで鑑定文を生成できる | MUST | Phase 1。local-first 版では `LocalFortuneGenerator` で生成 |
| FR-FT-02 | 水野南北キャラで鑑定文を生成できる | MUST | Phase 2。テンプレートセットを追加 |
| FR-FT-03 | 悩みカテゴリ（恋愛・仕事・金運・健康・家庭・運命）を選択できる | MUST | カテゴリ別テンプレートに反映 |
| FR-FT-04 | 鑑定文は 200 文字以内・文語体（晴明）または江戸口語体（南北） | MUST | テンプレート規則で制御 |
| FR-FT-05 | 鑑定履歴を保存し過去結果を閲覧できる | SHOULD | Phase 1 では SwiftData の `FortuneRecord` に保存 |
| FR-FT-06 | 「今日の天命」が毎朝ホームに表示される | SHOULD | ローカル日付 seed で生成。通知連動は別途検討 |

### 3.3 占術エンジン

> 凡例: 「ロールアウト Phase」はリリース計画上のフェーズ（[roadmap.md](./roadmap.md)）。エンジンの実装バリアントは「ENGINE 名」で表記する。

| ID | 要求 | 優先度 | エンジン実装 | ロールアウト Phase |
|---|---|---|---|---|
| FR-EN-01 | 六壬神課で式神（十二天将）・干支・五行・スコアを算出 | MUST | ENGINE A | Phase 1 |
| FR-EN-02 | 観相エンジンでスライダー入力から所見を生成 | SHOULD | ENGINE B Slider | Phase 2 |
| FR-EN-02b | 観相エンジンで Vision Framework により所見を生成 | COULD | ENGINE B Vision | Phase 3 |
| FR-EN-03 | 手相 AI カメラで 5 線（生命・感情・頭脳・運命・財運）をスコア化 | COULD | ENGINE B-Palm | Phase 3 |
| FR-EN-04 | 履歴を踏まえたパーソナル鑑定文を生成 | SHOULD | ENGINE D | Phase 2。local-first 版では直近履歴の簡易要約を利用 |

### 3.4 課金

| ID | 要求 | 優先度 | 備考 |
|---|---|---|---|
| FR-PY-01 | FREE / PREMIUM(¥480/月) / DIVINE(¥480〜980/回) の 3 ティア | MUST | Phase 1 では StoreKit 2 直利用を基本とする |
| FR-PY-02 | 年額プラン ¥3,800 を提供 | SHOULD | Phase 2 |
| FR-PY-03 | 2 週間無料トライアル | SHOULD | StoreKit 2 の introductory offer で検討 |
| FR-PY-04 | ペイウォール（無料部分 → ぼかし → 課金ボタン） | MUST | `.claude/D_screens.md` Flow 3 |
| FR-PY-05 | 解約フロー内で「1 ヶ月 50% OFF」オファーを提示 | COULD | チャーン抑制 |
| FR-PY-06 | RevenueCat を介した購入状態の同期 | MUST | 旧方針。local-first Phase 1 では `LF-PY-01` を優先し、本IDはクラウド課金管理を導入する段階で再評価 |

### 3.5 通知 / シェア

| ID | 要求 | 優先度 | 備考 |
|---|---|---|---|
| FR-NT-01 | 毎朝 7〜9 時に「今日の式神ひとこと」をプッシュ通知 | SHOULD | local notification で実装可能 |
| FR-NT-02 | 鑑定結果から OGP 画像を生成しシェア | SHOULD | UGC 創出 |
| FR-NT-03 | 友達招待で 30 日延長 | COULD | K-Factor 向上。サーバ管理が必要なら将来対応 |

## 4. Local-first 追加要求（LF）

local-first 化で追加する要件は既存 FR/NFR ID を再利用せず、`LF-*` として定義する。

| ID | 要求 | 優先度 | 備考 |
|---|---|---|---|
| LF-GEN-01 | Claude API を使わず、端末内テンプレートで鑑定文を生成できる | MUST | `LocalFortuneGenerator` |
| LF-DB-01 | ユーザー設定・鑑定履歴・キャッシュを SwiftData に保存できる | MUST | `UserProfile` / `FortuneRecord` |
| LF-CACHE-01 | 同一入力ではローカルキャッシュ済み鑑定を返せる | MUST | `inputHash` 検索 |
| LF-NET-01 | Phase 1 の主要鑑定フローはネットワーク接続なしで完了する | MUST | 機内モードテスト対象 |
| LF-PY-01 | Phase 1 の課金状態は StoreKit 2 の entitlement で判定する | SHOULD | RevenueCat なし |
| LF-CLOUD-01 | Supabase / Claude / RevenueCat は Phase 1 の必須依存にしない | MUST | 将来拡張として再導入可 |

## 5. 非機能要求（NFR）

既存 NFR ID も意味を変更しない。local-first 化による補足は備考で扱う。

| ID | 要求 | 計測方法 / 目標値 |
|---|---|---|
| NFR-PF-01 | 鑑定文生成は p95 で 3 秒以内 | local-first 版では p95 2 秒以内を目標 |
| NFR-PF-02 | アプリ起動から鑑定開始まで 2 秒以内 | 計測 SDK / ローカル計測 |
| NFR-OF-01 | Claude API 障害時もテンプレートで鑑定文を返す | local-first 版では Claude 依存がないため、テンプレ生成失敗時のフォールバックを検証 |
| NFR-OF-02 | オフライン時も六壬神課の式神結果は表示できる | 機内モードテスト |
| NFR-PR-01 | 顔・手の写真は端末外に送信しない | コードレビュー + 通信ログ |
| NFR-PR-02 | プライバシーポリシーで全データ取扱いを開示 | 法務レビュー |
| NFR-AV-01 | App Store 公開後の月間稼働率 99.9% 以上 | local-first 版では外部SLA依存を持たない |
| NFR-AC-01 | iOS 17 以降をサポート | 動作確認 |
| NFR-CO-01 | 1 鑑定あたり Claude コスト 1 円未満 | local-first 版では Claude コスト 0 円を目標 |
| NFR-LN-01 | 多言語化を前提とした文字列分離（初期は日本語のみ） | `Localizable.strings` |

## 6. 主要ユースケース

### UC-1: 新規ユーザーが初めて鑑定する

1. アプリを起動
2. オンボーディング 5 ステップを完了（FR-ON-01〜03）
3. ホームで「晴明」を選択
4. 悩みカテゴリを選び、自由テキストで質問
5. 「式神を放つ」ボタン → local-first 鑑定文が表示（FR-FT-01 / LF-GEN-01）
6. 末尾にペイウォール → 「天命の続きを見る」ボタン

### UC-2: 既存ユーザーが詳細鑑定を見る

1. ホームの「今日の天命」をタップ
2. 続きを見るためにサブスク登録 → StoreKit 2 経由（FR-PY-01 / LF-PY-01）
3. 解放された詳細鑑定書を閲覧

### UC-3: 手相 AI を試す（Phase 3）

1. ホーム → 「手相 AI」
2. 撮影 → 端末上で 5 線スコアを算出（FR-EN-03 / NFR-PR-01）
3. ¥480 都度課金 → 南北の所見を表示

### UC-4: オフライン時の挙動

1. 端末が機内モード
2. ENGINE A の結果とローカルテンプレートから鑑定文を生成（LF-NET-01）
3. 履歴とキャッシュを SwiftData に保存（LF-DB-01）

## 7. 制約と前提

- 提供 OS: iOS 17 以降（Android は Phase 3 以降）
- 開発体制: 小規模スタートアップ（iOS 1 / デザイン 1 を想定）
- Phase 1 では外部バックエンド運用を前提にしない
- 占術監修: 専門家レビューを Phase 1 リリース前に最低 1 回
- 法務レビュー: 規約・LP・アプリ内表現の初版を法務確認

## 8. 受け入れ基準（Acceptance Criteria）

各 FR / LF について最低 1 件のテストケースを `testing.md` で定義する。
リリース判定は以下のチェックリストを通過すること。

- [ ] すべての MUST 要求がユニット / E2E テストで検証済み
- [ ] App Store ガイドライン（解約導線・自動更新表記）を満たす
- [ ] プライバシーラベルが実装と一致
- [ ] 占術監修者の最終レビューを通過
- [ ] 法務レビューを通過
- [ ] クラッシュフリー率 99.5% 以上（TestFlight 1 週間）
- [ ] local-first 追加要求（LF-*）の MUST が検証済み

## 9. 関連ドキュメント

- アーキテクチャ判断: [architecture.md](./architecture.md)
- データモデル・API: [design.md](./design.md)
- Local-first 移行方針: [local-first-migration.md](./local-first-migration.md)
- テスト戦略: [testing.md](./testing.md)
- ロードマップ: [roadmap.md](./roadmap.md)
