# 開発ドキュメント — 式神鑑定 / SHIKIGAMI FORTUNE

実装担当者向けの開発ドキュメント群。
設計コンセプト・世界観・グロース戦略は `.claude/A_world_ui.md` 〜 `.claude/E_bizplan.md` に分離されている。

## ドキュメント一覧

| ファイル | 内容 | 主な対象読者 |
|---|---|---|
| [requirements.md](./requirements.md) | 要求仕様（機能要求・非機能要求・受け入れ基準） | PM・エンジニア・QA |
| [architecture.md](./architecture.md) | 全体アーキテクチャ・技術選定・ADR | エンジニア・テックリード |
| [design.md](./design.md) | 詳細設計（DB・API・占術エンジン・プロンプト） | エンジニア |
| [development.md](./development.md) | 開発環境セットアップ・ブランチ運用・コーディング規約 | エンジニア |
| [testing.md](./testing.md) | テスト戦略 | エンジニア・QA |
| [operations.md](./operations.md) | CI/CD・リリースプロセス・運用・トラブルシューティング | エンジニア・SRE |
| [security.md](./security.md) | セキュリティと法務（景表法・特商法・薬機法） | エンジニア・法務 |
| [roadmap.md](./roadmap.md) | Phase 1〜3 のチケット粒度ロードマップ | PM・エンジニア |
| [glossary.md](./glossary.md) | 用語集 | 全員 |
| [business_plan.docx](./business_plan.docx) | 事業計画書フル版 | 経営・投資家 |

## 役割分担の考え方

```
.claude/  →  「何を作るか（設計コンセプト）」
docs/     →  「どう作るか・どう運用するか（実装と運用）」
mockups/  →  「どう見えるか（インタラクティブモック）」
```

新しい仕様や設計の意思決定は `.claude/` 側を更新し、
実装手順や運用ルールの変更は `docs/` 側を更新すること。

> 注: `mockups/*.jsx` と `docs/business_plan.docx` は本リポジトリにはまだ含まれていない。
> `scripts/push_shikigami_full.py` 経由で別途追加される予定。docs 側のリンクは追加後に有効化される。

## 読む順序

### 新規参加エンジニア
1. ルートの `README.md` で全体像
2. `.claude/A_world_ui.md` で世界観
3. `requirements.md` で要件
4. `architecture.md` で構成
5. `development.md` で環境構築

### 機能追加担当
1. `requirements.md` で対象要件
2. `design.md` で関連設計
3. `testing.md` でテスト方針

### リリース担当
1. `operations.md`
2. `security.md`
