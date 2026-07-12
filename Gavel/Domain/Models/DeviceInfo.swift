import Foundation

/// 撮影に使った端末情報。個体差の把握とデータ品質の均質化に使う
/// （限定協力者に iPhone を揃える方針の裏付け。`requirements.md` §1）。
struct DeviceInfo: Codable, Equatable, Sendable {
    /// 端末モデル識別子（例: "iPhone16,1"）。
    var model: String
    /// OS バージョン（例: "18.0"）。
    var systemVersion: String
}
