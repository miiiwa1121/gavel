import Foundation
@testable import Gavel

enum FakeCaptureError: Error {
    case startFailed
    case stopFailed
}

/// テスト用のカメラサービス。実ファイルを1本作って `RecordedVideo` を返す（Store 保存を通すため）。
struct FakeCameraCaptureService: CameraCaptureService {
    var availability: CameraAvailability = .available
    var brightness: Double? = 0.5
    var resolution = Resolution(width: 1920, height: 1080)
    var durationSec: Double = 10
    var sharpness: Double = 40
    var recordedBrightness: Double = 0.5
    var failStart = false
    var failStop = false

    func prepare() async -> CameraAvailability { availability }

    func sampleBrightness() async -> Double? { brightness }

    func startRecording() async throws {
        if failStart { throw FakeCaptureError.startFailed }
    }

    func stopRecording() async throws -> RecordedVideo {
        if failStop { throw FakeCaptureError.stopFailed }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fake-video-\(UUID().uuidString).mov")
        try Data("video-bytes".utf8).write(to: url)
        return RecordedVideo(
            url: url,
            durationSec: durationSec,
            resolution: resolution,
            sharpness: sharpness,
            brightness: recordedBrightness
        )
    }
}

/// テスト用の IMU サービス。固定件数の合成サンプルを返す。
struct FakeMotionRecordingService: MotionRecordingService {
    var available = true
    var sampleCount = 1_000

    func isAvailable() async -> Bool { available }
    func start() async {}
    func stop() async -> [IMUSample] {
        TestSupport.makeIMUSamples(count: sampleCount, rateHz: CaptureConfig.imuSampleRateHz)
    }
}

/// テスト用の音声アノテーションサービス。実ファイルを1本作って URL を返す。
struct FakeAudioAnnotationRecording: AudioAnnotationRecording {
    var failStart = false
    var failStop = false

    func startRecording() async throws {
        if failStart { throw FakeCaptureError.startFailed }
    }

    func stopRecording() async throws -> URL {
        if failStop { throw FakeCaptureError.stopFailed }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fake-audio-\(UUID().uuidString).m4a")
        try Data("audio-bytes".utf8).write(to: url)
        return url
    }
}
