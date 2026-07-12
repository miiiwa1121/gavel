import Foundation

/// 映像の解像度（ピクセル）。
struct Resolution: Codable, Equatable, Sendable {
    var width: Int
    var height: Int

    /// 長辺・短辺での比較用（縦横どちらで撮っても判定できるように）。
    var longSide: Int { max(width, height) }
    var shortSide: Int { min(width, height) }
}

/// 1 投稿＝ミッションが定義する 1 タスクの 1 実演（不変ルール）。
///
/// 映像・IMU は常にセットで時刻同期され、この構造は端末内の `manifest.json` に保存される
/// メタ情報の中核（実体ファイルは同じフォルダに置く）。`data-model.md` の Submission に対応。
struct Submission: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    /// 所属ミッション（`Mission.id`）。
    let missionId: String
    /// 投稿者（`Contributor.id`）。
    let contributorId: UUID
    /// 収録日時。
    let createdAt: Date
    /// 自己申告の成否（失敗も価値ある文脈として記録）。
    var outcome: SelfReportedOutcome
    /// 装着位置。
    var mountType: MountType
    /// 端末情報。
    var device: DeviceInfo
    /// 映像尺（秒）。
    var videoDurationSec: Double
    /// 映像解像度。
    var videoResolution: Resolution
    /// 記録した IMU サンプル数（映像とセットである不変ルールの検証にも使う）。
    var imuSampleCount: Int
    /// IMU の公称サンプリングレート（Hz）。
    var imuSampleRateHz: Double
    /// 音声アノテーションの有無（任意・高単価化の入口）。
    var hasAudioAnnotation: Bool
    /// 投稿前の人力プライバシー確認を通したか（写り込み配慮。`requirements.md` §7）。
    var privacyConfirmed: Bool
    /// 同期状態（v1 は既定 pendingSync）。
    var syncState: SyncState
    /// 任意の補足メモ。
    var note: String?

    init(
        id: UUID = UUID(),
        missionId: String,
        contributorId: UUID,
        createdAt: Date = Date(),
        outcome: SelfReportedOutcome,
        mountType: MountType,
        device: DeviceInfo,
        videoDurationSec: Double,
        videoResolution: Resolution,
        imuSampleCount: Int,
        imuSampleRateHz: Double,
        hasAudioAnnotation: Bool,
        privacyConfirmed: Bool,
        syncState: SyncState = .pendingSync,
        note: String? = nil
    ) {
        self.id = id
        self.missionId = missionId
        self.contributorId = contributorId
        self.createdAt = createdAt
        self.outcome = outcome
        self.mountType = mountType
        self.device = device
        self.videoDurationSec = videoDurationSec
        self.videoResolution = videoResolution
        self.imuSampleCount = imuSampleCount
        self.imuSampleRateHz = imuSampleRateHz
        self.hasAudioAnnotation = hasAudioAnnotation
        self.privacyConfirmed = privacyConfirmed
        self.syncState = syncState
        self.note = note
    }
}
