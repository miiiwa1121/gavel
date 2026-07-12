import Foundation

/// スマホの装着位置（一人称マウント撮影）。
///
/// 固定撮影では IMU がほぼ無意味になるため、v1 は体に装着して撮る前提を型で明示する
/// （`docs/tech/customer/requirements.md` 中核設計B）。
enum MountType: String, Codable, CaseIterable, Sendable {
    case head
    case chest

    var displayName: String {
        switch self {
        case .head: "頭マウント"
        case .chest: "胸マウント"
        }
    }
}

/// 1 実演の自己申告の成否。
///
/// 失敗も「なぜ失敗したか」の文脈として価値があるため投稿可能で、必須メタとして記録する
/// （`docs/tech/tech-notes.md` §3）。
enum SelfReportedOutcome: String, Codable, CaseIterable, Sendable {
    case success
    case failure

    var displayName: String {
        switch self {
        case .success: "成功"
        case .failure: "失敗"
        }
    }
}

/// 投稿の同期状態。
///
/// v1 は実サーバ送信を行わず端末内に完結するため、既定は `pendingSync`（ローカル保持・未送信）。
/// 将来のアップロード実装がこの状態を進める（`docs/tech/customer/requirements.md` §5）。
enum SyncState: String, Codable, CaseIterable, Sendable {
    /// ローカルに保持済み・サーバ未送信（v1 の既定）。
    case pendingSync
    /// サーバへ送信済み（将来実装）。
    case synced

    var displayName: String {
        switch self {
        case .pendingSync: "未同期（端末内保持）"
        case .synced: "同期済み"
        }
    }
}

/// ミッションのカテゴリ。日本特化タスクを中心に据える（差別化3本柱の1つ）。
enum MissionCategory: String, Codable, CaseIterable, Sendable {
    case cooking
    case tableware
    case housework
    case other

    var displayName: String {
        switch self {
        case .cooking: "調理"
        case .tableware: "食器の扱い"
        case .housework: "家事・配膳"
        case .other: "その他"
        }
    }
}
