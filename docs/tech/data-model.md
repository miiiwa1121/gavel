# データモデル（v1 一部確定・全体は暫定）- gavel

> **要約**: 本事業がプロダクト化する際に**必ず必要になる論理エンティティ**を、事業モデルから逆算して列挙したメモ。**2026-07-12 に C側アプリ v1 の実装へ着手し、供給側に必要な部分を実装に合わせて確定**した（下記「§ v1 実装で確定したデータモデル」）。買い手・ライセンス・還元台帳は v1 では実装せず、暫定のまま将来へ持ち越す。
>
> 前提となる事業モデルは [`business-model.md`](../biz/business-model.md)。v1 の実装コードは `Gavel/Domain/`、確定の根拠は [`devlog/2026-07.md`](../devlog/2026-07.md)（追記3以降）を参照。

## この事業でデータモデルが特に重要になる理由

本事業の中核は「**データの権利を保持したまま、閲覧権を複数社に売る**」こと（[`business-model.md`](../biz/business-model.md)）。したがって、**誰のどのデータを・誰に・どの範囲（非独占/独占）で許諾したか**と、**売れるたびに誰へいくら還元するか（レベニューシェア）**を正確に追える構造が事業の生命線になる。ここを後付けするのは極めて高くつくため、方針だけ先に意識しておく。

## 暫定エンティティ（事業モデルから導かれる）

| エンティティ | 役割（想定） |
|--------------|--------------|
| **Contributor（供給者）** | スマホで撮影・投稿する一般消費者。レベニューシェアの受取主体 |
| **Mission（ミッション）** | 収集の単位。`type`（受注型／常設型）、収集条件、収集手段（スマホのみ／器具配布） |
| **Submission / Clip（投稿）** | 供給者が1回投稿した手元動作データ（原子単位）。所属ミッション・投稿者を持つ |
| **Media（メディア）** | 実体の映像／IMU 等のセンサーデータ。原本保持 |
| **Annotation（アノテーション）** | 音声実況等による「判断・暗黙知」のラベル。任意・高単価化の対象 |
| **Buyer（買い手）** | データを購入する企業（国内ロボット企業・海外フロンティアラボ） |
| **License（ライセンス）** | 閲覧権の許諾。`type`（**非独占／独占**）、対象データ範囲、許諾先、価格、期間 |
| **RevenueShareLedger（還元台帳）** | どの License 売上を、どの Contributor へ、いくら継続還元したかの記録 |

## いま意識しておく不変条件（案・未確定）

事業モデル上「絶対に守りたい」であろう性質を、**候補として**記録する（確定ではない）。

1. **データの所有権は常に自社に残る**（売るのは閲覧権であって所有権ではない）。
2. **1データに対する許諾は追跡可能**であること。特に**独占ライセンスを許諾したデータは、他社へ非独占で売れない**（二重許諾の禁止）。
3. **売上と還元の対応が壊れない**こと。どの売上がどの供給者へ還元されたかが常に追える（レベニューシェアの信頼性＝供給者ロックインの前提）。
4. **原本を保持**する（加工前データから何度でも別の加工・アノテーションを作れるように）。
5. **個人情報（顔等）の扱いを構造で担保**する（[`roadmap.md`](../biz/roadmap.md) §4。ぼかし前後のどちらを許諾対象にするか等）。

## v1 実装で確定したデータモデル（2026-07-12）

C側アプリ v1（供給側）で必要なエンティティのみを実装した。物理設計は **「1投稿=1フォルダ」のファイルベース**（SwiftData/DB は使わない。理由は devlog 追記3の技術選定表）。

### 実装したエンティティ ↔ コードの対応

| 論理エンティティ | v1 実装 | 主なフィールド（確定） |
|------------------|---------|------------------------|
| **Contributor** | `Contributor`（`profile.json`・端末内単一） | id / displayName / inviteCode / mountType / consentAcceptedAt |
| **Mission** | `Mission` ＋ `MissionCatalog`（コードに seed・少数常設） | id(slug) / title / category / summary / taskDescription / exampleGuidance / successConditions / shootingTips / min・maxClipDurationSec / recommendedMountType / isJapanSpecific / allowsAudioAnnotation |
| **Submission** | `Submission`（`manifest.json`） | id / missionId / contributorId / createdAt / outcome / mountType / device / videoDurationSec / videoResolution / imuSampleCount / imuSampleRateHz / hasAudioAnnotation / privacyConfirmed / syncState / note |
| **Media（原本）** | 投稿フォルダ内の実体ファイル `video.mov` / `imu.jsonl` | IMU は 1行1サンプルの JSONL（`IMUSample`: t / userAcceleration / rotationRate / gravity / attitude(quaternion)） |
| **Annotation** | 任意の `annotation.m4a`（音声）＋ `Submission.hasAudioAnnotation` | v1 は後付け型ナレーション（撮影後） |
| **Buyer / License / RevenueShareLedger** | **v1 未実装（暫定のまま）** | 売買が発生しない v1 では持たない。将来の需要側実装（`tech/business/`）で確定 |

### 端末内の物理レイアウト（原本保持）

```
<Documents>/
├── profile.json                       # Contributor（同意状態を含む）
└── submissions/
    └── <submissionId>/
        ├── manifest.json              # Submission メタ（schemaVersion 付き・最後に書く＝完成マーカー）
        ├── video.<ext>                # 映像原本（必須。拡張子は元ファイルを継承。実名は manifest.files.video に記録）
        ├── imu.jsonl                  # 映像と時刻同期した IMU（必須）
        └── annotation.<ext>           # 音声アノテーション（任意）
```

- **確定の根拠**: 「原本保持」（不変条件4）と、将来のデータセット納品形式（**LeRobot** の episode 単位）への変換しやすさを両立するため、投稿を自己記述的なフォルダ単位で持つ。`manifest.json` を最後に書くことで、その存在を「フォルダが完成した」コミットマーカーにできる（半端な書き込みを `all()` が拾わない）。
- **時刻同期の確定（v1 の実装忠実度）**: IMU の `t` は**収録開始の瞬間を 0 とする相対秒**。基準は `start()` 呼び出し時の `systemUptime`（deviceMotion.timestamp と同じ「起動からの秒」時間基準）にアンカーする。映像も同時刻に開始し、停止時は **IMU を先に止めてから映像をファイナライズ**する（asset ロード遅延ぶんの末尾ドリフトを避ける）。よって映像と IMU は「収録開始の瞬間」を共通の起点として対応づく。公称サンプリングは 100Hz。**フレーム精度での厳密な映像 PTS 整合（サブフレーム同期）は実機での追い込み課題**であり、v1 は「対で必ず揃い、開始起点を共有する」ところまでを担保する。
- **syncState**: v1 は実サーバ送信を行わないため既定 `pendingSync`（ローカル保持）。所有権は常に自社/供給者側に残り（不変条件1）、送信という外部公開は将来の同期実装で扱う。

## 今回はまだ決めない（次段以降）

- プロダクト/アプリの具体設計、画面、技術スタック、バックエンド基盤。
- 物理設計（DB・ストレージ・データ形式）。※ロボット学習の事実上の標準フォーマットは **LeRobot（Hugging Face）**（[`industry.md`](../biz/industry.md)）で、出力形式選定時の第一候補になりうる。
- ライセンス許諾・レベニューシェアの厳密なルール（価格・還元率は [`roadmap.md`](../biz/roadmap.md) §2 で確定させる）。
