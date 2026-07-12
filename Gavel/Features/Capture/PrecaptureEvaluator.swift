import Foundation

/// 撮影前チェック（ポカヨケ第1段）の項目種別。
enum PrecaptureItemKind: String, Sendable, CaseIterable {
    case mount
    case hands
    case brightness
    case motion

    var label: String {
        switch self {
        case .mount: "マウント装着"
        case .hands: "手元が画角に入っている"
        case .brightness: "明るさが十分"
        case .motion: "IMU（モーション）が利用可能"
        }
    }
}

/// 撮影前チェックの 1 項目。
struct PrecaptureItem: Identifiable, Equatable, Sendable {
    let kind: PrecaptureItemKind
    let satisfied: Bool
    let detail: String

    var id: PrecaptureItemKind { kind }
}

/// 撮影前チェックの総合結果。
struct PrecaptureStatus: Equatable, Sendable {
    let items: [PrecaptureItem]

    /// 全項目を満たし、撮影を開始してよいか。
    var canStart: Bool { items.allSatisfy(\.satisfied) }
}

/// 撮影前チェックを評価する純粋ロジック（ポカヨケを「入口で構造的に」担保する第1段）。
///
/// マウント装着・手元が画角に入るはユーザーの自己確認、明るさ・IMU 可否は計測値。
/// これらが揃うまで撮影を開始させない（`requirements.md` §2 撮影前チェック）。
enum PrecaptureEvaluator {
    static func evaluate(
        mountConfirmed: Bool,
        handsConfirmed: Bool,
        brightness: Double?,
        motionAvailable: Bool,
        standard: QualityStandard = .standard
    ) -> PrecaptureStatus {
        var items: [PrecaptureItem] = []

        items.append(PrecaptureItem(
            kind: .mount,
            satisfied: mountConfirmed,
            detail: mountConfirmed ? "装着を確認しました" : "スマホを頭/胸のマウントに装着してください"
        ))
        items.append(PrecaptureItem(
            kind: .hands,
            satisfied: handsConfirmed,
            detail: handsConfirmed ? "手元が画角に入っています" : "手元が画面の中央に入るよう体を向けてください"
        ))

        let brightnessOK: Bool
        let brightnessDetail: String
        if let brightness {
            brightnessOK = standard.brightnessRange.contains(brightness)
            if brightnessOK {
                brightnessDetail = "明るさは適切です"
            } else if brightness < standard.brightnessRange.lowerBound {
                brightnessDetail = "暗すぎます。手元に光を当ててください"
            } else {
                brightnessDetail = "明るすぎ（白飛び）です。角度を調整してください"
            }
        } else {
            brightnessOK = false
            brightnessDetail = "明るさを測定できません（カメラを確認してください）"
        }
        items.append(PrecaptureItem(kind: .brightness, satisfied: brightnessOK, detail: brightnessDetail))

        items.append(PrecaptureItem(
            kind: .motion,
            satisfied: motionAvailable,
            detail: motionAvailable ? "IMU を利用できます" : "IMU が利用できません（実機・センサー権限を確認）"
        ))

        return PrecaptureStatus(items: items)
    }
}

/// 撮影中の自動停止（上限尺での打ち切り）を判定する純粋ロジック。
///
/// 要件「上限尺で自動トリミング」を、後処理 export ではなく **収録の自動停止** で実現する
/// （撮影側の関心。M1 レビュー N-3 の整合点）。評価器の上限超過チェックは安全網として残る。
enum CaptureTiming {
    static func shouldAutoStop(elapsedSec: Double, maxDurationSec: Double) -> Bool {
        elapsedSec >= maxDurationSec
    }
}
