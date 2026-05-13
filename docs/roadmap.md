# ロードマップ — 式神鑑定

> Phase ごとのチケット粒度ロードマップ。  
> KPI 目標と市場戦略は `.claude/E_bizplan.md` を、要求仕様は [requirements.md](./requirements.md) を参照。

## サマリー

| Phase | 期間 | 目標 |
|---|---|---|
| Phase 1 | Month 1〜3 | MVP・App Store 申請 → 1,000 DL |
| Phase 2 | Month 4〜9 | 南北追加・サブスク本実装 → 10,000 DL・MRR ¥50 万 |
| Phase 3 | Month 10〜18 | 手相 AI カメラ・Android → 50,000 DL・MRR ¥300 万 |

## Phase 1: MVP（Month 1〜3 / DL 1,000）

### 開発
- [ ] `ios/` Xcode プロジェクト雛形（SwiftUI / iOS 17 ターゲット）
- [ ] DesignSystem（カラー・タイポ・五芒星 SVG コンポーネント）
- [ ] オンボーディング 5 ステップ（[design.md §3](./design.md#3-占術エンジン) / `.claude/D_screens.md` Flow 1）
- [ ] ENGINE A（六壬神課）実装 + 決定論ユニットテスト
- [ ] Supabase スキーマ初版 + RLS
- [ ] Edge Function `claude-proxy`（晴明プロンプトのみ）
- [ ] ホーム画面・鑑定画面・結果画面
- [ ] RevenueCat 統合（Premium のみ）
- [ ] ペイウォール（`.claude/D_screens.md` Flow 3）

### 配布
- [ ] TestFlight 内部配布
- [ ] App Store 申請（解約導線・特商法表記・プライバシーラベル）
- [ ] LP（ストア外）公開

### マーケ
- [ ] TikTok 開始（週 4 本投稿カレンダー）
- [ ] ASO スクショ 5 枚作成

### 受け入れ基準
- すべての MUST 要求（FR-ON / FR-FT / FR-PY-01,04,06）が緑
- クラッシュフリー率 99.5% 以上（TestFlight 1 週間）
- 占術監修者レビュー通過
- 法務レビュー通過

## Phase 2: 拡張（Month 4〜9 / DL 10,000・MRR ¥50 万）

### 開発
- [ ] 水野南北キャラ追加（プロンプト + UI 切替）
- [ ] ENGINE B Phase 1（スライダー入力）
- [ ] ENGINE D（パーソナル記憶層）
- [ ] 年額プラン ¥3,800
- [ ] プッシュ通知（毎朝の式神ひとこと）
- [ ] シェア用 OGP 画像自動生成
- [ ] アカウント削除フロー

### マーケ
- [ ] Apple Search Ads 出稿
- [ ] Instagram Reels 並行投稿
- [ ] 占い系インフルエンサーへの試験タイアップ

### 受け入れ基準
- DAU 2,000 / Day7 RR 12%
- MRR ¥50 万到達
- ASO 主要 5 ワードで Top 10

## Phase 3: スケール（Month 10〜18 / DL 50,000・MRR ¥300 万）

### 開発
- [ ] ENGINE B Phase 2（Vision Framework 観相）
- [ ] 手相 AI カメラ（Divine プラン・¥480 都度課金）
- [ ] Android 版（Kotlin Multiplatform 検討）
- [ ] 友達招待 / K-Factor 施策
- [ ] 解約フロー内「50% OFF オファー」

### マーケ
- [ ] PR / プレスリリース
- [ ] インフルエンサー本格展開

### 受け入れ基準
- 累計 DL 50,000
- 課金転換率 2.5%
- MRR ¥300 万

## チケット運用

- GitHub Issues で 1 機能 = 1 Issue
- Phase ラベル: `phase-1` `phase-2` `phase-3`
- 種別ラベル: `feature` `bug` `chore` `docs`
- マイルストーン: `v0.1.0` `v0.2.0` ... をリリース計画と紐付け
- 進捗ボードは GitHub Projects（Beta）

## 関連ドキュメント

- 要求仕様: [requirements.md](./requirements.md)
- 詳細設計: [design.md](./design.md)
- 事業計画フル版: `business_plan.docx`
- グロース戦略: `.claude/C_growth.md`
