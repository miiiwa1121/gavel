import Foundation

/// 投稿フォルダ内の実体ファイルの解決済み URL。
struct SubmissionMedia: Sendable, Equatable {
    let video: URL
    let imu: URL
    let audioAnnotation: URL?
}

/// 投稿ストアのエラー。
enum SubmissionStoreError: Error, Equatable {
    /// 下書きが参照する映像ファイルが存在しない。
    case videoFileMissing
    /// 下書きが参照する音声ファイルが存在しない。
    case audioFileMissing
    /// IMU サンプルが空。映像と IMU は常にセット（中核設計Aの不変ルール）＝映像単体の投稿は作らない。
    case imuSamplesMissing
}

/// 「1投稿=1フォルダ」でローカルに投稿を保持するファイルベースのリポジトリ。
///
/// ファイルアクセスを直列化するため actor で実装する。原本（映像・IMU・音声）と
/// `manifest.json` を投稿フォルダにまとめて置く。manifest.json を最後に書くことで、
/// その存在を「フォルダが完成した」というコミットマーカーとして扱える。
actor SubmissionStore {
    private let rootDirectory: URL

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    /// 投稿群を格納するディレクトリ。
    private var submissionsDirectory: URL {
        rootDirectory.appendingPathComponent("submissions", isDirectory: true)
    }

    /// 指定投稿のフォルダ URL（実体ファイルへアクセスする UI 用）。
    func folderURL(for id: UUID) -> URL {
        submissionsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    /// 下書きを永続化して確定した `Submission` を返す。
    ///
    /// 原本は「投稿フォルダへ **コピー** し、`manifest.json`（コミットマーカー）を書き終えてから
    /// 元の一時ファイルを削除する」順序にする。途中で失敗したら作りかけのフォルダを消し、元の
    /// 一時ファイルは残す（撮ったクリップを黙って失わない＝呼び出し元は再試行できる）。
    @discardableResult
    func save(_ draft: SubmissionDraft) throws -> Submission {
        let fileManager = FileManager.default
        // 映像単体・IMU単体の投稿は作らない（中核設計Aの不変ルールを関所で強制）。
        guard !draft.imuSamples.isEmpty else {
            throw SubmissionStoreError.imuSamplesMissing
        }
        guard fileManager.fileExists(atPath: draft.videoURL.path) else {
            throw SubmissionStoreError.videoFileMissing
        }
        if let audioURL = draft.audioAnnotationURL, !fileManager.fileExists(atPath: audioURL.path) {
            throw SubmissionStoreError.audioFileMissing
        }

        let submissionID = UUID()
        let folder = submissionsDirectory.appendingPathComponent(submissionID.uuidString, isDirectory: true)

        let videoExtension = draft.videoURL.pathExtension.isEmpty ? "mov" : draft.videoURL.pathExtension
        let videoName = "video.\(videoExtension)"
        let imuName = "imu.jsonl"
        var audioName: String?

        let submission = Submission(
            id: submissionID,
            missionId: draft.missionId,
            contributorId: draft.contributorId,
            createdAt: draft.createdAt,
            outcome: draft.outcome,
            mountType: draft.mountType,
            device: draft.device,
            videoDurationSec: draft.videoDurationSec,
            videoResolution: draft.videoResolution,
            imuSampleCount: draft.imuSamples.count,
            imuSampleRateHz: draft.imuSampleRateHz,
            hasAudioAnnotation: draft.audioAnnotationURL != nil,
            privacyConfirmed: draft.privacyConfirmed,
            syncState: .pendingSync,
            note: draft.note
        )

        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

            // 映像原本をコピー（元は成功後まで消さない）。
            try fileManager.copyItem(at: draft.videoURL, to: folder.appendingPathComponent(videoName))

            // IMU を JSONL で書き出し。
            let imuData = try IMUSampleSerializer.encode(draft.imuSamples)
            try imuData.write(to: folder.appendingPathComponent(imuName), options: .atomic)

            // 任意の音声アノテーションをコピー。
            if let audioURL = draft.audioAnnotationURL {
                let audioExtension = audioURL.pathExtension.isEmpty ? "m4a" : audioURL.pathExtension
                let name = "annotation.\(audioExtension)"
                try fileManager.copyItem(at: audioURL, to: folder.appendingPathComponent(name))
                audioName = name
            }

            // manifest.json を最後に書く（完成のコミットマーカー）。
            let manifest = SubmissionManifest(
                submission: submission,
                files: SubmissionFileRefs(video: videoName, imu: imuName, audioAnnotation: audioName)
            )
            let manifestData = try GavelJSON.makeEncoder().encode(manifest)
            try manifestData.write(to: folder.appendingPathComponent("manifest.json"), options: .atomic)
        } catch {
            // 部分失敗: 作りかけフォルダを消し、元の一時ファイルは残して再試行可能にする。
            try? fileManager.removeItem(at: folder)
            throw error
        }

        // コミット成功後に一時ファイルを回収（端末容量を無駄にしない）。
        try? fileManager.removeItem(at: draft.videoURL)
        if let audioURL = draft.audioAnnotationURL {
            try? fileManager.removeItem(at: audioURL)
        }

        return submission
    }

    /// 保存済みの全投稿を新しい順で返す。未完成（manifest 無し）のフォルダはスキップする。
    func all() throws -> [Submission] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: submissionsDirectory.path) else { return [] }

        let folders = try fileManager.contentsOfDirectory(
            at: submissionsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let decoder = GavelJSON.makeDecoder()
        var result: [Submission] = []
        for folder in folders {
            let manifestURL = folder.appendingPathComponent("manifest.json")
            // manifest 不在＝未完成フォルダはスキップ（コミットマーカー設計）。
            guard fileManager.fileExists(atPath: manifestURL.path) else { continue }
            do {
                let data = try Data(contentsOf: manifestURL)
                let manifest = try decoder.decode(SubmissionManifest.self, from: data)
                result.append(manifest.submission)
            } catch {
                // 破損・非互換な manifest は握りつぶしてスキップし、1件の破損で全履歴を失わない。
                continue
            }
        }
        // 新しい順。同一秒の同値化に備え id を第二キーにして決定的にする。
        return result.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }

    /// 貢献記録サマリを集計して返す。
    func summary() throws -> ContributionSummary {
        ContributionSummary.make(from: try all())
    }

    /// 指定投稿の実体ファイル URL を manifest から解決して返す（再生・確認 UI 用）。
    func media(for id: UUID) throws -> SubmissionMedia? {
        let folder = submissionsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        let manifestURL = folder.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else { return nil }
        let data = try Data(contentsOf: manifestURL)
        let manifest = try GavelJSON.makeDecoder().decode(SubmissionManifest.self, from: data)
        let videoURL = folder.appendingPathComponent(manifest.files.video)
        // 映像実体が欠けている異常時は nil を返し、UI 側で「読み込めません」を出せるようにする。
        guard FileManager.default.fileExists(atPath: videoURL.path) else { return nil }
        return SubmissionMedia(
            video: videoURL,
            imu: folder.appendingPathComponent(manifest.files.imu),
            audioAnnotation: manifest.files.audioAnnotation.map { folder.appendingPathComponent($0) }
        )
    }

    /// 指定投稿を削除する（フォルダごと）。存在しなければ無視。
    func delete(id: UUID) throws {
        let folder = submissionsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: folder.path) {
            try fileManager.removeItem(at: folder)
        }
    }
}
