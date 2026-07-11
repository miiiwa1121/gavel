# ドキュメント案内 - gavel

> **要約**: docs/ 配下の読み方ガイド。docs 直下は **biz（事業戦略・分析）／ tech（技術・プロダクト）／ devlog（作業ログ）** の3領域に分かれる。目的別ナビゲーション表でどのファイルを読むべきか引ける。どこに何の資料があるか分からないとき最初に読む。
>
> 事業自体の概要は [`biz/concept.md`](./biz/concept.md) を参照。

## 現在のステータス

**企画・調査フェーズ**。事業要件・市場・競合・技術・業界の分析が一巡し、docs にまとめた段階。**プロダクト実装には未着手**。次に詰めるべき論点は [`biz/roadmap.md`](./biz/roadmap.md) を参照。

---

## ディレクトリ構成

```
docs/
├── overview.md              ← このファイル（docs全体の案内）
├── biz/                      事業戦略・分析レイヤー（なぜ／何を／どこで戦うか）
│   ├── concept.md            事業概要・三者構造・差別化・ポジショニング
│   ├── market.md             市場規模（TAM/SAM/SOM・国内/世界）・需給ギャップ
│   ├── competitors.md        競合分析・ポジショニングマップ
│   ├── business-model.md     事業モデル（ミッション/ライセンス/レベシェア）＋設計判断・見送ったアイデア
│   ├── industry.md           業界構造・トレンド・重要人物・情報源
│   ├── usecases.md           三者の具体シナリオ（目的を見失わないための北極星）
│   ├── roadmap.md            未解決の論点・今後の検討事項（優先度順）
│   └── references.md         参考文献・情報源一覧
├── tech/                     技術・プロダクトレイヤー（どう実現するか）
│   ├── tech-notes.md         技術的論点（動画vsモーキャプ・仮想vs現実・人型の必然性 等）
│   ├── data-model.md         事業モデルから導かれる暫定エンティティ（未確定）
│   ├── customer/             【予約】供給側＝消費者向けデータ収集アプリのプロダクト/技術設計
│   └── business/             【予約】需要側＝買い手（企業）向けプラットフォームのプロダクト/技術設計
└── devlog/                   作業ログ
    ├── overview.md            月次ログの索引
    └── YYYY-MM.md             月次の日付付きログ
```

> `tech/customer/` と `tech/business/` は、本プラットフォームの**二面性**（データを出す消費者側／データを買う企業側）に対応した予約領域。プロダクト設計に入る段でそれぞれの画面・機能・技術仕様を置く。現在は企画・調査フェーズのため未使用（各フォルダの `README.md` に意図を記載）。

---

## 目的別ナビゲーション

| やりたいこと | 読むファイル |
|------|-----------|
| 事業の全体像・コアコンセプトを知りたい | [`biz/concept.md`](./biz/concept.md) |
| 市場規模（TAM/SAM/SOM）と需給ギャップを知りたい | [`biz/market.md`](./biz/market.md) |
| 競合・自社の立ち位置を知りたい | [`biz/competitors.md`](./biz/competitors.md) |
| 収益化の仕組み（ライセンス・レベシェア）と設計判断を知りたい | [`biz/business-model.md`](./biz/business-model.md) |
| 業界の構造・トレンド・重要人物を知りたい | [`biz/industry.md`](./biz/industry.md) |
| 具体的な使われ方（三者のシナリオ）を知りたい（目的の再確認） | [`biz/usecases.md`](./biz/usecases.md) |
| 今後の検討事項・未解決の論点を知りたい | [`biz/roadmap.md`](./biz/roadmap.md) |
| 一次情報・出典を辿りたい | [`biz/references.md`](./biz/references.md) |
| 技術的な論点・実現可能性の裏付けを知りたい | [`tech/tech-notes.md`](./tech/tech-notes.md) |
| プロダクト化で効いてくるデータ構造の論点を知りたい | [`tech/data-model.md`](./tech/data-model.md) |
| 直近の作業経緯を追いたい | [`devlog/overview.md`](./devlog/overview.md) |

---

## 出典

本 docs は `research_summary.md`（2026-07-12 時点のリサーチ総括）を一次ソースとして再構成したもの。数値・競合状況は変化が速い分野のため、意思決定前に [`biz/references.md`](./biz/references.md) の一次情報での再確認を推奨する。
