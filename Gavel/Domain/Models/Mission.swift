import Foundation

/// 収集の単位＝ミッション。
///
/// v1 は少数の常設ミッション（日本特化タスク）をアプリ内に固定表示する。各ミッションは
/// 「タスク説明・お手本・成功条件・撮り方の注意」を持つ（`requirements.md` §3）。
/// マーケットプレイス（多数の案件の検索・応募）は v1 では作らない。
struct Mission: Codable, Identifiable, Hashable, Sendable {
    /// 安定した slug（例: "chopsticks-plating"）。投稿の参照キーになるため変更しない。
    let id: String
    /// 一覧・詳細に出すタイトル。
    let title: String
    let category: MissionCategory
    /// 一覧で出す短い説明。
    let summary: String
    /// 何を実演するかの本文。
    let taskDescription: String
    /// お手本・望ましいやり方の説明。
    let exampleGuidance: String
    /// 成功条件（箇条書き）。
    let successConditions: [String]
    /// 撮り方の注意（ポカヨケの下地。箇条書き）。
    let shootingTips: [String]
    /// クリップ最小尺（秒）。これ未満は短すぎて実演として成立しにくい。
    let minClipDurationSec: Double
    /// クリップ最大尺（秒）。超過分は自動トリミングの対象（長尺の垂れ流し防止）。
    let maxClipDurationSec: Double
    /// 推奨マウント位置。
    let recommendedMountType: MountType
    /// 日本特有タスクか（差別化の軸）。
    let isJapanSpecific: Bool
    /// 音声アノテーションを推奨するか（v1 は任意・高単価化の入口）。
    let allowsAudioAnnotation: Bool

    init(
        id: String,
        title: String,
        category: MissionCategory,
        summary: String,
        taskDescription: String,
        exampleGuidance: String,
        successConditions: [String],
        shootingTips: [String],
        minClipDurationSec: Double = 3,
        maxClipDurationSec: Double = 60,
        recommendedMountType: MountType = .chest,
        isJapanSpecific: Bool = true,
        allowsAudioAnnotation: Bool = true
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.summary = summary
        self.taskDescription = taskDescription
        self.exampleGuidance = exampleGuidance
        self.successConditions = successConditions
        self.shootingTips = shootingTips
        self.minClipDurationSec = minClipDurationSec
        self.maxClipDurationSec = maxClipDurationSec
        self.recommendedMountType = recommendedMountType
        self.isJapanSpecific = isJapanSpecific
        self.allowsAudioAnnotation = allowsAudioAnnotation
    }
}
