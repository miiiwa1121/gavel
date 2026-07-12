import Foundation

/// アプリ全体の依存を束ねるコンテナ（DI のルート）。
///
/// 本番は Documents ディレクトリ、テストは一時ディレクトリを渡すことで、同じ画面/VM を
/// 実機・シミュレータ・ユニットテストのいずれでも動かせる。
@MainActor
@Observable
final class AppContainer {
    let rootDirectory: URL
    let submissionStore: SubmissionStore
    let profileStore: ProfileStore

    /// 投稿の保存など、データ変化を購読側へ知らせるための版番号。
    /// 画面はこれを `.task(id:)` に使い、保存後に自動で再読込する。
    private(set) var dataVersion = 0

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
        self.submissionStore = SubmissionStore(rootDirectory: rootDirectory)
        self.profileStore = ProfileStore(rootDirectory: rootDirectory)
    }

    /// データが変化したことを通知する（投稿保存後などに呼ぶ）。
    func bumpDataVersion() {
        dataVersion += 1
    }

    /// 本番用（アプリの Documents ディレクトリ配下）。
    static func live() -> AppContainer {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return AppContainer(rootDirectory: documents)
    }
}
