#!/usr/bin/env bash
# gavel C側アプリ 検証スクリプト（正本）。
# 静的解析 → ビルド＋テスト を順に実行し、いずれか失敗で即座に非0終了する。
# CLAUDE.md「検証（ビルド・テスト・静的解析）」の確定コマンド。
set -euo pipefail

cd "$(dirname "$0")/.."

# 実機不要のシミュレータ。環境変数で上書き可。
SIMULATOR="${GAVEL_SIMULATOR:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

echo "==> [1/3] project 再生成（project.yml → Gavel.xcodeproj）"
xcodegen generate

echo "==> [2/3] 静的解析（SwiftLint, --strict で警告も失敗扱い）"
swiftlint lint --strict

echo "==> [3/3] ビルド＋テスト: ${SIMULATOR}"
xcodebuild test \
  -project Gavel.xcodeproj \
  -scheme Gavel \
  -destination "${SIMULATOR}" \
  CODE_SIGNING_ALLOWED=NO \
  | grep -E "error:|warning:|Test run|✘|✔ Suite|BUILD (SUCCEEDED|FAILED)|\*\* TEST" || true

echo "==> 検証完了"
