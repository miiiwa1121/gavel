import Foundation
import Testing
@testable import Gavel

@MainActor
struct CaptureViewModelTests {
    private func makeViewModel(
        camera: FakeCameraCaptureService = FakeCameraCaptureService(),
        motion: FakeMotionRecordingService = FakeMotionRecordingService(),
        audio: FakeAudioAnnotationRecording = FakeAudioAnnotationRecording(),
        store: SubmissionStore,
        onSaved: @escaping @MainActor () -> Void = {}
    ) -> CaptureViewModel {
        CaptureViewModel(
            mission: MissionCatalog.chopsticksPlating,
            contributor: Contributor(displayName: "t", inviteCode: "c", mountType: .chest),
            device: DeviceInfo(model: "m", systemVersion: "18.0"),
            camera: camera,
            motion: motion,
            audio: audio,
            submissionStore: store,
            onSaved: onSaved
        )
    }

    /// review 段まで進めた VM を返す（前チェック→収録→停止）。
    private func makeReviewingViewModel(
        audio: FakeAudioAnnotationRecording = FakeAudioAnnotationRecording(),
        store: SubmissionStore
    ) async -> CaptureViewModel {
        let viewModel = makeViewModel(audio: audio, store: store)
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        await viewModel.startRecording()
        await viewModel.stopRecording()
        return viewModel
    }

    private func makeStore() throws -> SubmissionStore {
        SubmissionStore(rootDirectory: try TestSupport.makeTempDirectory())
    }

    @Test
    func precheckBlocksStartUntilConfirmed() async throws {
        let viewModel = makeViewModel(store: try makeStore())
        await viewModel.prepare()
        #expect(!viewModel.canStart)  // マウント・手元が未確認
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        #expect(viewModel.canStart)
    }

    @Test
    func cameraUnavailableBlocksStart() async throws {
        let camera = FakeCameraCaptureService(availability: .unavailableNoCamera)
        let viewModel = makeViewModel(camera: camera, store: try makeStore())
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        #expect(!viewModel.canStart)  // カメラが無ければ開始不可
    }

    @Test
    func recordThenStopProducesReviewWithQuality() async throws {
        let viewModel = makeViewModel(store: try makeStore())
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true

        await viewModel.startRecording()
        #expect(viewModel.stage == .recording)

        await viewModel.stopRecording()
        #expect(viewModel.stage == .review)
        #expect(viewModel.recorded != nil)
        #expect(viewModel.qualityReport?.passed == true)
        #expect(viewModel.imuSamples.count == 1_000)
    }

    @Test
    func startFailureMovesToFailedStage() async throws {
        let camera = FakeCameraCaptureService(failStart: true)
        let viewModel = makeViewModel(camera: camera, store: try makeStore())
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true

        await viewModel.startRecording()
        if case .failed = viewModel.stage {
            #expect(viewModel.errorMessage != nil)
        } else {
            Issue.record("開始失敗時は .failed になるべき")
        }
    }

    @Test
    func submitRequiresPrivacyConfirmation() async throws {
        let store = try makeStore()
        let viewModel = makeViewModel(store: store)
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        await viewModel.startRecording()
        await viewModel.stopRecording()

        #expect(!viewModel.canSubmit)  // プライバシー未確認では投稿不可
        viewModel.privacyConfirmed = true
        #expect(viewModel.canSubmit)
    }

