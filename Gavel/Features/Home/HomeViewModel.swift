import Foundation

/// ホーム画面の状態。貢献記録サマリを読み込む。
@MainActor
@Observable
final class HomeViewModel {
    private let submissionStore: SubmissionStore
    private(set) var summary: ContributionSummary = .empty
    private(set) var isLoading = false

    /// 常設ミッション（固定カタログ）。
    let missions = MissionCatalog.all

    init(submissionStore: SubmissionStore) {
        self.submissionStore = submissionStore
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        summary = (try? await submissionStore.summary()) ?? .empty
    }
}
