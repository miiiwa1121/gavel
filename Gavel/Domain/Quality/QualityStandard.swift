import Foundation

/// 品質基準（ポカヨケ判定のしきい値）。
///
/// v1 の価値は「100件が均質に高品質」であること。品質は撮影時点で決まるため、入口で構造的に
/// 担保する（`requirements.md` §2）。しきい値は運用で調整できるよう1か所に集約する。
struct QualityStandard: Sendable {
    /// 解像度の長辺・短辺の最小値（縦横どちらの向きでも判定できるよう長辺/短辺で持つ）。
    var minResolutionLongSide: Int
    var minResolutionShortSide: Int
    /// ピント（鮮鋭度）の最小値。ラプラシアン分散の標準偏差スケール（モックの発想を踏襲）。
    var minSharpness: Double
    /// 明るさ（平均輝度 0.0〜1.0）の許容レンジ。暗すぎ・白飛びを弾く。
    var brightnessRange: ClosedRange<Double>
    /// IMU が映像とセットで記録されている必要があるか（中核設計Aの不変ルール）。
    var requireIMU: Bool
    /// IMU カバレッジ（実サンプル数 ÷ 期待サンプル数）の最小比。収録全体で IMU が動いていたか。
    var minIMUCoverageRatio: Double
    /// 上限尺の許容超過（秒）。自動停止は瞬時でないため、わずかな超過は「長すぎ」としない。
    var durationUpperToleranceSec: Double

    init(
        minResolutionLongSide: Int = 1280,
        minResolutionShortSide: Int = 720,
        minSharpness: Double = 18,
        brightnessRange: ClosedRange<Double> = 0.12...0.92,
        requireIMU: Bool = true,
        minIMUCoverageRatio: Double = 0.8,
        durationUpperToleranceSec: Double = 1.0
    ) {
        self.minResolutionLongSide = minResolutionLongSide
        self.minResolutionShortSide = minResolutionShortSide
        self.minSharpness = minSharpness
        self.brightnessRange = brightnessRange
        self.requireIMU = requireIMU
        self.minIMUCoverageRatio = minIMUCoverageRatio
        self.durationUpperToleranceSec = durationUpperToleranceSec
    }

    /// v1 の既定基準。
    static let standard = QualityStandard()
}
