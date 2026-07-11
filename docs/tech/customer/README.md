# tech/customer — 供給側（消費者）プロダクト/技術

> **要約**: 本プラットフォームの**供給側＝一般消費者向けデータ収集アプリ（C側アプリ）**のプロダクト・技術設計を置く領域。**要件定義に着手済み**。

## このディレクトリのファイル

| ファイル | 内容 |
|----------|------|
| [`requirements.md`](./requirements.md) | **C側アプリの要件定義（正本）**。決定仕様・設計判断・未確定事項 |
| `screens.md`（未作成） | 画面一覧・画面遷移（要件が固まり次第、requirements から分離） |

## このアプリの位置づけ

データを「出す」側＝スマホで手元動作を撮影・投稿する消費者アプリ。v1 は「**高品質サンプル100件を作り買い手に持ち込む**」ための最小構成（限定協力者・映像＋IMU・一人称マウント撮影）。詳細と確定事項は [`requirements.md`](./requirements.md) を参照。

## 関連

- 事業モデル上の役割・供給側の動機は [`../../biz/business-model.md`](../../biz/business-model.md)・[`../../biz/usecases.md`](../../biz/usecases.md)
- 取得データの技術的前提は [`../tech-notes.md`](../tech-notes.md)、データ構造は [`../data-model.md`](../data-model.md)
- 需要側（買い手向け）は [`../business/`](../business/)
