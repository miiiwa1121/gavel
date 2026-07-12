import Foundation

/// 投稿フォルダ内の実体ファイル参照（フォルダからの相対名）。
struct SubmissionFileRefs: Codable, Equatable, Sendable {
    /// 映像ファイル名（例: "video.mov"）。
    var video: String
    /// IMU ファイル名（JSONL、例: "imu.jsonl"）。
    var imu: String
    /// 音声アノテーションファイル名（任意）。
    var audioAnnotation: String?

    init(video: String, imu: String, audioAnnotation: String? = nil) {
        self.video = video
        self.imu = imu
        self.audioAnnotation = audioAnnotation
    }
}

/// 端末内に保存される `manifest.json` の中身。
///
/// 「1投稿=1フォルダ」の自己記述メタデータ。原本（映像・IMU・音声）と同じフォルダに置かれ、
/// 将来のデータセット納品（LeRobot 等）への変換元になる。`schemaVersion` で後方互換を追う。
struct SubmissionManifest: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var submission: Submission
    var files: SubmissionFileRefs

    static let currentSchemaVersion = 1

    init(
        schemaVersion: Int = SubmissionManifest.currentSchemaVersion,
        submission: Submission,
        files: SubmissionFileRefs
    ) {
        self.schemaVersion = schemaVersion
        self.submission = submission
        self.files = files
    }
}

/// マニフェスト／プロフィールの JSON 変換器（日付は ISO8601・キー整列で決定的に）。
enum GavelJSON {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
