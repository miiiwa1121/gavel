import Foundation

/// 3 次元ベクトル（加速度・角速度・重力方向などに使う）。
struct Vector3: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double

    static let zero = Vector3(x: 0, y: 0, z: 0)

    /// ベクトルの大きさ（ノルム）。品質判定でブレ量の目安などに使う。
    var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }
}

/// 端末姿勢を表すクォータニオン。
///
/// オイラー角より特異点に強く、データセットとしての再利用性が高いため姿勢はこの形で保持する。
struct Quaternion: Codable, Equatable, Sendable {
    var w: Double
    var x: Double
    var y: Double
    var z: Double

    /// 無回転（単位クォータニオン）。
    static let identity = Quaternion(w: 1, x: 0, y: 0, z: 0)
}
