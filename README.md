# gavel

日本の一般消費者がスマホで日常の手元動作を撮影・投稿し、フィジカルAI（身体性AI）・ロボット企業に「学習データの閲覧権（ライセンス）」として販売する、分散型データプラットフォーム事業（コードネーム・仮称）。

現在は **C側アプリ（供給側＝データ収集アプリ）の iOS 実装フェーズ**。事業・市場・競合・技術・業界の分析と製品要件は [`docs/`](./docs/) にまとめています（まずは [`docs/overview.md`](./docs/overview.md)）。

## iOS アプリ（供給側 v1）

限定協力者が **一人称・マウント撮影で「映像＋IMU」** を収集する最小構成。要件は [`docs/tech/customer/requirements.md`](./docs/tech/customer/requirements.md)、画面は [`docs/tech/customer/screens.md`](./docs/tech/customer/screens.md)、データ構造は [`docs/tech/data-model.md`](./docs/tech/data-model.md)、実装の判断ログは [`docs/devlog/2026-07.md`](./docs/devlog/2026-07.md)。

### 技術スタック
- Swift 6（strict concurrency・警告をエラー化）／ SwiftUI（`@Observable` MVVM）／ 依存注入サービス
- 永続化: ファイルベース（1投稿=1フォルダ: `manifest.json` + `video` + `imu.jsonl` + 任意 `annotation`）
- 撮影: AVFoundation（映像）＋ CoreMotion（IMU 100Hz）※実収録は実機のみ（シミュレータにカメラ無し）
- プロジェクト生成: XcodeGen（`project.yml` が正本）／ 静的解析: SwiftLint

### 必要なもの
- Xcode 26 系（iOS 18+ SDK）
- `xcodegen`, `swiftlint`（`brew install xcodegen swiftlint`）

### セットアップ・ビルド・検証
```sh
xcodegen generate                 # project.yml → Gavel.xcodeproj
./scripts/verify.sh               # 静的解析 + ビルド + テスト（正本の検証手順）
```
`scripts/verify.sh` は `xcodegen generate` → `swiftlint lint --strict` → `xcodebuild test`（iPhone 17 / iOS 26.5 シミュレータ）を順に実行します。シミュレータは `GAVEL_SIMULATOR` 環境変数で上書き可能。

### 構成
```
Gavel/            アプリ本体（App / Domain / Features / Support）
GavelTests/       ユニットテスト（Swift Testing）
project.yml       XcodeGen プロジェクト定義（正本）
scripts/verify.sh 検証スクリプト（正本）
docs/             事業・技術・作業ログ
```
