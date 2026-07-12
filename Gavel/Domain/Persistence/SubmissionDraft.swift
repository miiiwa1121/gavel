import Foundation

/// 撮影パイプラインが生成し、まだ永続化されていない投稿の下書き。
///
/// 一時ファイル（映像・音声）と、メモリ上の IMU サンプル、確定に必要なメタを束ねる。
/// `SubmissionStore.save` がこれを受け取り、投稿フォルダへ原本を移動して確定する。
struct SubmissionDraft: Sendable {
    var missionId: String
    var contributorId: UUID
    var createdAt: Date
    var outcome: SelfReportedOutcome
    var mountType: MountType
    var device: DeviceInfo
    /// 収録済み映像の一時ファイル URL。
    var videoURL: URL
    var videoDurationSec: Double
    var videoResolution: Resolution
    /// 時刻同期済みの IMU サンプル列。
    var imuSamples: [IMUSample]
    var imuSampleRateHz: Double
    /// 任意の音声アノテーションの一時ファイル URL。
    var audioAnnotationURL: URL?
    /// 投稿前の人力プライバシー確認を通したか。
    var privacyConfirmed: Bool
    var note: String?

    init(
        missionId: String,
        contributorId: UUID,
        createdAt: Date = Date(),
        outcome: SelfReportedOutcome,
        mountType: MountType,
        device: DeviceInfo,
        videoURL: URL,
        videoDurationSec: Double,
        videoResolution: Resolution,
        imuSamples: [IMUSample],
        imuSampleRateHz: Double,
        audioAnnotationURL: URL? = nil,
        privacyConfirmed: Bool,
        note: String? = nil
    ) {
        self.missionId = missionId
        self.contributorId = contributorId
        self.createdAt = createdAt
        self.outcome = outcome
        self.mountType = mountType
        self.device = device
        self.videoURL = videoURL
        self.videoDurationSec = videoDurationSec
        self.videoResolution = videoResolution
        self.imuSamples = imuSamples
        self.imuSampleRateHz = imuSampleRateHz
        self.audioAnnotationURL = audioAnnotationURL
        self.privacyConfirmed = privacyConfirmed
        self.note = note
    }
}
