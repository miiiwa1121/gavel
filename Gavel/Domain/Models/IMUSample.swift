import Foundation

/// 映像と時刻同期した IMU（慣性計測）の 1 サンプル。
///
/// `t` は収録開始を 0 とした相対秒。映像の PTS と突合できる基準にする
/// （`docs/tech/customer/requirements.md` 中核設計A: 映像と IMU は常に時刻同期）。
struct IMUSample: Codable, Equatable, Sendable {
    /// 収録開始からの相対時刻（秒）。
    var t: Double
    /// 重力を除いたユーザー加速度（G）。
    var userAcceleration: Vector3
    /// 角速度（rad/s）。
    var rotationRate: Vector3
    /// 重力方向（G）。
    var gravity: Vector3
    /// 端末姿勢（クォータニオン）。
    var attitude: Quaternion
}

/// IMU サンプル列を JSONL（1 行 1 サンプルの改行区切り JSON）へ相互変換する。
///
/// JSONL にする理由: 長時間収録でもストリーミング追記・部分読込ができ、原本として
/// 扱いやすい。将来のデータセット納品形式（LeRobot 等）への変換元にもしやすい。
enum IMUSampleSerializer {
    /// 改行区切り。末尾にも改行を付けない（空行を作らない）。
    static func encode(_ samples: [IMUSample]) throws -> Data {
        let encoder = JSONEncoder()
        // 決定的な出力（テスト容易性）と行内完結のためソート＆改行なし。
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var lines: [Data] = []
        lines.reserveCapacity(samples.count)
        for sample in samples {
            lines.append(try encoder.encode(sample))
        }
        let newline = Data([0x0A])
        return Data(lines.joined(separator: newline))
    }

    /// JSONL を復号する。空行はスキップする。
    static func decode(_ data: Data) throws -> [IMUSample] {
        let decoder = JSONDecoder()
        var result: [IMUSample] = []
        for line in data.split(separator: 0x0A, omittingEmptySubsequences: true) {
            result.append(try decoder.decode(IMUSample.self, from: Data(line)))
        }
        return result
    }
}
