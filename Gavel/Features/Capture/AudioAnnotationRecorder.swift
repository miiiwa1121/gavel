import AVFoundation

enum AudioAnnotationError: Error {
    case notRecording
}

/// AVAudioRecorder による音声アノテーション録音（任意・後付け型）。
final class AVAudioAnnotationRecorder: NSObject, AudioAnnotationRecording, @unchecked Sendable {
    private let lock = NSLock()
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?

    func startRecording() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("annotation-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()

        lock.withLock {
            self.recorder = recorder
            currentURL = url
        }
    }

    func stopRecording() async throws -> URL {
        let (activeRecorder, url): (AVAudioRecorder?, URL?) = lock.withLock {
            let active = recorder
            let recordedURL = currentURL
            recorder = nil
            currentURL = nil
            return (active, recordedURL)
        }

        activeRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url else { throw AudioAnnotationError.notRecording }
        return url
    }
}
