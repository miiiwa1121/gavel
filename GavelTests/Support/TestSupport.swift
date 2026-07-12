import Foundation
@testable import Gavel

/// テスト用の一時ファイル・下書き生成ヘルパ。
enum TestSupport {
    /// 一意な一時ディレクトリを作って返す。
    static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gavel-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// 指定拡張子のダミー一時ファイルを作って返す。
    static func makeTempFile(extension ext: String, contents: String = "dummy") throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gavel-file-\(UUID().uuidString).\(ext)")
        try Data(contents.utf8).write(to: url)
        return url
    }

    static func makeIMUSamples(count: Int, rateHz: Double) -> [IMUSample] {
        (0..<count).map { index in
            let t = Double(index) / rateHz
            return IMUSample(
                t: t,
                userAcceleration: Vector3(x: 0.01 * Double(index), y: 0, z: 0),
                rotationRate: Vector3(x: 0, y: 0.02, z: 0),
                gravity: Vector3(x: 0, y: 0, z: -1),
                attitude: Quaternion(w: 1, x: 0, y: 0, z: 0)
            )
        }
    }

    /// 有効な下書きを作る。IMU は 100Hz × durationSec 相当を満たす件数を生成する。
    static func makeDraft(
        videoURL: URL,
        audioURL: URL? = nil,
        missionId: String = MissionCatalog.chopsticksPlating.id,
        outcome: SelfReportedOutcome = .success,
        durationSec: Double = 10,
        rateHz: Double = 100,
        privacyConfirmed: Bool = true
    ) -> SubmissionDraft {
        let sampleCount = Int(durationSec * rateHz)
        return SubmissionDraft(
            missionId: missionId,
            contributorId: UUID(),
            outcome: outcome,
            mountType: .chest,
            device: DeviceInfo(model: "iPhone-Test", systemVersion: "18.0"),
            videoURL: videoURL,
            videoDurationSec: durationSec,
            videoResolution: Resolution(width: 1920, height: 1080),
            imuSamples: makeIMUSamples(count: sampleCount, rateHz: rateHz),
            imuSampleRateHz: rateHz,
            audioAnnotationURL: audioURL,
            privacyConfirmed: privacyConfirmed
        )
    }
}
