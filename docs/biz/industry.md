# 業界構造・トレンド - gavel

> **要約**: フィジカルAI（身体性AI）業界の**構造・トレンド・重要人物**をまとめた資料。「なぜ今このタイミングか」（[`concept.md`](./concept.md)）の裏付けであり、事業を業界の文脈に位置づけるための背景資料。
>
> 技術的な深掘りは [`tech-notes.md`](../tech/tech-notes.md)、一次情報の一覧は [`references.md`](./references.md) を参照。

## スケーリング則とその陰り — 事業が立つフェーズ

- LLM は「**データ量に比例して性能向上**」という脳筋プレイで進化してきたが、**良質なテキストデータの枯渇・収穫逓減・質重視への揺り戻し**で、その勢いに陰りが出ている。
- 一方、**フィジカルAI（ロボット）はまだ脳筋プレイにすら入れていない段階**。Open X-Embodiment で約100万デモ・1万時間の統合データセットができたが、「**これは始まりに過ぎない**」（Sergey Levine 評）。
- **LLM は「燃料切れで減速」、ロボットは「燃料をこれから集める」段階**で、真逆のフェーズにある。本事業はここに立つ。

## 重要人物・情報源

| 対象 | 内容 |
|------|------|
| **Sergey Levine／Chelsea Finn** | ロボット学習の中心人物、Physical Intelligence 創業陣。Levine の Substack「Learning and Control」の記事「The Promise of Generalist Robotic Policies」は必読 |
| **Physical Intelligence（π）** | π0 モデルで業界の実質的な基準を作った。4億ドル以上調達、評価額24億ドル |
| **NVIDIA** | Isaac Sim/Omniverse（シミュレーション）、GR00T（基盤モデル）、Jetson（計算基盤）でロボットAIの"Android"化を狙う |
| **Data Scaling Laws 論文** | データの量・多様性（特に**環境と対象物の多様性**）が性能向上に直結することを実証。**分散型ToC収集の理論的裏付け**（[`tech-notes.md`](../tech/tech-notes.md)） |
| **LeRobot（Hugging Face）** | ロボット学習データの事実上の標準フォーマットを提供する OSS |
| **Open X-Embodiment／DROID／AgiBot World** | 既存の大規模データセット。「何が足りないか」の参考になる |
| キュレーション | GitHub「awesome-physical-ai」 |

リンク付きの一覧は [`references.md`](./references.md) を参照。

## 国内動向

- **FastLabel** がフィジカルAI領域に本格参入（2026年4月、ロボティクスAI事業本部を新設。[`competitors.md`](./competitors.md)）。
- **経産省・NEDO** のフィジカルAI関連予算（**205億円**）、介護ロボット導入支援等の公的支援。
- **Mujin**（倉庫ピッキング特化で成功、シリーズDで362億円調達）が日本発 Physical AI の代表例。
- **2026年は「量産元年」を経て「作業元年」へ移行**するとの予測（PwC Japan）。

## 事業への含意

- 「**燃料をこれから集める**」段階＝データ収集事業の追い風。ただし供給側の話であり、**買い手予算の細さ（需要）は別問題**（[`market.md`](./market.md)）。
- 国内は公的予算・大手参入で**注目度が上がるほど競争も激化**する。空白（日本特化 × ToC分散）を**早く押さえる**ことが要（[`roadmap.md`](./roadmap.md)）。
