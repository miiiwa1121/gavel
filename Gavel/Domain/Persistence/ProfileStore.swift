import Foundation

/// 供給者プロフィール（同意状態を含む）を `profile.json` で保持する。
///
/// v1 は端末内の単一プロフィール。招待コード＋表示名＋同意日時＋マウント種別のみ。
actor ProfileStore {
    private let rootDirectory: URL

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    private var fileURL: URL {
        rootDirectory.appendingPathComponent("profile.json", isDirectory: false)
    }

    /// 保存済みプロフィールを読み込む。無ければ nil。
    func load() throws -> Contributor? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try GavelJSON.makeDecoder().decode(Contributor.self, from: data)
    }

    /// プロフィールを保存（上書き）する。
    func save(_ contributor: Contributor) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let data = try GavelJSON.makeEncoder().encode(contributor)
        try data.write(to: fileURL, options: .atomic)
    }

    /// プロフィールを削除する（存在しなければ無視）。
    func clear() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
