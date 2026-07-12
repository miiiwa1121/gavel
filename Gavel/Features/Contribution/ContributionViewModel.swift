import Foundation

/// 記録（貢献）画面の状態。投稿一覧・サマリ・ミッション別内訳を読み込み、削除も担う。
@MainActor
@Observable
final class ContributionViewModel {
    /// ミッション別の貢献件数（表示用）。
    struct MissionContribution: Identifiable, Equatable {
        let missionId: String
        let title: String
        let count: Int
        var id: String { missionId }
    }

    /// v1 の目標＝高品質サンプル100件（買い手に持ち込む最小構成。`roadmap.md` 最優先アクション）。
    static let sampleGoal = 100

    private let submissionStore: SubmissionStore
    private(set) var submissions: [Submission] = []
    private(set) var summary: ContributionSummary = .empty
    private(set) var isLoading = false

    init(submissionStore: SubmissionStore) {
        self.submissionStore = submissionStore
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        let loaded = (try? await submissionStore.all()) ?? []
        submissions = loaded
        summary = ContributionSummary.make(from: loaded)
    }

    /// 投稿を削除して一覧を更新する。
    func delete(_ submission: Submission) async {
        try? await submissionStore.delete(id: submission.id)
        await load()
    }

    /// 投稿の実体ファイル URL を解決する（詳細画面での再生用）。
    func media(for submission: Submission) async -> SubmissionMedia? {
        do {
            return try await submissionStore.media(for: submission.id)
        } catch {
            return nil
        }
    }

    /// 投稿のミッション名を解決する（未知なら id をそのまま返す）。
    func missionTitle(for submission: Submission) -> String {
        MissionCatalog.mission(id: submission.missionId)?.title ?? submission.missionId
    }

    /// 100件ゴールに対する進捗（0..1）。
    var goalProgress: Double {
        guard Self.sampleGoal > 0 else { return 0 }
        return min(1, Double(summary.total) / Double(Self.sampleGoal))
    }

    /// ミッション別の貢献件数（多い順・同数は id 昇順で決定的）。
    var missionBreakdown: [MissionContribution] {
        summary.countByMission
            .map { pair in
                MissionContribution(
                    missionId: pair.key,
                    title: MissionCatalog.mission(id: pair.key)?.title ?? pair.key,
                    count: pair.value
                )
            }
            .sorted { lhs, rhs in
                lhs.count != rhs.count ? lhs.count > rhs.count : lhs.missionId < rhs.missionId
            }
    }
}
