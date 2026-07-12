import Foundation

/// 撮影フローの段階。
enum CaptureStage: Equatable {
    case precheck
    case recording
    case review
    case saving
    case done
    case failed(String)
}

/// 撮影〜レビュー〜保存を統括する。ハードウェアは protocol 注入なので実機なしでもテストできる。
///
/// フロー: 撮影前チェック → 収録（映像＋IMU 同期）→ レビュー（品質判定・自己申告・任意音声・
/// プライバシー確認）→ 保存（`SubmissionDraft` → `SubmissionStore`）。1投稿=1タスクの1実演。
@MainActor
@Observable
final class CaptureViewModel {
    let mission: Mission
    private let contributor: Contributor
    private let device: DeviceInfo
    private let camera: CameraCaptureService
    private let motion: MotionRecordingService
    private let audio: AudioAnnotationRecording
    private let submissionStore: SubmissionStore
    private let onSaved: @MainActor () -> Void

    // 撮影前チェック
    var mountConfirmed = false
    var handsConfirmed = false
    private(set) var cameraAvailability: CameraAvailability = .available
    private(set) var brightness: Double?
    private(set) var motionAvailable = false

    // 段階
    private(set) var stage: CaptureStage = .precheck
    private(set) var recordingStartedAt: Date?
    // 収録開始/停止の再入防御（await 前に同期的に立てる）。
    private(set) var isStarting = false
    private(set) var isStopping = false

    // レビュー
    private(set) var recorded: RecordedVideo?
    private(set) var imuSamples: [IMUSample] = []
    private(set) var qualityReport: QualityReport?
    var outcome: SelfReportedOutcome = .success
    var note: String = ""
    var privacyConfirmed = false
    private(set) var audioAnnotationURL: URL?
    private(set) var isRecordingAudio = false
    private(set) var errorMessage: String?

    init(
        mission: Mission,
        contributor: Contributor,
        device: DeviceInfo,
        camera: CameraCaptureService,
        motion: MotionRecordingService,
        audio: AudioAnnotationRecording,
        submissionStore: SubmissionStore,
        onSaved: @escaping @MainActor () -> Void
    ) {
        self.mission = mission
        self.contributor = contributor
        self.device = device
        self.camera = camera
        self.motion = motion
        self.audio = audio
        self.submissionStore = submissionStore
        self.onSaved = onSaved
    }

    // MARK: - 撮影前チェック

    var precaptureStatus: PrecaptureStatus {
        PrecaptureEvaluator.evaluate(
            mountConfirmed: mountConfirmed,
            handsConfirmed: handsConfirmed,
            brightness: brightness,
            motionAvailable: motionAvailable
        )
    }

    var canStart: Bool {
        stage == .precheck && !isStarting && cameraAvailability == .available && precaptureStatus.canStart
    }

    /// カメラ・IMU を準備し、利用可否と明るさを取り込む。
    func prepare() async {
        cameraAvailability = await camera.prepare()
        motionAvailable = await motion.isAvailable()
        if cameraAvailability == .available {
            brightness = await camera.sampleBrightness()
        }
    }

    /// 明るさを再測定する（撮影前チェックのライブ更新）。
    func refreshBrightness() async {
        guard stage == .precheck, cameraAvailability == .available else { return }
        brightness = await camera.sampleBrightness()
    }

    // MARK: - 収録

    func startRecording() async {
        guard canStart else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            try await camera.startRecording()
            await motion.start()
            recordingStartedAt = Date()
            stage = .recording
        } catch {
            fail("撮影を開始できませんでした。カメラの状態を確認してください。")
        }
    }

    func stopRecording() async {
        guard stage == .recording, !isStopping else { return }
        isStopping = true
        defer { isStopping = false }
        // IMU を先に止め、映像のファイナライズ/メタデータ読込の遅延ぶん末尾がずれないようにする。
        let samples = await motion.stop()
        do {
            let video = try await camera.stopRecording()
            recorded = video
            imuSamples = samples
            qualityReport = QualityEvaluator.evaluate(CaptureQualityInput(
                resolution: video.resolution,
                durationSec: video.durationSec,
                sharpness: video.sharpness,
                brightness: video.brightness,
                imuSampleCount: samples.count,
                imuSampleRateHz: CaptureConfig.imuSampleRateHz,
                minClipDurationSec: mission.minClipDurationSec,
                maxClipDurationSec: mission.maxClipDurationSec
            ))
            stage = .review
        } catch {
            fail("撮影の保存処理に失敗しました。もう一度撮影してください。")
        }
    }

    /// 上限尺に達したかどうか（View のタイマーから使う）。
    func hasReachedMaxDuration(at now: Date) -> Bool {
        guard let start = recordingStartedAt else { return false }
        return CaptureTiming.shouldAutoStop(
            elapsedSec: now.timeIntervalSince(start),
            maxDurationSec: mission.maxClipDurationSec
        )
    }

    // MARK: - 音声アノテーション（任意）

    func toggleAudioAnnotation() async {
        if isRecordingAudio {
            do {
                audioAnnotationURL = try await audio.stopRecording()
            } catch {
                errorMessage = "音声アノテーションの保存に失敗しました。"
            }
            isRecordingAudio = false
        } else {
            do {
                try await audio.startRecording()
                isRecordingAudio = true
            } catch {
                errorMessage = "音声アノテーションを開始できませんでした（マイク権限を確認）。"
            }
        }
    }

    func clearAudioAnnotation() {
        if let url = audioAnnotationURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioAnnotationURL = nil
    }

    // MARK: - 保存

    /// レビューを通過し投稿できるか。**プライバシー確認は投稿の必須ゲート**（写り込み配慮）。
    var canSubmit: Bool {
        stage == .review && recorded != nil && privacyConfirmed && !imuSamples.isEmpty
    }

    func submit() async {
        guard canSubmit, let recorded else { return }
        stage = .saving
        errorMessage = nil
        let draft = SubmissionDraft(
            missionId: mission.id,
            contributorId: contributor.id,
            outcome: outcome,
            mountType: contributor.mountType,
            device: device,
            videoURL: recorded.url,
            videoDurationSec: recorded.durationSec,
            videoResolution: recorded.resolution,
            imuSamples: imuSamples,
            imuSampleRateHz: CaptureConfig.imuSampleRateHz,
            audioAnnotationURL: audioAnnotationURL,
            privacyConfirmed: privacyConfirmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        )
        do {
            _ = try await submissionStore.save(draft)
            onSaved()
            stage = .done
        } catch {
            errorMessage = "投稿の保存に失敗しました。時間をおいて再度お試しください。"
            stage = .review
        }
    }

    /// 撮り直し（レビュー/失敗から撮影前チェックへ戻す）。未使用の収録物を破棄する。
    func retake() {
        discardTempFiles()
        recorded = nil
        imuSamples = []
        qualityReport = nil
        outcome = .success
        note = ""
        privacyConfirmed = false
        audioAnnotationURL = nil
        isRecordingAudio = false
        recordingStartedAt = nil
        errorMessage = nil
        stage = .precheck
    }

    /// 投稿せず画面を離れた場合の後始末（未投稿の一時ファイルを消す）。
    /// `.done`（保存済み＝store が原本を消費）と `.saving`（保存中）では触らない。
    func discardPending() {
        guard stage != .done, stage != .saving else { return }
        discardTempFiles()
    }

    /// 収録済み映像・音声の一時ファイルを削除する。
    private func discardTempFiles() {
        if let url = recorded?.url {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = audioAnnotationURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func fail(_ message: String) {
        errorMessage = message
        stage = .failed(message)
    }
}
