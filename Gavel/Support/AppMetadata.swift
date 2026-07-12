import Foundation

/// アプリのメタ情報を一元管理する純粋な値。
///
/// UI・テストの双方から参照でき、ハードウェアやフレームワークに依存しない。
enum AppMetadata {
    /// 表示名（コードネーム）。正式サービス名は未定（`docs/biz/concept.md`）。
    static let displayName = "gavel"

    /// マーケティングバージョン。`project.yml` の `MARKETING_VERSION` と一致させる。
    static let version = "0.1.0"

    /// 対象プラットフォーム。iOS 固定（`CLAUDE.md` / `requirements.md` §1）。
    static let platform = "iOS"
}
