import Foundation

/// 品質チェックの種類（安定した識別子）。
enum QualityCheckKind: String, Codable, Sendable, CaseIterable {
    case resolution
    case duration
    case sharpness
    case brightness
    case imuPresence
    case imuCoverage

    var displayName: String {
        switch self {
        case .resolution: "解像度"
        case .duration: "撮影時間"
        case .sharpness: "ピント（ブレ・ボケ）"
        case .brightness: "明るさ"
        case .imuPresence: "IMU の記録"
        case .imuCoverage: "IMU の連続性"
        }
    }
}

/// 個別チェックの結果。
struct QualityCheck: Equatable, Sendable, Identifiable {
    let kind: QualityCheckKind
    let passed: Bool
    /// 人間向けの詳細（合否理由・撮り直しのヒント）。
    let detail: String

    var id: QualityCheckKind { kind }
}

/// 品質評価の総合結果。
struct QualityReport: Equatable, Sendable {
    let checks: [QualityCheck]

    /// すべての必須チェックに合格したか。
    var passed: Bool { checks.allSatisfy(\.passed) }

    /// 不合格のチェックのみ。
    var failures: [QualityCheck] { checks.filter { !$0.passed } }
}

/// 撮影結果から抽出した、品質判定に必要な数値群。
///
/// 実際のピント・明るさの計算（ピクセルバッファ由来）は撮影サービス側で行い、
/// ここへ数値として渡す。これによりドメインの判定ロジックは実機なしでテストできる。
struct CaptureQualityInput: Sendable {
    var resolution: Resolution
    var durationSec: Double
    /// ピント（鮮鋭度）指標。
    var sharpness: Double
    /// 平均輝度（0.0〜1.0）。
    var brightness: Double
    var imuSampleCount: Int
    var imuSampleRateHz: Double
    /// ミッションが定めるクリップ尺の下限・上限。
    var minClipDurationSec: Double
    var maxClipDurationSec: Double
}

/// 撮影後の品質を、基準に照らして判定する純粋なロジック。
enum QualityEvaluator {
    static func evaluate(
        _ input: CaptureQualityInput,
        standard: QualityStandard = .standard
    ) -> QualityReport {
        var checks: [QualityCheck] = []

        checks.append(resolutionCheck(input, standard))
        checks.append(durationCheck(input, standard))
        checks.append(sharpnessCheck(input, standard))
        checks.append(brightnessCheck(input, standard))
        if standard.requireIMU {
            checks.append(imuPresenceCheck(input))
            checks.append(imuCoverageCheck(input, standard))
        }

        return QualityReport(checks: checks)
    }

    // MARK: - 個別チェック

    private static func resolutionCheck(_ input: CaptureQualityInput, _ standard: QualityStandard) -> QualityCheck {
        let res = input.resolution
        let passed = res.longSide >= standard.minResolutionLongSide
            && res.shortSide >= standard.minResolutionShortSide
        let detail = passed
            ? "\(res.width)×\(res.height)px（基準: 長辺\(standard.minResolutionLongSide)/短辺\(standard.minResolutionShortSide)以上）"
            : "解像度が不足しています（\(res.width)×\(res.height)px）。基準は長辺\(standard.minResolutionLongSide)・短辺\(standard.minResolutionShortSide)以上です。"
        return QualityCheck(kind: .resolution, passed: passed, detail: detail)
    }

    private static func durationCheck(_ input: CaptureQualityInput, _ standard: QualityStandard) -> QualityCheck {
        let dur = input.durationSec
        // 自動停止のわずかな超過を許容（停止は瞬時でないため）。
        let upperBound = input.maxClipDurationSec + standard.durationUpperToleranceSec
        let passed = dur >= input.minClipDurationSec && dur <= upperBound
        let detail: String
        if passed {
            detail = String(format: "%.1f秒（基準: %.0f〜%.0f秒）", dur, input.minClipDurationSec, input.maxClipDurationSec)
        } else if dur < input.minClipDurationSec {
            detail = String(format: "短すぎます（%.1f秒）。%.0f秒以上で撮り直してください。", dur, input.minClipDurationSec)
        } else {
            detail = String(format: "長すぎます（%.1f秒）。%.0f秒以内に収めてください。", dur, input.maxClipDurationSec)
        }
        return QualityCheck(kind: .duration, passed: passed, detail: detail)
    }

    private static func sharpnessCheck(_ input: CaptureQualityInput, _ standard: QualityStandard) -> QualityCheck {
        let passed = input.sharpness >= standard.minSharpness
        let detail = passed
            ? "ピントは良好です。"
            : "ブレ・ボケが検出されました。手元を固定し、被写体にピントを合わせて撮り直してください。"
        return QualityCheck(kind: .sharpness, passed: passed, detail: detail)
    }

    private static func brightnessCheck(_ input: CaptureQualityInput, _ standard: QualityStandard) -> QualityCheck {
        let passed = standard.brightnessRange.contains(input.brightness)
        let detail: String
        if passed {
            detail = "明るさは適切です。"
        } else if input.brightness < standard.brightnessRange.lowerBound {
            detail = "暗すぎます。手元に光が当たるようにしてください。"
        } else {
            detail = "明るすぎ（白飛び）ています。照明や角度を調整してください。"
        }
        return QualityCheck(kind: .brightness, passed: passed, detail: detail)
    }

    private static func imuPresenceCheck(_ input: CaptureQualityInput) -> QualityCheck {
        let passed = input.imuSampleCount > 0
        let detail = passed
            ? "IMU が記録されています（\(input.imuSampleCount)サンプル）。"
            : "IMU が記録されていません。映像と IMU は常にセットで必要です（センサー権限・装着を確認）。"
        return QualityCheck(kind: .imuPresence, passed: passed, detail: detail)
    }

    private static func imuCoverageCheck(_ input: CaptureQualityInput, _ standard: QualityStandard) -> QualityCheck {
        let expected = input.durationSec * input.imuSampleRateHz
        // 期待サンプルが0（尺0など）なら判定不能→不合格側に倒す。
        guard expected > 0 else {
            return QualityCheck(kind: .imuCoverage, passed: false, detail: "IMU カバレッジを判定できません（尺またはレートが0）。")
        }
        let ratio = Double(input.imuSampleCount) / expected
        let passed = ratio >= standard.minIMUCoverageRatio
        let detail = passed
            ? String(format: "IMU は収録全体で記録されています（カバレッジ %.0f%%）。", min(ratio, 1) * 100)
            : String(format: "IMU の記録が途切れています（カバレッジ %.0f%%）。撮影中にセンサーが止まっていないか確認してください。", ratio * 100)
        return QualityCheck(kind: .imuCoverage, passed: passed, detail: detail)
    }
}
