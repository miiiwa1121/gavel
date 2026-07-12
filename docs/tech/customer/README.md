# tech/customer — 供給側（消費者）プロダクト/技術

> **要約**: 本プラットフォームの**供給側＝一般消費者向けデータ収集アプリ（C側アプリ）**のプロダクト・技術設計を置く領域。**要件定義＋ iOS v1 実装（オンボーディング/ミッション/キャプチャ/貢献記録）に着手済み**。実装コードは [`Gavel/`](../../../Gavel/)、判断ログは [`../../devlog/2026-07.md`](../../devlog/2026-07.md)。

## このディレクトリのファイル

| ファイル | 内容 |
|----------|------|
| [`requirements.md`](./requirements.md) | **C側アプリの要件定義（正本）**。決定仕様・設計判断・未確定事項 |
| [`screens.md`](./screens.md) | 画面一覧・画面遷移（実装状況つき） |
| [`device-smoke-test.md`](./device-smoke-test.md) | 実機 smoke test 手順（F-1・映像＋IMU実収録の検証） |

## このアプリの位置づけ

データを「出す」側＝スマホで手元動作を撮影・投稿する消費者アプリ。v1 は「**高品質サンプル100件を作り買い手に持ち込む**」ための最小構成（限定協力者・映像＋IMU・一人称マウント撮影）。詳細と確定事項は [`requirements.md`](./requirements.md) を参照。

## 関連

- 事業モデル上の役割・供給側の動機は [`../../biz/business-model.md`](../../biz/business-model.md)・[`../../biz/usecases.md`](../../biz/usecases.md)
- 取得データの技術的前提は [`../tech-notes.md`](../tech-notes.md)、データ構造は [`../data-model.md`](../data-model.md)
- 需要側（買い手向け）は [`../business/`](../business/)
