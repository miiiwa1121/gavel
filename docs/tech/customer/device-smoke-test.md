# 実機 smoke test 手順（F-1）- gavel C側アプリ

> **要約**: シミュレータにはカメラが無いため、映像＋IMU の実収録・時刻同期・権限フローは**実機でしか検証できない**。この手順を1周通して初めて v1 を「動作確認済み」と呼べる（[`../../devlog/2026-07.md`](../../devlog/2026-07.md) の F-1）。所要 10〜15分。

## 0. 必要なもの
- iPhone（iOS 18+）と Mac、USB ケーブル（または同一 Wi-Fi でワイヤレスデバッグ）。
- Xcode に自分の Apple ID でサインイン済み（無料の Personal Team で可）。
- 頭/胸のクリップマウント（無ければ手持ちでも可。IMU が動けば検証は成立）。

## 1. 署名（初回のみ）
**推奨（Xcode GUI・確実）**:
1. `xcodegen generate` して `Gavel.xcodeproj` を開く。
2. TARGETS → `Gavel` → **Signing & Capabilities** → *Automatically manage signing* にチェック → **Team** に自分の Apple ID を選ぶ。
3. `com.gavel.customer` が使用済みなら Bundle Identifier を一意なもの（例 `com.<yourname>.gavel`）に変更。

**CLI で繰り返したい場合（任意）**: `project.yml` の `Gavel` ターゲット `settings.base` に以下を足すと `xcodegen generate` 後の再設定が不要になる（`4PM8SZR33W` は検出した開発チームID。違う場合は自分のものに）:
```yaml
        CODE_SIGN_STYLE: Automatic
        DEVELOPMENT_TEAM: "4PM8SZR33W"
```

## 2. 実機で起動
- **Xcode**: 実行先に接続した iPhone（例: ポリゴン / iPhone 11）を選び ⌘R。初回は端末側で「デベロッパを信頼」（設定 > 一般 > VPN とデバイス管理）が要る場合あり。
- **CLI 代替**:
  ```sh
  xcodebuild -project Gavel.xcodeproj -scheme Gavel \
    -destination 'platform=iOS,name=ポリゴン' -allowProvisioningUpdates build
  xcrun devicectl device install app --device <DEVICE_UDID> <Gavel.app のパス>
  ```

## 3. アプリ内で1周（機能の手触り確認）
1. **オンボーディング**: 同意（必須トグルを ON にしないと進めないこと）→ 招待コード・表示名・マウント → チュートリアル → 「撮影をはじめる」。
2. **権限**: 初回撮影で **カメラ／モーション** の許可ダイアログが出ることを確認（マイクは音声アノテ録音時のみ）。→ **一度「許可しない」を選び**、撮影前チェックの「IMU が利用可能」等が ❌ になり開始できないこと（＝拒否時の分岐）も確認。設定アプリで許可に戻す。
3. **撮影前チェック**: マウント・手元を ✓、明るさ/IMU が ✅ になり「撮影を開始」が活性化。プレビューに手元が映ること。
4. **収録**: 手元を数秒動かして「撮影を停止」。**上限60秒で自動停止**すること（試すなら長回し）。
5. **レビュー**: 撮った映像が再生できる／品質チェックが出る／成否を選べる／（任意で）音声アノテを録音できる／**「写り込み確認」をONにしないと投稿できない**こと。→ 投稿。
6. **記録**: 「記録」タブで投稿件数・100件ゴール・ミッション別内訳が増える。投稿をタップ → 詳細で**再生**、メタ（長さ・IMU件数・解像度・音声アノテ有無）を確認、**削除（確認ダイアログ）**が効く。

> **その場でできる簡易チェック**: 詳細画面の「長さ」と「IMU」を見て、**IMU件数 ≒ 長さ×100** になっていれば同期記録は概ね正常。

## 4. 生成物の機械検証（原本の中身を確認）
1. Xcode → **Window > Devices and Simulators** → 端末 → *Installed Apps* → `Gavel` → ⚙️ → **Download Container…** で `.xcappdata` を保存。
2. Finder で右クリック → **パッケージの内容を表示** → `AppData/Documents/submissions/<uuid>/`。
3. その投稿フォルダを検証ツールにかける:
   ```sh
   swift scripts/inspect-submission.swift /path/to/AppData/Documents/submissions/<uuid>
   ```
   **合格条件（🟢）**: IMU件数が尺×100の±20%／manifestと実ファイルの件数一致／IMU開始 t≈0／末尾 t≈尺／**本編 mov に音声トラック0本**／映像トラック1本。

## 5. 判定
- 手順3の手触り（プレビュー・自動停止・プライバシー必須ゲート・再生・削除）がすべて期待どおり、かつ手順4の `inspect-submission.swift` が **🟢** なら、**F-1 合格＝「動作確認済み v1」** と宣言してよい。結果（合否・気づき）は devlog に記録する。
- ❌ が出たら、該当箇所（権限・同期・音声混入など）を修正 → 再撮影 → 再検証。