    @Test
    func submitPersistsSubmissionAndSignalsSaved() async throws {
        let store = try makeStore()
        var savedSignals = 0
        let viewModel = makeViewModel(store: store, onSaved: { savedSignals += 1 })
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        await viewModel.startRecording()
        await viewModel.stopRecording()

        viewModel.outcome = .failure
        viewModel.privacyConfirmed = true
        await viewModel.submit()

        #expect(viewModel.stage == .done)
        #expect(savedSignals == 1)

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.outcome == .failure)
        #expect(all.first?.privacyConfirmed == true)
        #expect(all.first?.imuSampleCount == 1_000)
    }

    @Test
    func audioAnnotationTogglesAndPersists() async throws {
        let store = try makeStore()
        let viewModel = makeViewModel(store: store)
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        await viewModel.startRecording()
        await viewModel.stopRecording()

        await viewModel.toggleAudioAnnotation()  // 開始
        #expect(viewModel.isRecordingAudio)
        await viewModel.toggleAudioAnnotation()  // 停止 → URL 確定
        #expect(!viewModel.isRecordingAudio)
        #expect(viewModel.audioAnnotationURL != nil)

        viewModel.privacyConfirmed = true
        await viewModel.submit()
        let all = try await store.all()
        #expect(all.first?.hasAudioAnnotation == true)
    }

    @Test
    func retakeResetsToPrecheckAndDeletesTempFiles() async throws {
        let viewModel = await makeReviewingViewModel(store: try makeStore())
        viewModel.privacyConfirmed = true
        let videoURL = try #require(viewModel.recorded?.url)
        #expect(FileManager.default.fileExists(atPath: videoURL.path))

        viewModel.retake()
        #expect(viewModel.stage == .precheck)
        #expect(viewModel.recorded == nil)
        #expect(viewModel.imuSamples.isEmpty)
        #expect(!viewModel.privacyConfirmed)
        // 撮り直しで未投稿の一時ファイルは削除される（リークしない）。
        #expect(!FileManager.default.fileExists(atPath: videoURL.path))
    }

    @Test
    func stopFailureMovesToFailedStage() async throws {
        let camera = FakeCameraCaptureService(failStop: true)
        let viewModel = makeViewModel(camera: camera, store: try makeStore())
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        await viewModel.startRecording()
        await viewModel.stopRecording()
        if case .failed = viewModel.stage {
            #expect(viewModel.errorMessage != nil)
        } else {
            Issue.record("停止失敗時は .failed になるべき")
        }
    }

    @Test
    func submitFailureReturnsToReviewWithError() async throws {
        // 既存ファイルを root に見立てて Store 保存を失敗させる。
        let fileAsRoot = try TestSupport.makeTempFile(extension: "dat")
        let store = SubmissionStore(rootDirectory: fileAsRoot)
        let viewModel = await makeReviewingViewModel(store: store)
        viewModel.privacyConfirmed = true

        await viewModel.submit()
        #expect(viewModel.stage == .review)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func clearAudioAnnotationRemovesFile() async throws {
        let viewModel = await makeReviewingViewModel(store: try makeStore())
        await viewModel.toggleAudioAnnotation()
        await viewModel.toggleAudioAnnotation()
        let audioURL = try #require(viewModel.audioAnnotationURL)
        #expect(FileManager.default.fileExists(atPath: audioURL.path))

        viewModel.clearAudioAnnotation()
        #expect(viewModel.audioAnnotationURL == nil)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
    }

    @Test
    func audioStartFailureSetsError() async throws {
        let audio = FakeAudioAnnotationRecording(failStart: true)
        let viewModel = await makeReviewingViewModel(audio: audio, store: try makeStore())
        await viewModel.toggleAudioAnnotation()
        #expect(!viewModel.isRecordingAudio)
        #expect(viewModel.audioAnnotationURL == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func stopRecordingIsNoopAfterReview() async throws {
        // 再入防御: レビュー段に入った後の stopRecording は何もしない。
        let viewModel = await makeReviewingViewModel(store: try makeStore())
        let sampleCount = viewModel.imuSamples.count
        #expect(viewModel.stage == .review)
        await viewModel.stopRecording()
        #expect(viewModel.stage == .review)
        #expect(viewModel.imuSamples.count == sampleCount)
    }

    @Test
    func startRecordingIsNoopWhenNotPrecheck() async throws {
        // 再入防御: precheck 以外では収録を開始しない。
        let viewModel = await makeReviewingViewModel(store: try makeStore())
        #expect(viewModel.stage == .review)
        await viewModel.startRecording()
        #expect(viewModel.stage == .review)
    }

    @Test
    func hasReachedMaxDurationDetectsCap() async throws {
        let viewModel = makeViewModel(store: try makeStore())
        await viewModel.prepare()
        viewModel.mountConfirmed = true
        viewModel.handsConfirmed = true
        await viewModel.startRecording()
        let start = try #require(viewModel.recordingStartedAt)
        let maxSec = MissionCatalog.chopsticksPlating.maxClipDurationSec
        #expect(!viewModel.hasReachedMaxDuration(at: start))
        #expect(viewModel.hasReachedMaxDuration(at: start.addingTimeInterval(maxSec + 1)))
    }
}
