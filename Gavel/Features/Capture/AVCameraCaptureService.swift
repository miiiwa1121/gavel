import AVFoundation
import CoreImage

enum CameraCaptureError: Error {
    /// 既に停止処理が進行中（再入）。
    case alreadyStopping
}

/// AVFoundation による映像収録（実機のみ。シミュレータにはカメラが無く `.unavailableNoCamera`）。
///
/// セッション操作は専用キューで直列化し、可変メトリクスは `NSLock` で保護するため `@unchecked Sendable`。
/// 収録完了はデリゲート→continuation で await に橋渡しする。
final class AVCameraCaptureService: NSObject, CameraCaptureService, @unchecked Sendable {
    /// プレビュー接続用に公開するセッション。
    let session = AVCaptureSession()

    private let movieOutput = AVCaptureMovieFileOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "gavel.camera.session")
    private let sampleQueue = DispatchQueue(label: "gavel.camera.samples")
    private let ciContext = CIContext()

    private let lock = NSLock()
    private var latestBrightness: Double?
    private var latestSharpness: Double = 0
    private var frameCounter = 0
    private var stopContinuation: CheckedContinuation<URL, Error>?
    private var isConfigured = false

    func prepare() async -> CameraAvailability {
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            return .unavailableNoCamera
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted { return .unauthorized }
        default:
            return .unauthorized
        }
        return await configureIfNeeded()
    }

    func sampleBrightness() async -> Double? {
        lock.withLock { latestBrightness }
    }

    func startRecording() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("capture-\(UUID().uuidString).mov")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [self] in
                movieOutput.startRecording(to: url, recordingDelegate: self)
                continuation.resume()
            }
        }
    }

    func stopRecording() async throws -> RecordedVideo {
        let url: URL = try await withCheckedThrowingContinuation { continuation in
            // 継続の上書き（＝先行継続のリーク）を防ぐ。既に停止中なら弾く。
            let alreadyStopping = lock.withLock { () -> Bool in
                if stopContinuation != nil { return true }
                stopContinuation = continuation
                return false
            }
            if alreadyStopping {
                continuation.resume(throwing: CameraCaptureError.alreadyStopping)
                return
            }
            sessionQueue.async { [self] in movieOutput.stopRecording() }
        }

        let asset = AVURLAsset(url: url)
        let durationSec = (try? await asset.load(.duration)).map(CMTimeGetSeconds) ?? 0
        var resolution = Resolution(width: 0, height: 0)
        if let track = try? await asset.loadTracks(withMediaType: .video).first,
           let size = try? await track.load(.naturalSize) {
            resolution = Resolution(width: Int(abs(size.width)), height: Int(abs(size.height)))
        }
        let metrics = currentMetrics()
        return RecordedVideo(
            url: url,
            durationSec: durationSec,
            resolution: resolution,
            sharpness: metrics.sharpness,
            brightness: metrics.brightness
        )
    }

    // MARK: - 内部

    private func configureIfNeeded() async -> CameraAvailability {
        await withCheckedContinuation { (continuation: CheckedContinuation<CameraAvailability, Never>) in
            sessionQueue.async { [self] in
                if isConfigured {
                    continuation.resume(returning: .available)
                    return
                }
                session.beginConfiguration()
                session.sessionPreset = .high

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      session.canAddInput(input) else {
                    session.commitConfiguration()
                    continuation.resume(returning: .unavailableNoCamera)
                    return
                }
                session.addInput(input)

                // 本編クリップはマイク音声を含めない（データは映像＋IMU。第三者の音声 PII を
                // 既定で集めない）。判断の音声は任意の後付けアノテーションでのみ収集する。

                if session.canAddOutput(movieOutput) {
                    session.addOutput(movieOutput)
                }
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                videoDataOutput.setSampleBufferDelegate(self, queue: sampleQueue)
                if session.canAddOutput(videoDataOutput) {
                    session.addOutput(videoDataOutput)
                }

                session.commitConfiguration()
                session.startRunning()
                isConfigured = true
                continuation.resume(returning: .available)
            }
        }
    }

    private func currentMetrics() -> (brightness: Double, sharpness: Double) {
        lock.lock()
        defer { lock.unlock() }
        return (latestBrightness ?? 0, latestSharpness)
    }
}

// MARK: - 収録完了デリゲート

extension AVCameraCaptureService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        lock.lock()
        let continuation = stopContinuation
        stopContinuation = nil
        lock.unlock()

        if let error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume(returning: outputFileURL)
        }
    }
}

// MARK: - ライブフレームのメトリクス計測

extension AVCameraCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        lock.lock()
        frameCounter += 1
        let shouldProcess = frameCounter % 15 == 0
        lock.unlock()
        guard shouldProcess else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let metrics = FrameMetrics.evaluate(cgImage)

        lock.lock()
        latestBrightness = metrics.brightness
        latestSharpness = metrics.sharpness
        lock.unlock()
    }
}
