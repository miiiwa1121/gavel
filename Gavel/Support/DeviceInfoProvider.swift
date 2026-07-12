import Foundation
import UIKit

/// 現在の端末情報を取得する。撮影メタ（個体差の把握）に使う。
enum DeviceInfoProvider {
    /// 現在の端末の `DeviceInfo`。
    @MainActor
    static func current() -> DeviceInfo {
        DeviceInfo(model: hardwareModel(), systemVersion: UIDevice.current.systemVersion)
    }

    /// ハードウェア識別子（例: "iPhone16,1"）。シミュレータでは環境変数から得る。
    static func hardwareModel() -> String {
        if let simulator = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulator
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { partialResult, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            partialResult.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? "unknown" : identifier
    }
}
