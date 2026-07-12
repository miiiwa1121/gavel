import Foundation

/// 貢献記録のサマリ（ウォレットの代わり）。
///
/// v1 はレベニューシェアを実装せず、固定謝礼＋貢献記録に留める（`requirements.md` §6）。
/// 「何件・どのミッションを・成功/失敗どちらで提供したか」を見せるための集計。
struct ContributionSummary: Equatable, Sendable {
    var total: Int
    var successCount: Int
    var failureCount: Int
    var withAudioAnnotationCount: Int
    /// ミッション id ごとの投稿件数。
    var countByMission: [String: Int]

    static let empty = ContributionSummary(
        total: 0,
        successCount: 0,
        failureCount: 0,
        withAudioAnnotationCount: 0,
        countByMission: [:]
    )

    /// 投稿一覧から集計する純粋関数。
    static func make(from submissions: [Submission]) -> ContributionSummary {
        var summary = ContributionSummary.empty
        summary.total = submissions.count
        for submission in submissions {
            switch submission.outcome {
            case .success: summary.successCount += 1
            case .failure: summary.failureCount += 1
            }
            if submission.hasAudioAnnotation {
                summary.withAudioAnnotationCount += 1
            }
            summary.countByMission[submission.missionId, default: 0] += 1
        }
        return summary
    }
}
